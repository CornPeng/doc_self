import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SoulNote'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LOCAL NOTES'**
  String get appSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get searchHint;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @createNote.
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get createNote;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @enterNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter note title...'**
  String get enterNoteTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?\\nThis will also delete all related messages.'**
  String deleteNoteConfirm(String title);

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotes;

  /// No description provided for @createFirstNote.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create your first note'**
  String get createFirstNote;

  /// No description provided for @p2pActive.
  ///
  /// In en, this message translates to:
  /// **'P2P Active'**
  String get p2pActive;

  /// No description provided for @messageInput.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageInput;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'Notes ({count})'**
  String notesCount(int count);

  /// No description provided for @messagesCount.
  ///
  /// In en, this message translates to:
  /// **'Messages ({count})'**
  String messagesCount(int count);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results found'**
  String get noSearchResults;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @deviceIdentity.
  ///
  /// In en, this message translates to:
  /// **'Device Identity'**
  String get deviceIdentity;

  /// No description provided for @deviceIdentityDesc.
  ///
  /// In en, this message translates to:
  /// **'Visible to nearby P2P devices'**
  String get deviceIdentityDesc;

  /// No description provided for @storageManagement.
  ///
  /// In en, this message translates to:
  /// **'Storage Management'**
  String get storageManagement;

  /// No description provided for @storageSize.
  ///
  /// In en, this message translates to:
  /// **'Local database: {size}'**
  String storageSize(String size);

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-Sync Preferences'**
  String get autoSync;

  /// No description provided for @autoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth auto-discovery for local sync'**
  String get autoSyncDesc;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Local Data'**
  String get deleteAllData;

  /// No description provided for @privacyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data never leaves your local network. No cloud, no tracking.'**
  String get privacyMessage;

  /// No description provided for @syncRadar.
  ///
  /// In en, this message translates to:
  /// **'Sync Radar'**
  String get syncRadar;

  /// No description provided for @noCloud.
  ///
  /// In en, this message translates to:
  /// **'No Cloud — P2P Bluetooth Only'**
  String get noCloud;

  /// No description provided for @searchingDevices.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby devices...'**
  String get searchingDevices;

  /// No description provided for @stayClose.
  ///
  /// In en, this message translates to:
  /// **'Stay within 10 meters for best results'**
  String get stayClose;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @encryptionMessage.
  ///
  /// In en, this message translates to:
  /// **'YOUR NOTES NEVER LEAVE YOUR LOCAL NETWORK.\\nDATA IS ENCRYPTED END-TO-END.'**
  String get encryptionMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageSystem;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your local notes and settings. This action cannot be undone.\n\nNote: This deletion only removes local cache. Other devices are not affected and data can be restored through synchronization.'**
  String get deleteAllDataMessage;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @editNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note Title'**
  String get editNoteTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @importMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Import Markdown'**
  String get importMarkdown;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export Markdown'**
  String get exportMarkdown;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportSuccess;

  /// No description provided for @chatNotes.
  ///
  /// In en, this message translates to:
  /// **'Chat Notes'**
  String get chatNotes;

  /// No description provided for @markdownNotes.
  ///
  /// In en, this message translates to:
  /// **'Markdown Notes'**
  String get markdownNotes;

  /// No description provided for @createChatNote.
  ///
  /// In en, this message translates to:
  /// **'Create Chat Note'**
  String get createChatNote;

  /// No description provided for @createMarkdownNote.
  ///
  /// In en, this message translates to:
  /// **'Create Markdown Note'**
  String get createMarkdownNote;

  /// No description provided for @bluetoothBinding.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Binding'**
  String get bluetoothBinding;

  /// No description provided for @bluetoothBindingDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage paired devices for P2P sync'**
  String get bluetoothBindingDesc;

  /// No description provided for @boundDevices.
  ///
  /// In en, this message translates to:
  /// **'BOUND DEVICES'**
  String get boundDevices;

  /// No description provided for @availableDevices.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE DEVICES'**
  String get availableDevices;

  /// No description provided for @noBoundDevices.
  ///
  /// In en, this message translates to:
  /// **'No bound devices yet'**
  String get noBoundDevices;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found\nTap \"Search for Devices\" to scan'**
  String get noDevicesFound;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @searchForDevices.
  ///
  /// In en, this message translates to:
  /// **'Search for Devices'**
  String get searchForDevices;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @showMyQr.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get showMyQr;

  /// No description provided for @scanQrToPair.
  ///
  /// In en, this message translates to:
  /// **'Scan to Pair'**
  String get scanQrToPair;

  /// No description provided for @enterPairingPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Pairing Password'**
  String get enterPairingPassword;

  /// No description provided for @linkTo.
  ///
  /// In en, this message translates to:
  /// **'Link to \"{name}\"'**
  String linkTo(String name);

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @pairingHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a device to initiate pairing. Ensure the other device is in discovery mode and has Bluetooth enabled for local P2P sync.'**
  String get pairingHint;

  /// No description provided for @pairedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Successfully paired with {name}'**
  String pairedSuccessfully(String name);

  /// No description provided for @unboundFrom.
  ///
  /// In en, this message translates to:
  /// **'Unbound from {name}'**
  String unboundFrom(String name);

  /// No description provided for @enterFourDigitPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 4-digit password'**
  String get enterFourDigitPassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
