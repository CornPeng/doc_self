import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soul_note/providers/language_provider.dart';
import 'package:soul_note/l10n/app_localizations.dart';
import 'package:soul_note/services/database_service.dart';
import 'package:soul_note/screens/bluetooth_binding_screen.dart';
import 'package:soul_note/screens/qr_bluetooth_binding_screen.dart';
import 'package:soul_note/screens/auto_sync_radar_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.settings),
        backgroundColor: const Color(0xFF101922),
      ),
      body: ListView(
        children: [
          // Language Section
          _buildSectionHeader(l10n.languageSettings.toUpperCase()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: _buildLanguageSetting(),
          ),

          // Identity & Storage Section
          _buildSectionHeader('IDENTITY & STORAGE'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.person,
                  iconColor: const Color(0xFF137FEC),
                  title: 'Device Identity',
                  subtitle: 'Visible to nearby P2P devices',
                  trailing: const Text(
                    'iPhone (Alex)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                  indent: 72,
                ),
                _buildSettingItem(
                  icon: Icons.storage,
                  iconColor: Colors.green,
                  title: 'Storage Management',
                  subtitle: 'Local database: 24.5 MB',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Connectivity Section
          _buildSectionHeader('CONNECTIVITY'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.bluetooth,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Bluetooth Search',
                  subtitle: 'Manual search & pairing',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BluetoothBindingScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                  indent: 72,
                ),
                _buildSettingItem(
                  icon: Icons.qr_code_scanner,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'QR Code Binding',
                  subtitle: 'Scan to bind devices quickly',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QrBluetoothBindingScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                  indent: 72,
                ),
                _buildSettingItem(
                  icon: Icons.sync,
                  iconColor: Colors.orange,
                  title: 'Auto-Sync Radar',
                  subtitle: 'Periodic sync & logs (Beta)',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AutoSyncRadarScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Danger Zone Section
          _buildSectionHeader('DANGER ZONE', color: Colors.red),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2632),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showDeleteDialog(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delete All Local Data',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Footer Philosophy
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2632),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your data never leaves your local network. No cloud, no tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.offline_pin,
                    color: Colors.white.withOpacity(0.3),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.bluetooth_connected,
                    color: Colors.white.withOpacity(0.3),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.security,
                    color: Colors.white.withOpacity(0.3),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSetting() {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale;

    return InkWell(
      onTap: () => _showLanguageDialog(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.language,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.selectLanguage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  currentLocale.languageCode == 'zh'
                      ? l10n.languageChinese
                      : l10n.languageEnglish,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentLocale = languageProvider.locale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2632),
        title: Text(
          l10n.languageSettings,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              l10n.languageChinese,
              const Locale('zh'),
              currentLocale,
              languageProvider,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              l10n.languageEnglish,
              const Locale('en'),
              currentLocale,
              languageProvider,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    Locale locale,
    Locale currentLocale,
    LanguageProvider languageProvider,
  ) {
    final isSelected = currentLocale == locale;

    return InkWell(
      onTap: () {
        languageProvider.setLocale(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF137FEC).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF137FEC)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF137FEC) : Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF137FEC),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2632),
        title: Text(
          l10n.deleteAllDataTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.deleteAllDataMessage,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Delete all data from database
      await DatabaseService.instance.deleteAllData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message if deletion fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
