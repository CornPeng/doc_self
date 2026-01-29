import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soul_note/services/sync_service.dart';
import 'package:soul_note/services/multipeer_service.dart';
import 'package:soul_note/l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 扫码绑定页面 - 全新设计
class QrBluetoothBindingScreen extends StatefulWidget {
  const QrBluetoothBindingScreen({super.key});

  @override
  State<QrBluetoothBindingScreen> createState() =>
      _QrBluetoothBindingScreenState();
}

class _QrBluetoothBindingScreenState extends State<QrBluetoothBindingScreen> {
  final SyncService _syncService = SyncService();
  final MultipeerService _multipeer = MultipeerService();

  List<ConnectedDevice> _boundDevices = [];
  String? _myDeviceId;
  String? _myDeviceName;
  String? _myQrCode; // 我的二维码数据

  // 扫码配对相关
  String? _qrTargetDeviceId;
  String? _qrTargetDeviceName;
  String? _qrPairingCode;
  bool _isConnecting = false;

  StreamSubscription? _multipeerSubscription;
  StreamSubscription? _pairingResultSubscription;
  StreamSubscription? _devicesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  @override
  void dispose() {
    _multipeerSubscription?.cancel();
    _pairingResultSubscription?.cancel();
    _devicesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeSync() async {
    // 获取设备信息
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _myDeviceName = iosInfo.name; // 例如 "Corn的iPhone"
      _myDeviceId = iosInfo.identifierForVendor ?? 'unknown';
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      _myDeviceName = macInfo.computerName; // 例如 "MacBook Pro"
      _myDeviceId = macInfo.systemGUID ?? 'unknown';
    }

    // 初始化服务（SyncService 内部会初始化 MultipeerService）
    await _syncService.initialize();

    // 生成二维码数据（统一为 SoulNote 兼容格式）
    final pairingCode = _generatePairingCode();
    _myQrCode = jsonEncode({
      'app': 'SoulNote',
      'peerId': _myDeviceName,
      'peerName': _myDeviceName,
      'pairingCode': pairingCode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      // 兼容旧版字段
      'deviceId': _myDeviceId,
      'deviceName': _myDeviceName,
    });

    // 加载已绑定设备
    _loadBoundDevices();

    // 开始广播和搜索（让其他设备能发现我，同时也搜索其他设备）
    print('🚀 开始广播和搜索设备...');
    await _syncService.startScanningForBinding();

    // 监听配对结果
    _pairingResultSubscription =
        _syncService.pairingResultStream.listen((result) {
      if (!mounted) return;

      final snackBar = SnackBar(
        content: Text(
          result.success ? '配对成功！设备已绑定' : result.message,
        ),
        backgroundColor:
            result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      if (result.success) {
        // 配对成功，清除扫码状态
        setState(() {
          _qrTargetDeviceId = null;
          _qrTargetDeviceName = null;
          _qrPairingCode = null;
        });
        _loadBoundDevices();
      }
    });

    // 监听设备列表变化（用于扫码后等待设备被发现）
    _devicesSubscription = _syncService.devicesStream.listen((devices) {
      if (!mounted) return;
      if (_qrTargetDeviceName == null) return;

      print('🔍 设备列表更新，当前设备数: ${devices.length}');
      for (final d in devices) {
        print('   - ${d.name} (${d.id})');
      }

      // 如果正在等待扫码的设备被发现
      // 注意：Multipeer 返回的 peerId 就是 deviceName，所以用名称匹配
      final foundDevice = devices.firstWhere(
        (d) => d.name == _qrTargetDeviceName || d.id == _qrTargetDeviceName,
        orElse: () => ConnectedDevice(
          id: '',
          name: '',
          type: DeviceType.iphone,
          lastSyncTime: DateTime.now(),
        ),
      );

      if (foundDevice.id.isNotEmpty) {
        // 设备已发现，更新目标ID为实际的peerId（即name）
        print('✅ 扫码设备已发现: ${foundDevice.name} (${foundDevice.id})');
        setState(() {
          _qrTargetDeviceId = foundDevice.id;
        });
        _connectToQrDevice();
      }
    });

    // 监听 Multipeer 事件（接收邀请）
    _multipeerSubscription = _multipeer.eventStream.listen((event) {
      if (!mounted) return;

      if (event.type == MultipeerEventType.peerFound) {
        // 发现设备时，如与扫码目标匹配则直接发起邀请
        final isTarget =
            (_qrTargetDeviceId != null && event.peerId == _qrTargetDeviceId) ||
                (_qrTargetDeviceName != null &&
                    event.peerName == _qrTargetDeviceName);
        if (isTarget && _qrPairingCode != null && _qrPairingCode!.isNotEmpty) {
          print('🔗 发现扫码目标，立即邀请: ${event.peerName}');
          _multipeer.invitePeer(event.peerId, pairingCode: _qrPairingCode);
        }
      } else if (event.type == MultipeerEventType.invitationReceived) {
        // 收到邀请时，检查是否有待验证的配对码（来自扫码）
        if (_qrPairingCode != null && _qrPairingCode!.isNotEmpty) {
          // 这是扫码发起的配对，自动接受
          print('📱 收到扫码配对邀请，自动接受');
          _syncService.setPendingPairingCode(event.peerId, _qrPairingCode!);
          _multipeer.acceptInvitation();
        } else {
          // 普通邀请，需要手动确认（这里暂时自动接受，因为这是扫码页面）
          _multipeer.acceptInvitation();
        }
      } else if (event.type == MultipeerEventType.peerStateChanged) {
        print('🔄 设备状态变化: ${event.peerName} -> ${event.state}');

        if (event.state == PeerConnectionState.connected) {
          print('✅ 设备已连接: ${event.peerName} (${event.peerId})');

          // 连接成功后，如果是扫码发起的连接，发送配对码验证
          // 注意：peerId 和 peerName 在 Multipeer 中是相同的（都是 displayName）
          final isTargetDevice = (_qrTargetDeviceId != null &&
                  (_qrTargetDeviceId == event.peerId ||
                      _qrTargetDeviceId == event.peerName)) ||
              (_qrTargetDeviceName != null &&
                  _qrTargetDeviceName == event.peerName);

          if (isTargetDevice && _qrPairingCode != null) {
            print('📤 发送配对码验证: $_qrPairingCode');
            // 延迟一下确保连接稳定
            Future.delayed(const Duration(milliseconds: 500), () {
              _sendPairingVerification(event.peerId, _qrPairingCode!);
            });
          }
        } else if (event.state == PeerConnectionState.notConnected) {
          print('❌ 设备断开连接: ${event.peerName}');
        }
      }
    });

    setState(() {});
  }

  String _generatePairingCode() {
    return (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
  }

  Future<void> _loadBoundDevices() async {
    final devices = await _syncService.getTrustedDevices();
    if (mounted) {
      setState(() {
        _boundDevices = devices;
      });
    }
  }

  Future<void> _unbindDevice(ConnectedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '解除绑定',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要解除与 ${device.name} 的绑定吗？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('解除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _syncService.removeTrustedDevice(device.id);
      _loadBoundDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已解除与 ${device.name} 的绑定'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      }
    }
  }

  void _showMyQrCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C24),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '我的设备二维码',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _myDeviceName ?? '未知设备',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _myQrCode != null
                    ? QrImageView(
                        data: _myQrCode!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                      )
                    : const SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                '让对方扫描此二维码完成配对',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '关闭',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanQrCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _QrScannerScreen(
          onScanned: (data) {
            Navigator.pop(context, data);
          },
        ),
      ),
    );

    // 如果没有扫描结果，直接返回
    if (result == null || !mounted) return;

    await _handleQrScanResult(result);
  }

  Future<void> _handleQrScanResult(String data) async {
    try {
      final qrData = jsonDecode(data) as Map<String, dynamic>;
      // 兼容两种负载结构
      final appId = qrData['app'] as String?;
      if (appId != null && appId.isNotEmpty && appId != 'SoulNote') {
        throw const FormatException('不兼容的应用二维码');
      }
      final pairingCode = (qrData['pairingCode'] ?? qrData['code'])?.toString();
      final targetPeerId =
          (qrData['peerId'] ?? qrData['deviceName'] ?? qrData['deviceId'])
              ?.toString();
      final targetPeerName =
          (qrData['peerName'] ?? qrData['deviceName'] ?? targetPeerId)
              ?.toString();
      if (pairingCode == null || targetPeerId == null || targetPeerId.isEmpty) {
        throw const FormatException('二维码缺少必要字段');
      }

      // 保存扫码信息
      setState(() {
        _qrTargetDeviceId = targetPeerId;
        _qrTargetDeviceName = targetPeerName;
        _qrPairingCode = pairingCode;
      });

      // 统一使用 peerId(displayName) 作为键保存配对码
      _syncService.setPendingPairingCode(targetPeerId, pairingCode);
      print('📝 已保存配对码: $targetPeerId -> $pairingCode');

      // 提示并开始广播与搜索
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在搜索设备: ${targetPeerName ?? targetPeerId}...'),
            backgroundColor: const Color(0xFF3B82F6),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('🔄 重新开始广播和搜索...');
      await _syncService.startScanningForBinding();

      // 首次快速检查
      print('⏳ 等待设备发现...');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // 当前列表检查
      ConnectedDevice foundDevice = _syncService.connectedDevices.firstWhere(
        (d) => d.id == targetPeerId || d.name == targetPeerName,
        orElse: () => ConnectedDevice(
          id: '',
          name: '',
          type: DeviceType.iphone,
          lastSyncTime: DateTime.now(),
        ),
      );

      if (foundDevice.id.isNotEmpty) {
        print('✅ 设备已发现，开始连接: ${foundDevice.name} (${foundDevice.id})');
        setState(() {
          _qrTargetDeviceId = foundDevice.id;
        });
        _connectToQrDevice();
      } else {
        // 重试轮询（最多 7 次，每次 2 秒）
        bool invited = false;
        for (int i = 0; i < 7; i++) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          final currentDevices = _syncService.connectedDevices;
          print('🔍 轮询第 ${i + 1} 次，设备数: ${currentDevices.length}');
          final retryFound = currentDevices.firstWhere(
            (d) => d.id == targetPeerId || d.name == targetPeerName,
            orElse: () => ConnectedDevice(
              id: '',
              name: '',
              type: DeviceType.iphone,
              lastSyncTime: DateTime.now(),
            ),
          );
          if (retryFound.id.isNotEmpty) {
            print('✅ 轮询发现设备，开始连接: ${retryFound.name} (${retryFound.id})');
            setState(() {
              _qrTargetDeviceId = retryFound.id;
            });
            _connectToQrDevice();
            invited = true;
            break;
          }
        }
        if (!invited && mounted) {
          print('⚠️ 超时未发现目标设备: $targetPeerName / $targetPeerId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('搜索超时，请确保对方也在绑定页面并已开始搜索'),
              backgroundColor: Color(0xFFFF9800),
            ),
          );
        }
      }

      print('📱 扫码完成: ${targetPeerName ?? targetPeerId} ($targetPeerId)');
    } catch (e) {
      print('❌ 二维码解析失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无效的二维码'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _connectToQrDevice() async {
    if (_qrTargetDeviceId == null || _qrPairingCode == null) {
      print(
          '❌ 连接参数不完整: deviceId=$_qrTargetDeviceId, pairingCode=$_qrPairingCode');
      return;
    }

    // 防止重复连接
    if (_isConnecting) {
      print('⏳ 正在连接中，跳过重复请求');
      return;
    }
    _isConnecting = true;

    try {
      print('🔗 发起连接邀请: $_qrTargetDeviceId (配对码: $_qrPairingCode)');

      // 使用配对码发起邀请
      await _multipeer.invitePeer(_qrTargetDeviceId!,
          pairingCode: _qrPairingCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('正在连接: $_qrTargetDeviceName...'),
            backgroundColor: const Color(0xFF3B82F6),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 设置超时，如果10秒后还没连接成功，提示用户
      Future.delayed(const Duration(seconds: 10), () async {
        _isConnecting = false;
        // 检查是否已连接
        final connectedPeers = await _multipeer.getConnectedPeers();
        if (_qrTargetDeviceId != null &&
            !connectedPeers.contains(_qrTargetDeviceId)) {
          print('⚠️ 连接超时');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('连接超时，请确保对方设备也在配对页面'),
                backgroundColor: Color(0xFFFF9800),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      });
    } catch (e) {
      _isConnecting = false;
      print('❌ 发起邀请失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendPairingVerification(String peerId, String code) async {
    try {
      final payload = {
        'type': 'pairingVerify',
        'code': code,
      };
      final jsonStr = jsonEncode(payload);
      final data = Uint8List.fromList(utf8.encode(jsonStr));
      await _multipeer.sendData(peerId, data);
      print('✅ 配对码验证已发送');
    } catch (e) {
      print('❌ 发送配对码验证失败: $e');
    }
  }

  String _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.iphone:
        return 'phone_iphone';
      case DeviceType.ipad:
        return 'tablet_mac';
      case DeviceType.mac:
        return 'laptop_mac';
      default:
        return 'devices';
    }
  }

  String _getLastSyncText(DateTime? lastSync) {
    if (lastSync == null) return '从未同步';

    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return '刚刚同步';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14),
      body: Stack(
        children: [
          // 背景渐变
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 主内容
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0C14).withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Bluetooth Binding',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // 内容区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // 我的二维码展示区域
                        GestureDetector(
                          onTap: _showMyQrCode,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Container(
                                  width: 192,
                                  height: 192,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFE2E8F0),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: _myQrCode != null
                                      ? QrImageView(
                                          data: _myQrCode!,
                                          version: QrVersions.auto,
                                          backgroundColor: Colors.transparent,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'My Device QR Code',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scan this on another device to pair',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 扫码绑定按钮
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _scanQrCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              elevation: 0,
                              shadowColor:
                                  const Color(0xFF3B82F6).withOpacity(0.2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Scan to Bind',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 已绑定设备列表
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'BOUND DEVICES',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: _boundDevices.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.devices_other,
                                        size: 48,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '暂无已绑定设备',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _boundDevices.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  itemBuilder: (context, index) {
                                    final device = _boundDevices[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                        child: Icon(
                                          _getDeviceIconData(device.type),
                                          color: const Color(0xFF93C5FD)
                                              .withOpacity(0.9),
                                          size: 22,
                                        ),
                                      ),
                                      title: Text(
                                        device.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Last synced ${_getLastSyncText(device.lastSyncTime)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        onPressed: () => _unbindDevice(device),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: const Color(0xFFEF4444)
                                              .withOpacity(0.6),
                                          size: 22,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 24),

                        // 底部说明
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Devices communicate over an encrypted P2P Bluetooth channel. No data ever leaves your local mesh network.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIconData(DeviceType type) {
    switch (type) {
      case DeviceType.iphone:
        return Icons.phone_iphone;
      case DeviceType.ipad:
        return Icons.tablet_mac;
      case DeviceType.mac:
        return Icons.laptop_mac;
      default:
        return Icons.devices;
    }
  }
}

/// 二维码扫描页面
class _QrScannerScreen extends StatefulWidget {
  final Function(String) onScanned;

  const _QrScannerScreen({required this.onScanned});

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '扫描设备二维码',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_scanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _scanned = true;
                  });
                  // 回调会处理 Navigator.pop
                  widget.onScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 扫描框
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF3B82F6),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // 提示文字
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              '将二维码放入框内',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
