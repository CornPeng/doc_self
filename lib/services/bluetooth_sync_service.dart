import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
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

  // 初始化服务
  Future<void> initialize() async {
    await _loadDeviceInfo();
    await _authenticateUser();
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

  // 开始扫描附近设备
  Future<void> startScanning() async {
    _updateStatus(SyncStatus.scanning);
    _connectedDevices.clear();
    _devicesController.add(_connectedDevices);

    try {
      // 检查蓝牙是否可用
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth is not on');
        _updateStatus(SyncStatus.error);
        return;
      }

      // 开始扫描
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // 模拟发现设备（实际应通过蓝牙广播发现）
      await Future.delayed(const Duration(seconds: 2));
      _simulateDiscoveredDevices();

    } catch (e) {
      print('Scanning error: $e');
      _updateStatus(SyncStatus.error);
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

  // 模拟发现的设备（演示用）
  void _simulateDiscoveredDevices() {
    _connectedDevices = [
      ConnectedDevice(
        id: 'mac-1',
        name: 'MacBook Pro M2',
        type: DeviceType.mac,
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
        status: SyncStatus.idle,
      ),
      ConnectedDevice(
        id: 'ipad-1',
        name: 'iPad Pro',
        type: DeviceType.ipad,
        lastSyncTime: DateTime.now().subtract(const Duration(hours: 2)),
        status: SyncStatus.idle,
      ),
    ];
    _devicesController.add(_connectedDevices);
    _updateStatus(SyncStatus.idle);
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
