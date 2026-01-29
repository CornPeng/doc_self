// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SoulNote';

  @override
  String get appSubtitle => 'LOCAL NOTES';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get notes => 'Notes';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get createNote => 'Create Note';

  @override
  String get newNote => 'New Note';

  @override
  String get enterNoteTitle => 'Enter note title...';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String deleteNoteConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?\\nThis will also delete all related messages.';
  }

  @override
  String get noNotes => 'No notes yet';

  @override
  String get createFirstNote =>
      'Tap the button below to create your first note';

  @override
  String get p2pActive => 'P2P Active';

  @override
  String get messageInput => 'Type a message...';

  @override
  String get startRecording => 'Start recording';

  @override
  String get selectImage => 'Select Image';

  @override
  String get selectVideo => 'Select Video';

  @override
  String notesCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String messagesCount(int count) {
    return 'Messages ($count)';
  }

  @override
  String get noSearchResults => 'No matching results found';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String get deviceIdentity => 'Device Identity';

  @override
  String get deviceIdentityDesc => 'Visible to nearby P2P devices';

  @override
  String get storageManagement => 'Storage Management';

  @override
  String storageSize(String size) {
    return 'Local database: $size';
  }

  @override
  String get autoSync => 'Auto-Sync Preferences';

  @override
  String get autoSyncDesc => 'Bluetooth auto-discovery for local sync';

  @override
  String get deleteAllData => 'Delete All Local Data';

  @override
  String get privacyMessage =>
      'Your data never leaves your local network. No cloud, no tracking.';

  @override
  String get syncRadar => 'Sync Radar';

  @override
  String get noCloud => 'No Cloud — P2P Bluetooth Only';

  @override
  String get searchingDevices => 'Searching for nearby devices...';

  @override
  String get stayClose => 'Stay within 10 meters for best results';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get encryptionMessage =>
      'YOUR NOTES NEVER LEAVE YOUR LOCAL NETWORK.\\nDATA IS ENCRYPTED END-TO-END.';

  @override
  String get language => 'Language';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get deleteAllDataTitle => 'Delete All Data?';

  @override
  String get deleteAllDataMessage =>
      'This will permanently delete all your local notes and settings. This action cannot be undone.\n\nNote: This deletion only removes local cache. Other devices are not affected and data can be restored through synchronization.';

  @override
  String get deleteSuccess => 'All data deleted successfully';

  @override
  String get edit => 'Edit';

  @override
  String get editNote => 'Edit Note';

  @override
  String get editNoteTitle => 'Edit Note Title';

  @override
  String get save => 'Save';

  @override
  String get preview => 'Preview';

  @override
  String get importMarkdown => 'Import Markdown';

  @override
  String get exportMarkdown => 'Export Markdown';

  @override
  String get exportSuccess => 'Exported successfully';

  @override
  String get chatNotes => 'Chat Notes';

  @override
  String get markdownNotes => 'Markdown Notes';

  @override
  String get createChatNote => 'Create Chat Note';

  @override
  String get createMarkdownNote => 'Create Markdown Note';

  @override
  String get bluetoothBinding => 'Bluetooth Binding';

  @override
  String get bluetoothBindingDesc => 'Manage paired devices for P2P sync';

  @override
  String get boundDevices => 'BOUND DEVICES';

  @override
  String get availableDevices => 'AVAILABLE DEVICES';

  @override
  String get noBoundDevices => 'No bound devices yet';

  @override
  String get noDevicesFound =>
      'No devices found\nTap \"Search for Devices\" to scan';

  @override
  String get scanning => 'Scanning...';

  @override
  String get searchForDevices => 'Search for Devices';

  @override
  String get searching => 'Searching...';

  @override
  String get showMyQr => 'My QR Code';

  @override
  String get scanQrToPair => 'Scan to Pair';

  @override
  String get enterPairingPassword => 'Enter Pairing Password';

  @override
  String linkTo(String name) {
    return 'Link to \"$name\"';
  }

  @override
  String get link => 'Link';

  @override
  String get pairingHint =>
      'Tap a device to initiate pairing. Ensure the other device is in discovery mode and has Bluetooth enabled for local P2P sync.';

  @override
  String pairedSuccessfully(String name) {
    return 'Successfully paired with $name';
  }

  @override
  String unboundFrom(String name) {
    return 'Unbound from $name';
  }

  @override
  String get enterFourDigitPassword => 'Please enter a 4-digit password';
}
