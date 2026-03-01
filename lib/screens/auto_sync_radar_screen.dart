import 'package:flutter/material.dart';
import 'package:soul_note/l10n/app_localizations.dart';
import 'package:soul_note/services/sync_service.dart';
import 'package:soul_note/services/auto_sync_service.dart';
import 'package:soul_note/screens/sync_logs_screen.dart';

class AutoSyncRadarScreen extends StatefulWidget {
  const AutoSyncRadarScreen({super.key});

  @override
  State<AutoSyncRadarScreen> createState() => _AutoSyncRadarScreenState();
}

class _AutoSyncRadarScreenState extends State<AutoSyncRadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AutoSyncService _autoSyncService = AutoSyncService();
  final SyncService _syncService = SyncService();
  
  List<ConnectedDevice> _devices = [];
  AutoSyncStatus _autoStatus = AutoSyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _autoSyncService.initialize();
      
      // 监听设备列表
      _syncService.devicesStream.listen((devices) {
        if (mounted) {
          setState(() => _devices = devices);
        }
      });
      
      // 监听自动同步状态
      _autoSyncService.statusStream.listen((status) {
        if (mounted) {
          setState(() => _autoStatus = status);
        }
      });
      
      // 启动自动同步
      _autoSyncService.startAutoSync();
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.iphone:
        return Icons.smartphone;
      case DeviceType.ipad:
        return Icons.tablet_mac;
      case DeviceType.mac:
        return Icons.laptop_mac;
    }
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  String _getStatusText() {
    switch (_autoStatus) {
      case AutoSyncStatus.idle:
        return 'Waiting for next sync...';
      case AutoSyncStatus.scanning:
        return 'Scanning for nearby devices...';
      case AutoSyncStatus.syncing:
        return 'Syncing data...';
      case AutoSyncStatus.success:
        return 'Sync completed successfully';
      case AutoSyncStatus.failed:
        return 'Sync failed, retrying later';
      case AutoSyncStatus.noDeviceFound:
        return 'No trusted devices found';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 仅显示可信任设备或已连接设备
    final displayDevices = _devices;

    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.autoSyncRadar),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sync Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncLogsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: const Color(0xFF137FEC),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto P2P Sync — Encrypted & Local',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Radar Section
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar Rings
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(300, 300),
                      painter: RadarPainter(_animationController.value),
                    );
                  },
                ),
                
                // Central Device (Current Device)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF137FEC),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _syncService.deviceType != null 
                        ? _getDeviceIcon(_syncService.deviceType!)
                        : Icons.smartphone,
                    size: 36,
                    color: const Color(0xFF137FEC),
                  ),
                ),
                
                // 显示发现的设备
                ..._buildOrbitingDevices(),
                
                // Scanning Status
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next scan in progress based on schedule',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Devices List
          if (displayDevices.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2632).withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: displayDevices.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                ),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _syncService.syncWithDevice(displayDevices[i].id),
                    child: _buildDeviceListItem(
                      icon: _getDeviceIcon(displayDevices[i].type),
                      title: displayDevices[i].name,
                      subtitle: displayDevices[i].status == SyncStatus.syncing
                          ? 'Syncing... ${((displayDevices[i].progress ?? 0) * 100).toInt()}%'
                          : 'Last synced: ${_getTimeAgo(displayDevices[i].lastSyncTime)}',
                      subtitleColor: displayDevices[i].status == SyncStatus.syncing
                          ? const Color(0xFF137FEC)
                          : (DateTime.now().difference(displayDevices[i].lastSyncTime).inMinutes < 30
                              ? Colors.green
                              : Colors.white.withOpacity(0.6)),
                      showChevron: true,
                      showPulse: displayDevices[i].status == SyncStatus.syncing,
                    ),
                  );
                },
              ),
            ),
          
          // Manual Sync Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _autoSyncService.manualSync();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _autoStatus == AutoSyncStatus.syncing ? Icons.sync : Icons.sync,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _autoStatus == AutoSyncStatus.syncing 
                          ? 'Syncing...'
                          : 'Sync Now (Manual)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 复用原来的 RadarPainter 和构建方法
  // ... (_buildOrbitingDevices, _buildOrbitingDevice, _buildDeviceListItem 同 SyncRadarScreen)
  
  List<Widget> _buildOrbitingDevices() {
    final List<Widget> widgets = [];
    final positions = [
      {'top': 60.0, 'left': 40.0},
      {'bottom': 100.0, 'right': 30.0},
      {'top': 80.0, 'right': 40.0},
    ];
    
    for (int i = 0; i < _devices.length && i < 3; i++) {
      final device = _devices[i];
      final pos = positions[i];
      
      final isConnected = device.status == SyncStatus.idle && 
                         DateTime.now().difference(device.lastSyncTime).inMinutes < 30;
      final isSyncing = device.status == SyncStatus.syncing;
      final label = isSyncing
          ? 'Syncing ${((device.progress ?? 0) * 100).toInt()}%'
          : (isConnected ? 'Connected' : _getDeviceTypeName(device.type));
      
      widgets.add(
        Positioned(
          top: pos['top'],
          bottom: pos['bottom'],
          left: pos['left'],
          right: pos['right'],
          child: GestureDetector(
            onTap: () => _syncService.syncWithDevice(device.id),
            child: _buildOrbitingDevice(
              icon: _getDeviceIcon(device.type),
              label: label,
              isConnected: isConnected,
              isSyncing: isSyncing,
              progress: device.progress ?? 0.0,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

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

  Widget _buildOrbitingDevice({
    required IconData icon,
    required String label,
    bool isConnected = false,
    bool isSyncing = false,
    double progress = 0.0,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF283039),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isConnected
                      ? Colors.green
                      : const Color(0xFF137FEC).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            if (isConnected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF101922),
                      width: 2,
                    ),
                  ),
                ),
              ),
            if (isSyncing)
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF137FEC)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF283039).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected
                  ? Colors.green.withOpacity(0.3)
                  : const Color(0xFF137FEC).withOpacity(0.3),
                  width: 1,
                ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isConnected ? Colors.green : const Color(0xFF137FEC),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    bool showChevron = false,
    bool showPulse = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: showChevron
                  ? const Color(0xFF137FEC).withOpacity(0.2)
                  : const Color(0xFF283039),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: showChevron ? const Color(0xFF137FEC) : Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.4),
            ),
          if (showPulse)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;

  RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw three concentric circles
    final radii = [50.0, 100.0, 150.0];
    final opacities = [0.3, 0.2, 0.1];

    for (int i = 0; i < radii.length; i++) {
      paint.color = const Color(0xFF137FEC).withOpacity(opacities[i]);
      canvas.drawCircle(center, radii[i], paint);
    }

    // Draw animated pulse
    final pulseRadius = 150 * animationValue;
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF137FEC).withOpacity(1 - animationValue);
    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
