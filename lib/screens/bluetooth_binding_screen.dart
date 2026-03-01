import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:soul_note/services/sync_service.dart';
import 'package:soul_note/services/multipeer_service.dart';
import 'package:soul_note/l10n/app_localizations.dart';

class BluetoothBindingScreen extends StatefulWidget {
  const BluetoothBindingScreen({super.key});

  @override
  State<BluetoothBindingScreen> createState() => _BluetoothBindingScreenState();
}

class _BluetoothBindingScreenState extends State<BluetoothBindingScreen> {
  final SyncService _syncService = SyncService();
  final MultipeerService _multipeer = MultipeerService();

  List<ConnectedDevice> _availableDevices = [];
  List<ConnectedDevice> _boundDevices = [];
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _isScanning = false;

  ConnectedDevice? _selectedDeviceForPairing;
  String? _activeQrPairingCode;
  String? _qrTargetPeerId;
  String? _qrTargetPeerName;
  String? _qrTargetPairingCode;
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _loadBoundDevices();
    _setupListeners();
    // 页面打开时自动开始搜索
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchDevices();
    });
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _setupListeners() {
    // 监听设备列表
    _syncService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _availableDevices = devices.where((d) => !_isBound(d.id)).toList();
        });
      }
    });

    // 监听同步状态
    _syncService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
          _isScanning = status == SyncStatus.scanning;
        });
      }
    });

    // 监听 Multipeer 事件
    _multipeer.eventStream.listen((event) {
      if (!mounted) return;

      print('📱 [绑定页面] 收到 Multipeer 事件: ${event.type}');

      switch (event.type) {
        case MultipeerEventType.peerFound:
          _tryAutoInviteFromQr();
          break;
        case MultipeerEventType.invitationReceived:
          // 收到配对邀请，弹出对话框（配对码可能缺失，使用手动输入验证）
          if (event.pairingCode != null && event.pairingCode!.isNotEmpty) {
            print(
                '📱 [绑定页面] 收到配对邀请: ${event.peerName}, 配对码: ${event.pairingCode}');
          } else {
            print('⚠️ [绑定页面] 收到邀请但无配对码');
          }
          if (_activeQrPairingCode != null &&
              (event.pairingCode == null || event.pairingCode!.isEmpty)) {
            _syncService.setPendingPairingCode(
                event.peerId, _activeQrPairingCode!);
            _multipeer.acceptInvitation();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.qrPairingVerifying),
                backgroundColor: const Color(0xFF3B82F6),
              ),
            );
          } else {
            _showReceiverPairingDialog(
              event.peerId,
              event.peerName,
              pairingCode: event.pairingCode,
            );
          }
          break;

        case MultipeerEventType.peerStateChanged:
          // 连接状态变化
          if (event.state == PeerConnectionState.connected) {
            print('✅ [绑定页面] 设备已连接: ${event.peerName}');
            if (_qrTargetPeerId == event.peerId &&
                _qrTargetPairingCode != null) {
              _sendPairingVerify(event.peerId, _qrTargetPairingCode!);
            }
          }
          break;

        default:
          break;
      }
    });

    // 监听配对结果
    _syncService.pairingResultStream.listen((result) {
      if (!mounted) return;
      String? deviceName;
      for (final device in _syncService.connectedDevices) {
        if (device.id == result.peerId) {
          deviceName = device.name;
          break;
        }
      }
      final displayName = deviceName ?? result.peerId;

      final snackBar = SnackBar(
        content: Text(
          result.success ? '已与 $displayName 配对成功' : result.message,
        ),
        backgroundColor:
            result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      if (result.success) {
        ConnectedDevice? device;
        for (final item in _syncService.connectedDevices) {
          if (item.id == result.peerId) {
            device = item;
            break;
          }
        }
        _syncService.addTrustedDevice(
          result.peerId,
          name: device?.name ?? result.peerId,
          type: device?.type ?? DeviceType.iphone,
        );
        _loadBoundDevices();
      }
    });
  }

  Future<void> _loadBoundDevices() async {
    // 从 SharedPreferences 加载已绑定的设备
    final boundDevices = _syncService.getTrustedDevices();
    final connectedMap = {
      for (final device in _syncService.connectedDevices) device.id: device,
    };
    setState(() {
      _boundDevices = boundDevices.map((d) => connectedMap[d.id] ?? d).toList();
    });
  }

  bool _isBound(String deviceId) {
    return _syncService.isTrustedDevice(deviceId);
  }

  Future<void> _searchDevices() async {
    print('🔍 [DEBUG] 开始搜索设备...');
    setState(() => _isScanning = true);

    try {
      await _syncService.startScanningForBinding();
      print('✅ [DEBUG] 扫描已启动');
      _tryAutoInviteFromQr();
    } catch (e) {
      print('❌ [DEBUG] 扫描失败: $e');
      setState(() => _isScanning = false);
    }
    // 扫描会在10秒后自动停止
  }

  void _showPairingDialog(ConnectedDevice device) {
    setState(() => _selectedDeviceForPairing = device);

    // 生成随机4位配对码
    final pairingCode = _generatePairingCode();
    _syncService.setPendingPairingCode(device.id, pairingCode);

    // 清空输入
    for (var controller in _pinControllers) {
      controller.clear();
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _buildInitiatorPairingDialog(device, pairingCode),
    );
  }

  String _generatePairingCode() {
    // 生成4位数字配对码
    return (1000 +
            (9000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)
                .toInt())
        .toString();
  }

  void _showMyQrCode() {
    final pairingCode = _generatePairingCode();
    _activeQrPairingCode = pairingCode;
    final payload = jsonEncode({
      'app': 'SoulNote',
      'peerName': _syncService.deviceName ?? 'SoulNote',
      'peerId': _syncService.deviceId ?? _syncService.deviceName ?? 'SoulNote',
      'pairingCode': pairingCode,
    });

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '我的配对二维码',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '请对方扫码以自动连接',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: payload,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '配对码：$pairingCode',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _activeQrPairingCode = null;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '关闭',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showScanQrDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                '扫码配对',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final codes = capture.barcodes;
                      if (codes.isEmpty) {
                        return;
                      }
                      final raw = codes.first.rawValue;
                      if (raw == null || raw.isEmpty) {
                        return;
                      }
                      _handleQrPayload(raw);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQrPayload(String raw) {
    final l10n = AppLocalizations.of(context)!;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['app'] != 'SoulNote') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidQr),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      _qrTargetPeerId = map['peerId'] as String?;
      _qrTargetPeerName = map['peerName'] as String?;
      _qrTargetPairingCode = map['pairingCode'] as String?;
      if (_qrTargetPeerId == null || _qrTargetPairingCode == null) {
        throw const FormatException('QR payload missing fields');
      }
      _syncService.setPendingPairingCode(
          _qrTargetPeerId!, _qrTargetPairingCode!);
      _searchDevices();
      _tryAutoInviteFromQr();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.qrParseFailed),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _tryAutoInviteFromQr() {
    if (_qrTargetPeerId == null || _qrTargetPairingCode == null) {
      return;
    }
    for (final device in _syncService.connectedDevices) {
      if (device.id == _qrTargetPeerId || device.name == _qrTargetPeerName) {
        _sendInvitation(device, _qrTargetPairingCode!);
        return;
      }
    }
  }

  // 发起方看到的对话框 - 显示生成的配对码
  Widget _buildInitiatorPairingDialog(
      ConnectedDevice device, String pairingCode) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        l10n.enterPairingPassword,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.linkTo(device.name),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '请让对方输入以下配对码：',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 显示配对码
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05060A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: Text(
                          pairingCode,
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _sendInvitation(device, pairingCode);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.link,
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 发送邀请
  Future<void> _sendInvitation(
      ConnectedDevice device, String pairingCode) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _syncService.setPendingPairingCode(device.id, pairingCode);
      await _multipeer.invitePeer(device.id, pairingCode: pairingCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sendingPairingRequest(device.name)),
          backgroundColor: const Color(0xFF3B82F6),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.inviteFailed('$e')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _sendPairingVerify(String peerId, String code) async {
    final payload = {
      'type': 'pairingVerify',
      'code': code,
    };
    final jsonStr = jsonEncode(payload);
    final data = Uint8List.fromList(utf8.encode(jsonStr));
    await _multipeer.sendData(peerId, data);
  }

  // 接收方看到的对话框 - 输入配对码
  void _showReceiverPairingDialog(
    String peerId,
    String peerName, {
    String? pairingCode,
  }) {
    // 清空输入
    for (var controller in _pinControllers) {
      controller.clear();
    }

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          l10n.enterPairingPassword,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.linkTo(peerName),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          pairingCode != null && pairingCode.isNotEmpty
                              ? '对方的配对码是: $pairingCode'
                              : '请输入对方提供的配对码以确认:',
                          style: TextStyle(
                            color: pairingCode != null && pairingCode.isNotEmpty
                                ? const Color(0xFF3B82F6)
                                : Colors.white.withOpacity(0.6),
                            fontSize:
                                pairingCode != null && pairingCode.isNotEmpty
                                    ? 14
                                    : 13,
                            fontWeight:
                                pairingCode != null && pairingCode.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: SizedBox(
                                width: 48,
                                height: 56,
                                child: TextField(
                                  controller: _pinControllers[index],
                                  focusNode: _pinFocusNodes[index],
                                  maxLength: 1,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: TextInputType.number,
                                  scrollPadding:
                                      const EdgeInsets.only(bottom: 120),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: const Color(0xFF05060A),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 3) {
                                      _pinFocusNodes[index + 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _multipeer.rejectInvitation();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _confirmReceiverPairing(
                              peerId,
                              peerName,
                              expectedCode: pairingCode,
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                            ),
                            child: Text(
                              '确认',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 接收方确认配对
  Future<void> _confirmReceiverPairing(
    String peerId,
    String peerName, {
    String? expectedCode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // 获取输入的PIN码
    final enteredPin = _pinControllers.map((c) => c.text).join();

    if (enteredPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterFourDigitPassword),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    // 有预期配对码时进行本地校验
    if (expectedCode != null &&
        expectedCode.isNotEmpty &&
        enteredPin != expectedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pairingCodeMismatch),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      // 清空输入
      for (var controller in _pinControllers) {
        controller.clear();
      }
      _pinFocusNodes[0].requestFocus();
      return;
    }

    // 配对码匹配，接受邀请
    Navigator.pop(context);
    await _multipeer.acceptInvitation();

    await _sendPairingVerify(peerId, enteredPin);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.waitingForConfirm(peerName)),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Future<void> _confirmPairing(ConnectedDevice device) async {
    // 这个方法已被 _sendInvitation 和 _confirmReceiverPairing 替代
    // 保留是为了兼容性，但不再使用
    await _syncService.addTrustedDevice(device.id);

    Navigator.pop(context);

    setState(() {
      _boundDevices.add(device);
      _availableDevices.remove(device);
    });

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.pairedSuccessfully(device.name)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _unbindDevice(ConnectedDevice device) async {
    await _syncService.removeTrustedDevice(device.id);

    setState(() {
      _boundDevices.remove(device);
      _availableDevices =
          _syncService.connectedDevices.where((d) => !_isBound(d.id)).toList();
    });

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.unboundFrom(device.name)),
        backgroundColor: const Color(0xFF6B7280),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mac:
        return Icons.laptop_mac;
      case DeviceType.ipad:
        return Icons.tablet_mac;
      case DeviceType.iphone:
        return Icons.phone_iphone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14),
      body: Stack(
        children: [
          // Background blur effects
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

          // Main content
          Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C14).withOpacity(0.9),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.settings,
                                style: TextStyle(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.bluetoothBinding,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 80),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 24),

                    // Bound Devices
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              l10n.boundDevices,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: _boundDevices.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        l10n.noBoundDevices,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                        _boundDevices.length, (index) {
                                      final device = _boundDevices[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border:
                                              index < _boundDevices.length - 1
                                                  ? Border(
                                                      bottom: BorderSide(
                                                        color: Colors.white
                                                            .withOpacity(0.05),
                                                      ),
                                                    )
                                                  : null,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getDeviceIcon(device.type),
                                                color: const Color(0xFF93C5FD)
                                                    .withOpacity(0.8),
                                                size: 24,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  device.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    _unbindDevice(device),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: const Color(0xFFEF4444)
                                                      .withOpacity(0.7),
                                                  size: 22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Available Devices
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  l10n.availableDevices,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isScanning)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        const Color(0xFF3B82F6)
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: _availableDevices.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        _isScanning
                                            ? l10n.scanning
                                            : l10n.noDevicesFound,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                        _availableDevices.length, (index) {
                                      final device = _availableDevices[index];
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _showPairingDialog(device),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: index <
                                                      _availableDevices.length -
                                                          1
                                                  ? Border(
                                                      bottom: BorderSide(
                                                        color: Colors.white
                                                            .withOpacity(0.05),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getDeviceIcon(device.type),
                                                    color:
                                                        const Color(0xFF93C5FD)
                                                            .withOpacity(0.8),
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      device.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l10n.pairingHint,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0C14).withOpacity(0),
                    const Color(0xFF0A0C14).withOpacity(0.95),
                    const Color(0xFF0A0C14),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isScanning ? null : _searchDevices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            disabledBackgroundColor:
                                const Color(0xFF3B82F6).withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            elevation: 0,
                            shadowColor:
                                const Color(0xFF3B82F6).withOpacity(0.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isScanning ? Icons.sync : Icons.search,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isScanning
                                    ? l10n.searching
                                    : l10n.searchForDevices,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
