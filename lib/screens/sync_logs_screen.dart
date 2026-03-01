import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soul_note/l10n/app_localizations.dart';
import 'package:soul_note/services/auto_sync_service.dart';

class SyncLogsScreen extends StatefulWidget {
  const SyncLogsScreen({super.key});

  @override
  State<SyncLogsScreen> createState() => _SyncLogsScreenState();
}

class _SyncLogsScreenState extends State<SyncLogsScreen> {
  final AutoSyncService _autoSyncService = AutoSyncService();
  List<SyncLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _autoSyncService.logsStream.listen((logs) {
      if (mounted) {
        setState(() {
          _logs = logs;
        });
      }
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  Color _getStatusColor(AutoSyncStatus status) {
    switch (status) {
      case AutoSyncStatus.success:
        return Colors.green;
      case AutoSyncStatus.failed:
      case AutoSyncStatus.noDeviceFound:
        return Colors.redAccent;
      case AutoSyncStatus.scanning:
      case AutoSyncStatus.syncing:
        return const Color(0xFF137FEC);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AutoSyncStatus status) {
    switch (status) {
      case AutoSyncStatus.success:
        return Icons.check_circle_outline;
      case AutoSyncStatus.failed:
        return Icons.error_outline;
      case AutoSyncStatus.noDeviceFound:
        return Icons.wifi_off;
      case AutoSyncStatus.scanning:
        return Icons.radar;
      case AutoSyncStatus.syncing:
        return Icons.sync;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.syncLogs),
        backgroundColor: Colors.transparent,
      ),
      body: _logs.isEmpty
          ? Center(
              child: Text(
                'No logs yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withOpacity(0.05),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          _getStatusIcon(log.status),
                          size: 16,
                          color: _getStatusColor(log.status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(log.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
