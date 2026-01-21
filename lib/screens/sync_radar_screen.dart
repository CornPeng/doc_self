import 'package:flutter/material.dart';
import 'package:soul_note/services/bluetooth_sync_service.dart';

class SyncRadarScreen extends StatefulWidget {
  const SyncRadarScreen({super.key});

  @override
  State<SyncRadarScreen> createState() => _SyncRadarScreenState();
}

class _SyncRadarScreenState extends State<SyncRadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final BluetoothSyncService _syncService = BluetoothSyncService();
  
  List<ConnectedDevice> _devices = [];
  SyncStatus _syncStatus = SyncStatus.idle;

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
      await _syncService.initialize();
      
      // 监听设备列表
      _syncService.devicesStream.listen((devices) {
        if (mounted) {
          setState(() => _devices = devices);
        }
      });
      
      // 监听同步状态
      _syncService.statusStream.listen((status) {
        if (mounted) {
          setState(() => _syncStatus = status);
        }
      });
      
      // 自动开始扫描
      await _syncService.startScanning();
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _syncService.stopScanning();
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

  @override
  Widget build(BuildContext context) {
    // 使用原始设备数据或模拟数据
    final displayDevices = _devices.isNotEmpty ? _devices : [
      ConnectedDevice(
        id: 'mac-demo',
        name: 'MacBook Pro M2',
        type: DeviceType.mac,
        lastSyncTime: DateTime.now(),
        status: SyncStatus.idle,
      ),
      ConnectedDevice(
        id: 'ipad-demo',
        name: "Sarah's iPad Pro",
        type: DeviceType.ipad,
        lastSyncTime: DateTime.now().subtract(const Duration(hours: 1)),
        status: SyncStatus.syncing,
        progress: 0.85,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sync Radar'),
        backgroundColor: Colors.transparent,
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
                    'No Cloud — P2P Bluetooth Only',
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
                
                // Central Device
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smartphone,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                
                // MacBook Device
                Positioned(
                  top: 60,
                  left: 40,
                  child: GestureDetector(
                    onTap: () {
                      if (_devices.isNotEmpty) {
                        _syncService.syncWithDevice(displayDevices[0].id);
                      }
                    },
                    child: _buildOrbitingDevice(
                      icon: _getDeviceIcon(displayDevices[0].type),
                      label: displayDevices[0].status == SyncStatus.syncing 
                          ? 'Syncing ${((displayDevices[0].progress ?? 0) * 100).toInt()}%'
                          : 'Connected',
                      isConnected: true,
                      isSyncing: false,
                    ),
                  ),
                ),
                
                // iPad Device
                if (displayDevices.length > 1)
                  Positioned(
                    bottom: 100,
                    right: 30,
                    child: GestureDetector(
                      onTap: () {
                        if (_devices.isNotEmpty && _devices.length > 1) {
                          _syncService.syncWithDevice(displayDevices[1].id);
                        }
                      },
                      child: _buildOrbitingDevice(
                        icon: _getDeviceIcon(displayDevices[1].type),
                        label: 'Syncing ${((displayDevices[1].progress ?? 0.85) * 100).toInt()}%',
                        isConnected: false,
                        isSyncing: true,
                      ),
                    ),
                  ),
                
                // Scanning Status
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        _syncStatus == SyncStatus.scanning
                            ? 'Searching for nearby devices...'
                            : _syncStatus == SyncStatus.syncing
                            ? 'Syncing data...'
                            : 'Found ${displayDevices.length} devices',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay within 10 meters for best results',
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
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_devices.isNotEmpty) {
                      _syncService.syncWithDevice(displayDevices[0].id);
                    }
                  },
                  child: _buildDeviceListItem(
                    icon: _getDeviceIcon(displayDevices[0].type),
                    title: displayDevices[0].name,
                    subtitle: 'Last synced: ${_getTimeAgo(displayDevices[0].lastSyncTime)}',
                    subtitleColor: Colors.green,
                    showChevron: true,
                  ),
                ),
                Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                ),
                if (displayDevices.length > 1)
                  GestureDetector(
                    onTap: () {
                      if (_devices.isNotEmpty && _devices.length > 1) {
                        _syncService.syncWithDevice(displayDevices[1].id);
                      }
                    },
                    child: _buildDeviceListItem(
                      icon: _getDeviceIcon(displayDevices[1].type),
                      title: displayDevices[1].name,
                      subtitle: displayDevices[1].status == SyncStatus.syncing
                          ? 'Syncing files... ${((displayDevices[1].progress ?? 0.85) * 100).toInt()}%'
                          : 'Last synced: ${_getTimeAgo(displayDevices[1].lastSyncTime)}',
                      subtitleColor: displayDevices[1].status == SyncStatus.syncing
                          ? const Color(0xFF137FEC)
                          : Colors.white.withOpacity(0.6),
                      showPulse: displayDevices[1].status == SyncStatus.syncing,
                    ),
                  ),
              ],
            ),
          ),
          
          // Sync Now Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_devices.isNotEmpty) {
                    await _syncService.syncWithAllDevices();
                  } else {
                    await _syncService.startScanning();
                  }
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
                      _syncStatus == SyncStatus.syncing ? Icons.sync : Icons.sync,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _syncStatus == SyncStatus.syncing 
                          ? 'Syncing...'
                          : (_devices.isEmpty ? 'Scan Devices' : 'Sync Now'),
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
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'YOUR NOTES NEVER LEAVE YOUR LOCAL NETWORK.\nDATA IS ENCRYPTED END-TO-END.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
                letterSpacing: 1.2,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrbitingDevice({
    required IconData icon,
    required String label,
    bool isConnected = false,
    bool isSyncing = false,
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
                  value: 0.85,
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
