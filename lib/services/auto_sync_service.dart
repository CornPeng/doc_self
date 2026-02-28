import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul_note/services/sync_service.dart';

enum AutoSyncStatus {
  idle,
  scanning,
  syncing,
  success,
  failed,
  noDeviceFound,
}

class SyncLog {
  final DateTime timestamp;
  final AutoSyncStatus status;
  final String message;

  SyncLog({
    required this.timestamp,
    required this.status,
    required this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.index,
      'message': message,
    };
  }

  factory SyncLog.fromMap(Map<String, dynamic> map) {
    return SyncLog(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: AutoSyncStatus.values[map['status']],
      message: map['message'],
    );
  }
}

class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  final SyncService _syncService = SyncService();
  Timer? _scheduleTimer;
  bool _isAutoSyncEnabled = true;
  
  // 退避策略配置
  final List<int> _backoffIntervals = [1, 2, 5]; // 分钟
  int _currentBackoffIndex = 0;
  DateTime? _lastSyncTime;
  
  // 日志流
  final StreamController<List<SyncLog>> _logsController = StreamController.broadcast();
  Stream<List<SyncLog>> get logsStream => _logsController.stream;
  List<SyncLog> _logs = [];

  // 状态流
  final StreamController<AutoSyncStatus> _statusController = StreamController.broadcast();
  Stream<AutoSyncStatus> get statusStream => _statusController.stream;
  AutoSyncStatus _currentStatus = AutoSyncStatus.idle;

  // 初始化
  Future<void> initialize() async {
    await _syncService.initialize();
    _loadLogs();
    startAutoSync();
  }

  // 启动自动同步调度
  void startAutoSync() {
    if (!_isAutoSyncEnabled) return;
    
    print('⏰ 启动自动同步调度器');
    _scheduleNextSync(immediate: true);
  }

  // 停止自动同步
  void stopAutoSync() {
    print('🛑 停止自动同步调度器');
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _syncService.stopScanning();
  }

  void _scheduleNextSync({bool immediate = false}) {
    _scheduleTimer?.cancel();

    if (immediate) {
      _performAutoSync();
      return;
    }

    final intervalMinutes = _backoffIntervals[_currentBackoffIndex];
    final interval = Duration(minutes: intervalMinutes);
    
    print('⏳ 下次同步将在 $intervalMinutes 分钟后执行 (退避等级: $_currentBackoffIndex)');
    
    _scheduleTimer = Timer(interval, () {
      _performAutoSync();
    });
  }

  Future<void> _performAutoSync() async {
    if (_currentStatus == AutoSyncStatus.scanning || 
        _currentStatus == AutoSyncStatus.syncing) {
      print('⚠️ 当前正在同步中，跳过本次调度');
      return;
    }

    print('🚀 开始执行自动同步任务...');
    _updateStatus(AutoSyncStatus.scanning);
    _addLog(AutoSyncStatus.scanning, '开始自动扫描附近设备');

    try {
      // 1. 开始扫描 (30秒超时)
      await _syncService.startScanning();
      
      // 等待扫描结果
      await Future.delayed(const Duration(seconds: 30));
      
      final trustedDevices = _syncService.connectedDevices
          .where((d) => _syncService.isTrustedDevice(d.id))
          .toList();

      if (trustedDevices.isEmpty) {
        print('⚠️ 未发现可信任设备');
        _updateStatus(AutoSyncStatus.noDeviceFound);
        _addLog(AutoSyncStatus.noDeviceFound, '未发现可信任设备');
        _increaseBackoff();
        _syncService.stopScanning();
        _scheduleNextSync();
        return;
      }

      // 2. 发现设备，开始同步
      _updateStatus(AutoSyncStatus.syncing);
      _addLog(AutoSyncStatus.syncing, '发现 ${trustedDevices.length} 台设备，开始同步');
      
      // 这里直接复用 SyncService 的 syncWithAllDevices 逻辑
      // 注意：syncWithAllDevices 内部已经包含了连接重试逻辑
      await _syncService.syncWithAllDevices();

      // 检查同步结果（简单判断：如果没有抛出异常且执行完毕，视为成功）
      // 实际生产中可以更细致地检查每个设备的状态
      _updateStatus(AutoSyncStatus.success);
      _addLog(AutoSyncStatus.success, '自动同步完成');
      _resetBackoff(); // 成功后重置退避

    } catch (e) {
      print('❌ 自动同步失败: $e');
      _updateStatus(AutoSyncStatus.failed);
      _addLog(AutoSyncStatus.failed, '同步出错: $e');
      _increaseBackoff();
    } finally {
      // 总是停止扫描以省电
      await _syncService.stopScanning();
      // 总是调度下一次
      _scheduleNextSync();
    }
  }

  // 增加退避等级
  void _increaseBackoff() {
    if (_currentBackoffIndex < _backoffIntervals.length - 1) {
      _currentBackoffIndex++;
    }
  }

  // 重置退避等级
  void _resetBackoff() {
    _currentBackoffIndex = 0;
  }

  void _updateStatus(AutoSyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // 日志管理
  void _addLog(AutoSyncStatus status, String message) {
    final log = SyncLog(
      timestamp: DateTime.now(),
      status: status,
      message: message,
    );
    _logs.insert(0, log); // 最新在最前
    if (_logs.length > 50) {
      _logs.removeLast(); // 保留最近50条
    }
    _logsController.add(_logs);
    // TODO: 持久化日志到 SharedPreferences
  }

  void _loadLogs() {
    // TODO: 从 SharedPreferences 加载日志
    _logsController.add(_logs);
  }
  
  // 手动触发一次同步
  void manualSync() {
    print('👆 用户手动触发同步');
    _resetBackoff(); // 手动触发重置退避
    _scheduleNextSync(immediate: true);
  }

  void dispose() {
    _scheduleTimer?.cancel();
    _logsController.close();
    _statusController.close();
  }
}
