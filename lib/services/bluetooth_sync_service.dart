import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul_note/models/note.dart';
import 'package:soul_note/models/message.dart';
import 'package:soul_note/services/database_service.dart';

enum DeviceType { iphone, ipad, mac }

enum SyncStatus { idle, scanning, connecting, syncing, completed, error }

class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DateTime lastSyncTime;
  final SyncStatus status;
  final double? progress;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastSyncTime,
    this.status = SyncStatus.idle,
    this.progress,
  });

  ConnectedDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DateTime? lastSyncTime,
    SyncStatus? status,
    double? progress,
  }) {
    return ConnectedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class BluetoothSyncService {
  static final BluetoothSyncService _instance = BluetoothSyncService._internal();
  factory BluetoothSyncService() => _instance;
  BluetoothSyncService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // 服务 UUID（自定义，所有设备需使用相同的 UUID）
  static const String SERVICE_UUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String CHARACTERISTIC_UUID = '4fafc202-1fb5-459e-8fcc-c5c9c331914b';
  
  // 应用标识符 - 用于识别运行 SoulNote 的设备
  static const String APP_ID = 'com.soulnote.app';
  static const String DEVICE_NAME_PREFIX = 'SoulNote'; // 设备名称前缀

  String? _deviceId;
  String? _deviceName;
  DeviceType? _deviceType;
  String? _userAuthHash; // Face ID 的哈希标识

  final StreamController<List<ConnectedDevice>> _devicesController =
      StreamController<List<ConnectedDevice>>.broadcast();
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Stream<List<ConnectedDevice>> get devicesStream => _devicesController.stream;
  Stream<SyncStatus> get statusStream => _statusController.stream;

  List<ConnectedDevice> _connectedDevices = [];
  SyncStatus _currentStatus = SyncStatus.idle;
  
  // 可信任设备列表（已绑定的设备）
  Set<String> _trustedDeviceIds = {};
  static const String _trustedDevicesKey = 'trusted_device_ids';

  // 初始化服务
  Future<void> initialize() async {
    await _loadDeviceInfo();
    await _authenticateUser();
    await _loadTrustedDevices();
  }

  // 加载设备信息
  Future<void> _loadDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? '';
        _deviceName = iosInfo.name;
        
        // 根据设备型号判断类型
        final model = iosInfo.model.toLowerCase();
        if (model.contains('ipad')) {
          _deviceType = DeviceType.ipad;
        } else {
          _deviceType = DeviceType.iphone;
        }
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        _deviceId = macInfo.systemGUID ?? '';
        _deviceName = macInfo.computerName;
        _deviceType = DeviceType.mac;
      }
    } catch (e) {
      print('Error loading device info: $e');
    }
  }

  // 用户认证（Face ID/Touch ID）
  Future<bool> _authenticateUser() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics || 
                              await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        print('Device does not support biometric authentication');
        // 使用设备 ID 作为备用方案
        _userAuthHash = _generateHash(_deviceId ?? '');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: '验证身份以进行设备同步',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // 使用设备 ID 生成哈希作为用户标识
        _userAuthHash = _generateHash(_deviceId ?? '');
        return true;
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      _userAuthHash = _generateHash(_deviceId ?? '');
      return false;
    }
  }

  // 生成哈希
  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 加载可信任设备列表
  Future<void> _loadTrustedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedIds = prefs.getStringList(_trustedDevicesKey) ?? [];
      _trustedDeviceIds = trustedIds.toSet();
      print('✅ 已加载 ${_trustedDeviceIds.length} 个可信任设备');
    } catch (e) {
      print('❌ 加载可信任设备失败: $e');
      _trustedDeviceIds = {};
    }
  }

  // 保存可信任设备列表
  Future<void> _saveTrustedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_trustedDevicesKey, _trustedDeviceIds.toList());
      print('✅ 已保存 ${_trustedDeviceIds.length} 个可信任设备');
    } catch (e) {
      print('❌ 保存可信任设备失败: $e');
    }
  }

  // 添加可信任设备
  Future<void> addTrustedDevice(String deviceId) async {
    _trustedDeviceIds.add(deviceId);
    await _saveTrustedDevices();
  }

  // 移除可信任设备
  Future<void> removeTrustedDevice(String deviceId) async {
    _trustedDeviceIds.remove(deviceId);
    await _saveTrustedDevices();
  }

  // 检查设备是否是可信任的
  bool isTrustedDevice(String deviceId) {
    return _trustedDeviceIds.contains(deviceId);
  }

  // 获取所有可信任设备 ID 列表
  Set<String> getTrustedDeviceIds() {
    return Set.from(_trustedDeviceIds);
  }

  // 开始扫描附近设备
  Future<void> startScanning() async {
    _updateStatus(SyncStatus.scanning);
    _connectedDevices.clear();
    _devicesController.add(_connectedDevices);

    try {
      // 检查蓝牙是否可用
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        print('❌ Bluetooth not supported on this device');
        _updateStatus(SyncStatus.error);
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('❌ Bluetooth is not enabled. Please turn on Bluetooth');
        _updateStatus(SyncStatus.error);
        return;
      }

      // 监听扫描结果
      FlutterBluePlus.scanResults.listen((results) {
        _processDiscoveredDevices(results);
      });

      // 开始扫描所有附近的蓝牙设备
      print('🔍 开始扫描附近的蓝牙设备...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // 扫描超时后处理
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      
      // 扫描完成
      if (_connectedDevices.isEmpty) {
        print('');
        print('❌ 未发现 SoulNote 设备');
        print('💡 提示：');
        print('   1. 确保其他设备已安装并运行 SoulNote');
        print('   2. 确保蓝牙已开启');
        print('   3. 修改设备名称包含 "SoulNote"：');
        print('      iOS: 设置 > 通用 > 关于本机 > 名称');
        print('      macOS: 系统偏好设置 > 共享 > 电脑名称');
        print('   例如：Corn的iPhone → Corn的iPhone (SoulNote)');
        print('');
        _updateStatus(SyncStatus.idle);
      } else {
        print('');
        print('✅ 发现 ${_connectedDevices.length} 台 SoulNote 设备');
        for (final device in _connectedDevices) {
          print('   📱 ${device.name} (${_getDeviceTypeName(device.type)})');
        }
        print('');
        _updateStatus(SyncStatus.idle);
      }

    } catch (e) {
      print('❌ Scanning error: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  // 处理发现的设备（用于同步，只显示已绑定的设备）
  void _processDiscoveredDevices(List<ScanResult> results) {
    print('📱 发现 ${results.length} 个蓝牙设备');
    
    final discoveredDevices = <ConnectedDevice>[];
    final seenDevices = <String>{};
    
    for (final result in results) {
      try {
        final deviceId = result.device.remoteId.toString();
        
        // 避免重复添加
        if (seenDevices.contains(deviceId)) continue;
        seenDevices.add(deviceId);
        
        // ⭐ 只显示已绑定的设备
        if (!isTrustedDevice(deviceId)) {
          continue;
        }
        
        // 获取设备名称
        String deviceName = result.advertisementData.advName.isNotEmpty 
            ? result.advertisementData.advName 
            : result.device.platformName;
            
        // 如果没有名称，使用设备 ID 的前8位
        if (deviceName.isEmpty) {
          deviceName = 'Device ${deviceId.substring(0, 8)}';
        }
        
        print('  ✅ 发现已绑定设备: $deviceName (RSSI: ${result.rssi})');
        
        // 判断设备类型（基于名称）
        DeviceType type = DeviceType.iphone;
        final lowerName = deviceName.toLowerCase();
        if (lowerName.contains('ipad')) {
          type = DeviceType.ipad;
        } else if (lowerName.contains('mac') || lowerName.contains('macbook')) {
          type = DeviceType.mac;
        }

        // 添加已绑定的设备
        discoveredDevices.add(ConnectedDevice(
          id: deviceId,
          name: deviceName,
          type: type,
          lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
          status: SyncStatus.idle,
        ));
      } catch (e) {
        print('❌ 解析设备出错: $e');
      }
    }

    if (discoveredDevices.isNotEmpty) {
      print('✅ 可同步设备: ${discoveredDevices.length} 个');
      _connectedDevices = discoveredDevices;
      _devicesController.add(_connectedDevices);
    } else {
      print('💡 未发现已绑定的设备，请先在设置中绑定设备');
    }
  }
  
  // 检查是否是 SoulNote 设备
  bool _checkIfSoulNoteDevice(ScanResult result, String deviceName) {
    // 方法1：检查设备名称是否包含 SoulNote 标识
    if (deviceName.contains(DEVICE_NAME_PREFIX)) {
      return true;
    }
    
    // 方法2：检查是否广播了我们的服务 UUID
    final serviceUuids = result.advertisementData.serviceUuids;
    if (serviceUuids.contains(SERVICE_UUID)) {
      return true;
    }
    
    // 方法3：检查 manufacturerData 中是否包含我们的 APP_ID
    final manufacturerData = result.advertisementData.manufacturerData;
    for (final data in manufacturerData.values) {
      final dataString = String.fromCharCodes(data);
      if (dataString.contains(APP_ID)) {
        return true;
      }
    }
    
    // 方法4：检查是否是当前用户的其他设备（通过 userAuthHash）
    // 这需要在连接后验证，这里先简化处理
    
    return false;
  }
  
  // 获取设备类型名称
  String _getDeviceTypeName(DeviceType type) {
    switch (type) {
      case DeviceType.iphone:
        return 'iPhone';
      case DeviceType.ipad:
        return 'iPad';
      case DeviceType.mac:
        return 'Mac';
    }
  }

  // 扫描所有附近设备（用于绑定页面，不过滤）
  Future<void> startScanningForBinding() async {
    _updateStatus(SyncStatus.scanning);
    _connectedDevices.clear();
    _devicesController.add(_connectedDevices);

    try {
      // 检查蓝牙是否可用
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        print('❌ Bluetooth not supported on this device');
        _updateStatus(SyncStatus.error);
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('❌ Bluetooth is not enabled. Please turn on Bluetooth');
        _updateStatus(SyncStatus.error);
        return;
      }

      // 监听扫描结果（不过滤）
      FlutterBluePlus.scanResults.listen((results) {
        _processDiscoveredDevicesForBinding(results);
      });

      // 开始扫描所有附近的蓝牙设备
      print('🔍 开始扫描附近的所有蓝牙设备（用于绑定）...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // 扫描超时后处理
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      
      // 扫描完成
      print('✅ 扫描完成，发现 ${_connectedDevices.length} 台设备');
      _updateStatus(SyncStatus.idle);

    } catch (e) {
      print('❌ Scanning error: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  // 处理发现的设备（用于绑定页面，显示所有有名称的设备）
  void _processDiscoveredDevicesForBinding(List<ScanResult> results) {
    final discoveredDevices = <ConnectedDevice>[];
    final seenDevices = <String>{};
    
    for (final result in results) {
      try {
        final deviceId = result.device.remoteId.toString();
        
        // 避免重复添加
        if (seenDevices.contains(deviceId)) continue;
        seenDevices.add(deviceId);
        
        // 获取设备名称
        String deviceName = result.advertisementData.advName.isNotEmpty 
            ? result.advertisementData.advName 
            : result.device.platformName;
            
        // 只跳过完全没有名称的设备
        if (deviceName.isEmpty) {
          continue;
        }
        
        // 过滤掉信号太弱的设备（RSSI < -90）
        if (result.rssi < -90) {
          continue;
        }
        
        print('  📱 发现设备: $deviceName (RSSI: ${result.rssi})');
        
        // 判断设备类型（基于名称）
        DeviceType type = DeviceType.iphone;
        final lowerName = deviceName.toLowerCase();
        if (lowerName.contains('ipad')) {
          type = DeviceType.ipad;
        } else if (lowerName.contains('mac') || lowerName.contains('macbook')) {
          type = DeviceType.mac;
        }

        // 添加所有有名称的设备
        discoveredDevices.add(ConnectedDevice(
          id: deviceId,
          name: deviceName,
          type: type,
          lastSyncTime: DateTime.now(),
          status: SyncStatus.idle,
        ));
      } catch (e) {
        print('❌ 解析设备出错: $e');
      }
    }

    if (discoveredDevices.isNotEmpty) {
      print('✅ 可绑定设备: ${discoveredDevices.length} 个');
      _connectedDevices = discoveredDevices;
      _devicesController.add(_connectedDevices);
    }
  }

  // 停止扫描
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _updateStatus(SyncStatus.idle);
    } catch (e) {
      print('Stop scanning error: $e');
    }
  }

  // 与指定设备同步
  Future<void> syncWithDevice(String deviceId) async {
    final device = _connectedDevices.firstWhere((d) => d.id == deviceId);
    
    _updateStatus(SyncStatus.connecting);
    _updateDeviceStatus(deviceId, SyncStatus.connecting);

    await Future.delayed(const Duration(seconds: 1));

    _updateStatus(SyncStatus.syncing);
    _updateDeviceStatus(deviceId, SyncStatus.syncing, 0.0);

    try {
      // 获取本地所有笔记
      final localNotes = await _db.getAllNotes();
      
      // 模拟同步过程
      for (int i = 0; i < localNotes.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final progress = (i + 1) / localNotes.length;
        _updateDeviceStatus(deviceId, SyncStatus.syncing, progress);
      }

      // 同步完成
      _updateDeviceStatus(
        deviceId,
        SyncStatus.completed,
        1.0,
      );
      
      // 更新最后同步时间
      final index = _connectedDevices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _connectedDevices[index] = _connectedDevices[index].copyWith(
          lastSyncTime: DateTime.now(),
          status: SyncStatus.idle,
        );
        _devicesController.add(_connectedDevices);
      }

      await Future.delayed(const Duration(seconds: 1));
      _updateStatus(SyncStatus.completed);
      
      await Future.delayed(const Duration(seconds: 1));
      _updateStatus(SyncStatus.idle);

    } catch (e) {
      print('Sync error: $e');
      _updateDeviceStatus(deviceId, SyncStatus.error);
      _updateStatus(SyncStatus.error);
    }
  }

  // 与所有设备同步
  Future<void> syncWithAllDevices() async {
    _updateStatus(SyncStatus.syncing);
    
    for (final device in _connectedDevices) {
      await syncWithDevice(device.id);
    }
    
    _updateStatus(SyncStatus.completed);
    await Future.delayed(const Duration(seconds: 1));
    _updateStatus(SyncStatus.idle);
  }

  // 处理冲突的笔记
  Future<void> _handleConflict(Note localNote, Note remoteNote) async {
    // 如果远程笔记更新，保留两个版本
    if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
      // 重命名本地笔记为冲突副本
      final conflictNote = localNote.copyWith(
        title: '${localNote.title} (冲突副本 - ${_formatDateTime(localNote.updatedAt)})',
      );
      await _db.updateNote(conflictNote);
      
      // 保存远程笔记
      await _db.updateNote(remoteNote);
    } else {
      // 远程笔记更旧，保存为冲突副本
      final conflictNote = remoteNote.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${remoteNote.title} (冲突副本 - ${_formatDateTime(remoteNote.updatedAt)})',
      );
      await _db.createNote(conflictNote);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // 更新状态
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // 更新设备状态
  void _updateDeviceStatus(String deviceId, SyncStatus status, [double? progress]) {
    final index = _connectedDevices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _connectedDevices[index] = _connectedDevices[index].copyWith(
        status: status,
        progress: progress,
      );
      _devicesController.add(_connectedDevices);
    }
  }

  // 获取设备图标
  static String getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.iphone:
        return '📱';
      case DeviceType.ipad:
        return '📱';
      case DeviceType.mac:
        return '💻';
    }
  }

  // 清理资源
  void dispose() {
    _devicesController.close();
    _statusController.close();
  }

  // Getters
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  DeviceType? get deviceType => _deviceType;
  List<ConnectedDevice> get connectedDevices => _connectedDevices;
  SyncStatus get currentStatus => _currentStatus;
}
