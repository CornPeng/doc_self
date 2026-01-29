import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

enum MultipeerEventType {
  peerFound,
  peerLost,
  invitationReceived,
  peerStateChanged,
  dataReceived,
}

enum PeerConnectionState {
  notConnected,
  connecting,
  connected,
  unknown,
}

class MultipeerEvent {
  final MultipeerEventType type;
  final String peerId;
  final String peerName;
  final PeerConnectionState? state;
  final Uint8List? data;
  final String? pairingCode;

  MultipeerEvent({
    required this.type,
    required this.peerId,
    required this.peerName,
    this.state,
    this.data,
    this.pairingCode,
  });

  factory MultipeerEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String;
    final type = _parseEventType(typeStr);
    
    print('📱 [Dart] 解析事件: $typeStr');
    print('📱 [Dart] 原始 map: $map');
    
    PeerConnectionState? state;
    if (map['state'] != null) {
      state = _parsePeerState(map['state'] as String);
    }
    
    Uint8List? data;
    if (map['data'] != null) {
      data = map['data'] as Uint8List;
    }
    
    String? pairingCode;
    if (map['pairingCode'] != null) {
      final rawCode = map['pairingCode'];
      print('📱 [Dart] pairingCode 原始值: "$rawCode" (类型: ${rawCode.runtimeType})');
      if (rawCode is String && rawCode.isNotEmpty) {
        pairingCode = rawCode;
        print('📱 [Dart] 解析后的配对码: "$pairingCode"');
      } else {
        print('📱 [Dart] 配对码为空或类型不匹配');
      }
    } else {
      print('📱 [Dart] map 中没有 pairingCode 字段');
    }

    return MultipeerEvent(
      type: type,
      peerId: map['peerId'] as String,
      peerName: map['peerName'] as String,
      state: state,
      data: data,
      pairingCode: pairingCode,
    );
  }

  static MultipeerEventType _parseEventType(String typeStr) {
    switch (typeStr) {
      case 'peerFound':
        return MultipeerEventType.peerFound;
      case 'peerLost':
        return MultipeerEventType.peerLost;
      case 'invitationReceived':
        return MultipeerEventType.invitationReceived;
      case 'peerStateChanged':
        return MultipeerEventType.peerStateChanged;
      case 'dataReceived':
        return MultipeerEventType.dataReceived;
      default:
        throw ArgumentError('Unknown event type: $typeStr');
    }
  }

  static PeerConnectionState _parsePeerState(String stateStr) {
    switch (stateStr) {
      case 'notConnected':
        return PeerConnectionState.notConnected;
      case 'connecting':
        return PeerConnectionState.connecting;
      case 'connected':
        return PeerConnectionState.connected;
      default:
        return PeerConnectionState.unknown;
    }
  }
}

class MultipeerService {
  static final MultipeerService _instance = MultipeerService._internal();
  factory MultipeerService() => _instance;
  MultipeerService._internal();

  static const MethodChannel _channel = MethodChannel('multipeer_connectivity');
  static const EventChannel _eventChannel = EventChannel('multipeer_connectivity/events');

  Stream<MultipeerEvent>? _eventStream;
  final StreamController<MultipeerEvent> _eventController = StreamController<MultipeerEvent>.broadcast();

  // 已连接的设备列表
  final Map<String, String> _connectedPeers = {}; // peerId -> peerName
  
  // 发现的设备列表
  final Map<String, String> _discoveredPeers = {}; // peerId -> peerName

  bool _isInitialized = false;
  bool _isAdvertising = false;
  bool _isBrowsing = false;

  Stream<MultipeerEvent> get eventStream => _eventController.stream;
  Map<String, String> get connectedPeers => Map.unmodifiable(_connectedPeers);
  Map<String, String> get discoveredPeers => Map.unmodifiable(_discoveredPeers);
  bool get isAdvertising => _isAdvertising;
  bool get isBrowsing => _isBrowsing;

  /// 初始化 Multipeer Connectivity
  Future<void> initialize(String displayName) async {
    if (_isInitialized) {
      print('⚠️ MultipeerService 已初始化');
      return;
    }

    try {
      await _channel.invokeMethod('initialize', {'displayName': displayName});
      _isInitialized = true;
      print('✅ MultipeerService 初始化成功: $displayName');

      // 开始监听事件
      _startListening();
    } catch (e) {
      print('❌ MultipeerService 初始化失败: $e');
      rethrow;
    }
  }

  void _startListening() {
    print('👂 开始监听 Multipeer 事件...');
    
    _eventStream = _eventChannel.receiveBroadcastStream().map((event) {
      return MultipeerEvent.fromMap(event as Map<dynamic, dynamic>);
    });

    _eventStream!.listen((event) {
      print('📡 收到事件: ${event.type} - ${event.peerName}');
      
      // 更新设备列表
      switch (event.type) {
        case MultipeerEventType.peerFound:
          print('   ✅ 发现新设备: ${event.peerName} (${event.peerId})');
          _discoveredPeers[event.peerId] = event.peerName;
          break;
        case MultipeerEventType.peerLost:
          print('   ⚠️ 设备离线: ${event.peerName}');
          _discoveredPeers.remove(event.peerId);
          _connectedPeers.remove(event.peerId);
          break;
        case MultipeerEventType.peerStateChanged:
          print('   🔄 状态变化: ${event.peerName} -> ${event.state}');
          if (event.state == PeerConnectionState.connected) {
            _connectedPeers[event.peerId] = event.peerName;
          } else if (event.state == PeerConnectionState.notConnected) {
            _connectedPeers.remove(event.peerId);
          }
          break;
        default:
          break;
      }

      // 转发事件
      _eventController.add(event);
    }, onError: (error) {
      print('❌ 事件监听错误: $error');
    });
  }

  /// 开始广播（让其他设备可以发现你）
  Future<void> startAdvertising() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('startAdvertising');
      _isAdvertising = true;
      print('📢 开始广播设备');
      print('   - 服务类型: soulnote-sync');
      print('   - 等待其他设备发现...');
    } catch (e) {
      print('❌ 开始广播失败: $e');
      rethrow;
    }
  }

  /// 停止广播
  Future<void> stopAdvertising() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('stopAdvertising');
      _isAdvertising = false;
      print('🛑 停止广播设备');
    } catch (e) {
      print('❌ 停止广播失败: $e');
      rethrow;
    }
  }

  /// 开始搜索附近的设备
  Future<void> startBrowsing() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('startBrowsing');
      _isBrowsing = true;
      print('🔍 开始搜索设备');
    } catch (e) {
      print('❌ 开始搜索失败: $e');
      rethrow;
    }
  }

  /// 停止搜索
  Future<void> stopBrowsing() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('stopBrowsing');
      _isBrowsing = false;
      print('🛑 停止搜索设备');
    } catch (e) {
      print('❌ 停止搜索失败: $e');
      rethrow;
    }
  }

  /// 停止所有服务
  Future<void> stopAll() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('stopAll');
      _isAdvertising = false;
      _isBrowsing = false;
      _connectedPeers.clear();
      _discoveredPeers.clear();
      print('🛑 停止所有 Multipeer 服务');
    } catch (e) {
      print('❌ 停止服务失败: $e');
      rethrow;
    }
  }

  /// 邀请设备连接
  Future<void> invitePeer(String peerId, {String? pairingCode, double timeout = 30.0}) async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('invitePeer', {
        'peerId': peerId,
        'pairingCode': pairingCode ?? '',
        'timeout': timeout,
      });
      if (pairingCode != null && pairingCode.isNotEmpty) {
        print('📤 邀请设备: $peerId，配对码: $pairingCode');
      } else {
        print('📤 邀请设备: $peerId（自动连接）');
      }
    } catch (e) {
      print('❌ 邀请设备失败: $e');
      rethrow;
    }
  }

  /// 接受邀请
  Future<void> acceptInvitation() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('acceptInvitation');
      print('✅ 接受邀请');
    } catch (e) {
      print('❌ 接受邀请失败: $e');
      rethrow;
    }
  }

  /// 拒绝邀请
  Future<void> rejectInvitation() async {
    _ensureInitialized();
    try {
      await _channel.invokeMethod('rejectInvitation');
      print('❌ 拒绝邀请');
    } catch (e) {
      print('❌ 拒绝邀请失败: $e');
      rethrow;
    }
  }

  /// 发送数据到指定设备
  Future<bool> sendData(String peerId, Uint8List data) async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod('sendData', {
        'peerId': peerId,
        'data': data,
      });
      
      if (result == true) {
        print('✅ 数据发送成功: ${data.length} bytes -> $peerId');
      } else {
        print('❌ 数据发送失败: $peerId');
      }
      
      return result as bool;
    } catch (e) {
      print('❌ 发送数据异常: $e');
      return false;
    }
  }

  /// 发送数据到所有已连接的设备
  Future<bool> sendDataToAll(Uint8List data) async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod('sendDataToAll', {
        'data': data,
      });
      
      if (result == true) {
        print('✅ 数据广播成功: ${data.length} bytes -> ${_connectedPeers.length} 个设备');
      } else {
        print('❌ 数据广播失败');
      }
      
      return result as bool;
    } catch (e) {
      print('❌ 广播数据异常: $e');
      return false;
    }
  }

  /// 获取当前已连接的设备列表
  Future<List<String>> getConnectedPeers() async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod('getConnectedPeers');
      return List<String>.from(result as List);
    } catch (e) {
      print('❌ 获取已连接设备失败: $e');
      return [];
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('MultipeerService has not been initialized. Call initialize() first.');
    }
  }

  void dispose() {
    stopAll();
    _eventController.close();
  }
}
