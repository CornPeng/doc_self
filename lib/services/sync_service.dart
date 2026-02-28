import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul_note/models/note.dart';
import 'package:soul_note/models/message.dart';
import 'package:soul_note/services/database_service.dart';
import 'package:soul_note/services/multipeer_service.dart';

enum DeviceType { iphone, ipad, mac }

enum SyncStatus { idle, scanning, connecting, syncing, completed, error }

class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DateTime lastSyncTime;
  final SyncStatus status;
  final double? progress;
  final bool isConnected;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastSyncTime,
    this.status = SyncStatus.idle,
    this.progress,
    this.isConnected = false,
  });

  ConnectedDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DateTime? lastSyncTime,
    SyncStatus? status,
    double? progress,
    bool? isConnected,
  }) {
    return ConnectedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class _TrustedDeviceInfo {
  final String id;
  final String name;
  final DeviceType type;

  _TrustedDeviceInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
    };
  }

  factory _TrustedDeviceInfo.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? DeviceType.iphone.name;
    final type = DeviceType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => DeviceType.iphone,
    );
    return _TrustedDeviceInfo(
      id: map['id'] as String,
      name: map['name'] as String? ?? map['id'] as String,
      type: type,
    );
  }
}

class PairingResult {
  final String peerId;
  final bool success;
  final String message;

  PairingResult({
    required this.peerId,
    required this.success,
    required this.message,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final MultipeerService _multipeer = MultipeerService();

  String? _deviceId;
  String? _deviceName;
  DeviceType? _deviceType;

  final StreamController<List<ConnectedDevice>> _devicesController =
      StreamController<List<ConnectedDevice>>.broadcast();
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<PairingResult> _pairingResultController =
      StreamController<PairingResult>.broadcast();

  Stream<List<ConnectedDevice>> get devicesStream => _devicesController.stream;
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<PairingResult> get pairingResultStream =>
      _pairingResultController.stream;

  List<ConnectedDevice> _connectedDevices = [];
  SyncStatus _currentStatus = SyncStatus.idle;

  // 可信任设备列表（已绑定的设备）
  Set<String> _trustedDeviceIds = {};
  final Map<String, _TrustedDeviceInfo> _trustedDeviceInfo = {};
  final Map<String, String> _pendingPairingCodes = {};
  static const String _trustedDevicesKey = 'trusted_device_ids';
  static const String _trustedDeviceInfoKey = 'trusted_device_info';

  // 初始化服务
  Future<void> initialize() async {
    await _loadDeviceInfo();
    await _loadTrustedDevices();
    
    // 初始化 Multipeer Connectivity
    if (_deviceName != null) {
      await _multipeer.initialize(_deviceName!);
      _setupMultipeerListeners();
    }
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
      
      print('✅ 设备信息加载完成: $_deviceName ($_deviceType)');
    } catch (e) {
      print('❌ 加载设备信息失败: $e');
    }
  }

  // 设置 Multipeer 事件监听（单条事件异常不导致整机崩溃）
  void _setupMultipeerListeners() {
    _multipeer.eventStream.listen((event) {
      try {
        switch (event.type) {
          case MultipeerEventType.peerFound:
            _handlePeerFound(event.peerId, event.peerName);
            break;
          case MultipeerEventType.peerLost:
            _handlePeerLost(event.peerId);
            break;
          case MultipeerEventType.invitationReceived:
            _handleInvitationReceived(
              event.peerId,
              event.peerName,
              pairingCode: event.pairingCode,
            );
            break;
          case MultipeerEventType.peerStateChanged:
            if (event.state != null) {
              _handlePeerStateChanged(event.peerId, event.state!);
            }
            break;
          case MultipeerEventType.dataReceived:
            if (event.data != null && event.data!.isNotEmpty) {
              _handleDataReceived(event.peerId, event.data!);
            }
            break;
        }
      } catch (e, st) {
        print('❌ 处理 Multipeer 事件失败 (${event.type}): $e');
        print('$st');
      }
    }, onError: (e, st) {
      print('❌ Multipeer 事件流错误: $e');
      print('$st');
    });
  }

  void _handlePeerFound(String peerId, String peerName) {
    print('📱 发现设备: $peerName');
    
    // 判断设备类型
    DeviceType type = DeviceType.iphone;
    final lowerName = peerName.toLowerCase();
    if (lowerName.contains('ipad')) {
      type = DeviceType.ipad;
    } else if (lowerName.contains('mac') || lowerName.contains('macbook')) {
      type = DeviceType.mac;
    }

    // 添加到设备列表
    final device = ConnectedDevice(
      id: peerId,
      name: peerName,
      type: type,
      lastSyncTime: DateTime.now(),
      status: SyncStatus.idle,
      isConnected: false,
    );

    final index = _connectedDevices.indexWhere((d) => d.id == peerId);
    if (index == -1) {
      _connectedDevices.add(device);
    } else {
      _connectedDevices[index] = device;
    }

    _devicesController.add(_connectedDevices);
  }

  void _handlePeerLost(String peerId) {
    print('⚠️ 设备离线: $peerId');
    _connectedDevices.removeWhere((d) => d.id == peerId);
    _devicesController.add(_connectedDevices);
  }

  void _handleInvitationReceived(String peerId, String peerName, {String? pairingCode}) {
    print('📥 收到连接邀请: $peerName');
    
    // 如果有配对码，说明这是扫码发起的配对，自动接受
    if (pairingCode != null && pairingCode.isNotEmpty) {
      print('✅ 收到扫码配对邀请，配对码: $pairingCode');
      _pendingPairingCodes[peerId] = pairingCode;
      _multipeer.acceptInvitation();
      return;
    }
    
    // 已信任设备的邀请，自动接受
    if (isTrustedDevice(peerId)) {
      _multipeer.acceptInvitation();
      return;
    }
    
    // 其他情况，暂时自动接受（可以根据需要改为弹出确认对话框）
    print('⚠️ 收到未知设备的邀请，自动接受');
    _multipeer.acceptInvitation();
  }

  void _handlePeerStateChanged(String peerId, PeerConnectionState state) {
    print('🔄 设备状态变化: $peerId -> $state');
    
    final index = _connectedDevices.indexWhere((d) => d.id == peerId);
    if (index != -1) {
      _connectedDevices[index] = _connectedDevices[index].copyWith(
        isConnected: state == PeerConnectionState.connected,
        status: state == PeerConnectionState.connected 
            ? SyncStatus.idle 
            : (state == PeerConnectionState.connecting 
                ? SyncStatus.connecting 
                : SyncStatus.idle),
      );
      _devicesController.add(_connectedDevices);
      
      // 连接成功后，如果有待验证的配对码，说明这是扫码配对，等待对方发送验证
      if (state == PeerConnectionState.connected && _pendingPairingCodes.containsKey(peerId)) {
        print('✅ 扫码配对连接成功，等待对方发送配对码验证: $peerId');
      }
    }
  }

  void _handleDataReceived(String peerId, List<int> data) {
    print('📨 收到数据: ${data.length} bytes <- $peerId');
    
    try {
      final jsonStr = utf8.decode(data);
      final Map<String, dynamic> payload = jsonDecode(jsonStr);
      
      final type = payload['type'] as String;
      
      switch (type) {
        case 'note':
          _receiveNote(payload['data']);
          break;
        case 'message':
          _receiveMessage(payload['data']);
          break;
        case 'syncRequest':
          _handleSyncRequest(peerId);
          break;
        case 'pairingVerify':
          _handlePairingVerify(peerId, payload);
          break;
        case 'pairingResult':
          _handlePairingResult(peerId, payload);
          break;
        default:
          print('⚠️ 未知数据类型: $type');
      }
    } catch (e) {
      print('❌ 处理接收数据失败: $e');
    }
  }

  Future<void> _handlePairingVerify(
    String peerId,
    Map<String, dynamic> payload,
  ) async {
    print('🔐 收到配对码验证请求: $peerId');
    final code = payload['code'] as String?;
    final expected = _pendingPairingCodes[peerId];
    
    print('  收到的配对码: $code');
    print('  期望的配对码: $expected');
    print('  待验证的配对码列表: $_pendingPairingCodes');
    
    if (code == null || expected == null) {
      print('❌ 配对验证失败: 缺少配对码 (code=$code, expected=$expected)');
      _pairingResultController.add(
        PairingResult(
          peerId: peerId,
          success: false,
          message: '配对验证失败：缺少配对码',
        ),
      );
      await _sendPairingResult(peerId, false, '配对验证失败：缺少配对码');
      return;
    }

    if (code != expected) {
      print('❌ 配对码不匹配: 收到=$code, 期望=$expected');
      _pairingResultController.add(
        PairingResult(
          peerId: peerId,
          success: false,
          message: '配对码不匹配',
        ),
      );
      await _sendPairingResult(peerId, false, '配对码不匹配');
      return;
    }

    ConnectedDevice? device;
    for (final item in _connectedDevices) {
      if (item.id == peerId) {
        device = item;
        break;
      }
    }
    
    // 添加为信任设备
    await addTrustedDevice(
      peerId,
      name: device?.name ?? peerId,
      type: device?.type ?? DeviceType.iphone,
    );
    _pendingPairingCodes.remove(peerId);
    
    print('✅ 配对验证成功: $peerId，已添加为信任设备');
    _pairingResultController.add(
      PairingResult(
        peerId: peerId,
        success: true,
        message: '配对成功',
      ),
    );
    await _sendPairingResult(peerId, true, '配对成功');
  }

  void _handlePairingResult(String peerId, Map<String, dynamic> payload) {
    final success = payload['success'] as bool? ?? false;
    final message = payload['message'] as String? ?? '配对结果未知';
    
    // 如果配对成功，接收方也需要添加对方为信任设备
    if (success) {
      ConnectedDevice? device;
      for (final item in _connectedDevices) {
        if (item.id == peerId) {
          device = item;
          break;
        }
      }
      addTrustedDevice(
        peerId,
        name: device?.name ?? peerId,
        type: device?.type ?? DeviceType.iphone,
      );
      print('✅ 接收方已添加对方为信任设备: $peerId');
    }
    
    _pairingResultController.add(
      PairingResult(
        peerId: peerId,
        success: success,
        message: message,
      ),
    );
  }

  Future<void> _sendPairingResult(
    String peerId,
    bool success,
    String message,
  ) async {
    final payload = {
      'type': 'pairingResult',
      'success': success,
      'message': message,
    };
    final jsonStr = jsonEncode(payload);
    final data = Uint8List.fromList(utf8.encode(jsonStr));
    await _multipeer.sendData(peerId, data);
  }

  // 追踪本次同步中有新消息写入的 noteId，同步完成后统一修正 messageCount
  final Set<String> _pendingRecalcNoteIds = {};

  /// 接收 Note：只合并元数据（标题、类型），不覆盖 messageCount（由消息并集后重算决定）
  Future<void> _receiveNote(Map<String, dynamic> noteData) async {
    try {
      final remote = Note.fromJson(noteData);
      print('[同步-接收 Note] id=${remote.id} title="${remote.title}" updatedAt=${remote.updatedAt}');

      final local = await _db.getNote(remote.id);
      if (local == null) {
        // 本地无此聊天对象，先建一个壳（消息后续单独合并）
        await _db.createNote(remote.copyWith(messageCount: 0));
        print('  → 新建聊天对象: ${remote.title}');
      } else {
        // 只合并元数据（title / noteType / markdownContent），以较新 updatedAt 为准
        if (remote.updatedAt.isAfter(local.updatedAt) || remote.title != local.title) {
          await _db.updateNote(local.copyWith(
            title: remote.title,
            noteType: remote.noteType,
            markdownContent: remote.markdownContent,
          ));
          print('  → 更新元数据: ${remote.title}');
        } else {
          print('  → 元数据无变化，跳过');
        }
      }
    } catch (e) {
      print('❌ 接收笔记失败: $e');
    }
  }

  /// 接收 Message：按 id 取并集（已存在直接跳过），收完后由 _recalculatePendingNotes 修正 messageCount
  Future<void> _receiveMessage(Map<String, dynamic> messageData) async {
    try {
      final message = Message.fromJson(messageData);
      final inserted = await _db.insertOrIgnoreMessage(message);
      if (inserted) {
        print('  → 新消息入库: id=${message.id} noteId=${message.noteId} content="${message.content}"');
        _pendingRecalcNoteIds.add(message.noteId);
      } else {
        print('  → 消息已存在跳过: id=${message.id}');
      }
    } catch (e) {
      print('❌ 接收消息失败: $e');
    }
  }

  /// 对本次同步中有新消息写入的 note，重算 messageCount / lastMessagePreview
  Future<void> _recalculatePendingNotes() async {
    if (_pendingRecalcNoteIds.isEmpty) return;
    for (final noteId in _pendingRecalcNoteIds) {
      await _db.recalculateNoteStats(noteId);
      print('✅ 重算 messageCount: noteId=$noteId');
    }
    _pendingRecalcNoteIds.clear();
  }

  Future<void> _handleSyncRequest(String peerId) async {
    print('📤 处理同步请求来自: $peerId（回传本机笔记，不再请求对方）');
    await syncWithDevice(peerId, requestBack: false);
  }

  /// 向对方发送「请把你的笔记发给我」，实现双向同步
  Future<void> _sendSyncRequest(String deviceId) async {
    final payload = {'type': 'syncRequest'};
    final data = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    await _multipeer.sendData(deviceId, data);
    print('📥 已请求对方回传笔记: $deviceId');
  }

  // 加载可信任设备列表
  Future<void> _loadTrustedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedIds = prefs.getStringList(_trustedDevicesKey) ?? [];
      _trustedDeviceIds = trustedIds.toSet();
      final infoRaw = prefs.getString(_trustedDeviceInfoKey);
      if (infoRaw != null && infoRaw.isNotEmpty) {
        final decoded = jsonDecode(infoRaw) as List<dynamic>;
        _trustedDeviceInfo.clear();
        for (final item in decoded) {
          final map = item as Map<String, dynamic>;
          final info = _TrustedDeviceInfo.fromMap(map);
          _trustedDeviceInfo[info.id] = info;
        }
      }
      print('✅ 已加载 ${_trustedDeviceIds.length} 个可信任设备');
    } catch (e) {
      print('❌ 加载可信任设备失败: $e');
      _trustedDeviceIds = {};
      _trustedDeviceInfo.clear();
    }
  }

  // 保存可信任设备列表
  Future<void> _saveTrustedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_trustedDevicesKey, _trustedDeviceIds.toList());
      final infoList =
          _trustedDeviceInfo.values.map((info) => info.toMap()).toList();
      await prefs.setString(_trustedDeviceInfoKey, jsonEncode(infoList));
      print('✅ 已保存 ${_trustedDeviceIds.length} 个可信任设备');
    } catch (e) {
      print('❌ 保存可信任设备失败: $e');
    }
  }

  // 添加可信任设备
  Future<void> addTrustedDevice(
    String deviceId, {
    String? name,
    DeviceType? type,
  }) async {
    _trustedDeviceIds.add(deviceId);
    if (name != null && type != null) {
      _trustedDeviceInfo[deviceId] = _TrustedDeviceInfo(
        id: deviceId,
        name: name,
        type: type,
      );
    }
    await _saveTrustedDevices();
  }

  void setPendingPairingCode(String deviceId, String code) {
    _pendingPairingCodes[deviceId] = code;
  }

  // 移除可信任设备
  Future<void> removeTrustedDevice(String deviceId) async {
    _trustedDeviceIds.remove(deviceId);
    _trustedDeviceInfo.remove(deviceId);
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

  List<ConnectedDevice> getTrustedDevices() {
    final devices = <ConnectedDevice>[];
    for (final info in _trustedDeviceInfo.values) {
      devices.add(
        ConnectedDevice(
          id: info.id,
          name: info.name,
          type: info.type,
          lastSyncTime: DateTime.now(),
          status: SyncStatus.idle,
          isConnected: false,
        ),
      );
    }
    for (final id in _trustedDeviceIds) {
      if (_trustedDeviceInfo.containsKey(id)) {
        continue;
      }
      devices.add(
        ConnectedDevice(
          id: id,
          name: id,
          type: DeviceType.iphone,
          lastSyncTime: DateTime.now(),
          status: SyncStatus.idle,
          isConnected: false,
        ),
      );
    }
    return devices;
  }

  // 开始扫描附近设备（用于绑定）
  Future<void> startScanningForBinding() async {
    _updateStatus(SyncStatus.scanning);
    _connectedDevices.clear();
    _devicesController.add(_connectedDevices);

    try {
      // 同时开启广播和搜索
      await _multipeer.startAdvertising();
      await _multipeer.startBrowsing();
      _seedConnectedPeersForBinding();
      
      print('🔍 开始扫描附近设备（用于绑定）...');
      print('📱 当前设备: $_deviceName');
      print('🔊 正在广播: $_deviceName');
      print('🔍 正在搜索其他设备...');
      
      // 30秒后自动停止扫描（延长时间以便发现）
      Future.delayed(const Duration(seconds: 30), () {
        _updateStatus(SyncStatus.idle);
        print('✅ 扫描完成，发现 ${_connectedDevices.length} 台设备');
        if (_connectedDevices.isEmpty) {
          print('💡 提示：确保两个设备都在蓝牙绑定页面点击了"搜索设备"');
        }
      });
    } catch (e) {
      print('❌ 扫描失败: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  void _seedConnectedPeersForBinding() {
    final peers = _multipeer.connectedPeers;
    if (peers.isEmpty) {
      return;
    }
    for (final entry in peers.entries) {
      final peerId = entry.key;
      final peerName = entry.value;
      if (_connectedDevices.any((d) => d.id == peerId)) {
        continue;
      }
      final lowerName = peerName.toLowerCase();
      DeviceType type = DeviceType.iphone;
      if (lowerName.contains('ipad')) {
        type = DeviceType.ipad;
      } else if (lowerName.contains('mac') || lowerName.contains('macbook')) {
        type = DeviceType.mac;
      }
      _connectedDevices.add(
        ConnectedDevice(
          id: peerId,
          name: peerName,
          type: type,
          lastSyncTime: DateTime.now(),
          status: SyncStatus.idle,
          isConnected: true,
        ),
      );
    }
    _devicesController.add(_connectedDevices);
  }

  // 开始扫描已绑定的设备（用于同步）
  Future<void> startScanning() async {
    _updateStatus(SyncStatus.scanning);
    
    // 清空未信任的设备
    _connectedDevices.removeWhere((d) => !isTrustedDevice(d.id));
    _devicesController.add(_connectedDevices);

    try {
      // 同时开启广播和搜索
      await _multipeer.startAdvertising();
      await _multipeer.startBrowsing();
      
      print('🔍 开始扫描已绑定设备...');
      
      // 10秒后自动停止扫描
      Future.delayed(const Duration(seconds: 10), () {
        _updateStatus(SyncStatus.idle);
        
        final trustedDevices = _connectedDevices.where((d) => isTrustedDevice(d.id)).toList();
        print('✅ 扫描完成，发现 ${trustedDevices.length} 台已绑定设备');
      });
    } catch (e) {
      print('❌ 扫描失败: $e');
      _updateStatus(SyncStatus.error);
    }
  }

  // 停止扫描
  Future<void> stopScanning() async {
    try {
      await _multipeer.stopAll();
      _updateStatus(SyncStatus.idle);
    } catch (e) {
      print('❌ 停止扫描失败: $e');
    }
  }

  // 邀请设备连接
  Future<void> inviteDevice(String deviceId) async {
    try {
      await _multipeer.invitePeer(deviceId);
      _updateDeviceStatus(deviceId, SyncStatus.connecting);
    } catch (e) {
      print('❌ 邀请设备失败: $e');
    }
  }

  /// 若未连接则先邀请并等待建立连接（最多 [timeout]），返回是否已连接。
  Future<bool> _ensureConnection(String deviceId, {Duration timeout = const Duration(seconds: 20)}) async {
    if (_multipeer.connectedPeers.containsKey(deviceId)) {
      return true;
    }
    print('🔗 设备未连接，先发起邀请: $deviceId');
    await inviteDevice(deviceId);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_multipeer.connectedPeers.containsKey(deviceId)) {
        print('✅ 已连接: $deviceId');
        return true;
      }
    }
    print('⏱️ 等待连接超时: $deviceId');
    return false;
  }

  // 与指定设备同步。[requestBack] 为 true 时会在发完后请求对方回传（双向）；对方响应时传 false 避免死循环。
  Future<void> syncWithDevice(String deviceId, {bool requestBack = true}) async {
    _updateStatus(SyncStatus.syncing);
    _updateDeviceStatus(deviceId, SyncStatus.syncing, 0.0);

    try {
      // 先确保已连接（发现≠连接，需先邀请对方）
      final connected = await _ensureConnection(deviceId);
      if (!connected) {
        _updateDeviceStatus(deviceId, SyncStatus.error);
        _updateStatus(SyncStatus.error);
        print('❌ 无法连接设备，请确认对方也在 Sync Radar 页面并保持应用在前台');
        return;
      }

      // 获取本地所有笔记
      final localNotes = await _db.getAllNotes();
      
      // 发送每个笔记 + 该笔记下的所有消息（这样列表的 messageCount 与点进去的消息条数一致）
      int totalItems = 0;
      for (final note in localNotes) {
        final msgs = await _db.getMessagesForNote(note.id);
        totalItems += 1 + msgs.length;
      }
      int sent = 0;
      for (int i = 0; i < localNotes.length; i++) {
        final note = localNotes[i];
        final noteJson = note.toJson();
        await _multipeer.sendData(deviceId, utf8.encode(jsonEncode({'type': 'note', 'data': noteJson})));
        print('[同步-发送] note id=${note.id} title="${note.title}" messageCount=${note.messageCount}');
        
        final messages = await _db.getMessagesForNote(note.id);
        for (final message in messages) {
          await _multipeer.sendData(deviceId, utf8.encode(jsonEncode({'type': 'message', 'data': message.toJson()})));
          print('[同步-发送] message id=${message.id} noteId=${message.noteId} content="${message.content}"');
        }
        
        sent += 1 + messages.length;
        _updateDeviceStatus(deviceId, SyncStatus.syncing, sent / totalItems);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 仅主动发起同步时请求对方回传，实现双向同步；对方响应 syncRequest 时不再回传
      if (requestBack) {
        await _sendSyncRequest(deviceId);
      }

      // 本端数据发完后，等对方的数据回传并落库，再统一修正 messageCount
      // 稍作延迟确保 _receiveMessage 回调已处理完（网络包顺序可能有延迟）
      await Future.delayed(const Duration(milliseconds: 800));
      await _recalculatePendingNotes();

      // 同步完成
      _updateDeviceStatus(deviceId, SyncStatus.completed, 1.0);
      
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

      print('✅ 同步完成: $deviceId');
    } catch (e) {
      print('❌ 同步失败: $e');
      _updateDeviceStatus(deviceId, SyncStatus.error);
      _updateStatus(SyncStatus.error);
    }
  }

  // 与所有设备同步（对已发现的信任设备先连接再同步）
  Future<void> syncWithAllDevices() async {
    final trustedDiscovered = _connectedDevices.where((d) => isTrustedDevice(d.id)).toList();
    if (trustedDiscovered.isEmpty) {
      print('⚠️ 未发现已绑定的设备，请先点击「Scan Devices」并确保对方也在 Sync Radar 页面');
      return;
    }

    _updateStatus(SyncStatus.syncing);

    for (final device in trustedDiscovered) {
      await syncWithDevice(device.id);
    }

    _updateStatus(SyncStatus.completed);
    await Future.delayed(const Duration(seconds: 1));
    _updateStatus(SyncStatus.idle);
  }

  // 处理冲突的笔记
  Future<void> _handleConflict(Note localNote, Note remoteNote) async {
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

  void dispose() {
    _devicesController.close();
    _statusController.close();
    _pairingResultController.close();
    _multipeer.dispose();
  }

  // Getters
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  DeviceType? get deviceType => _deviceType;
  List<ConnectedDevice> get connectedDevices => _connectedDevices;
  SyncStatus get currentStatus => _currentStatus;
}
