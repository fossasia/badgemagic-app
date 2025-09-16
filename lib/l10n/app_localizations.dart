import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge Magic'**
  String get appTitle;

  /// No description provided for @checkApacheLicense.
  ///
  /// In en, this message translates to:
  /// **'Check Apache License 2.0 terms used on'**
  String get checkApacheLicense;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save;

  /// No description provided for @savedBadges.
  ///
  /// In en, this message translates to:
  /// **'Saved Badges'**
  String get savedBadges;

  /// No description provided for @savedBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Badges'**
  String get savedBadgesTitle;

  /// No description provided for @drawClipart.
  ///
  /// In en, this message translates to:
  /// **'Draw Clipart'**
  String get drawClipart;

  /// No description provided for @drawClipartTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw Clipart'**
  String get drawClipartTitle;

  /// No description provided for @transferButton.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferButton;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectBadge.
  ///
  /// In en, this message translates to:
  /// **'Select Badge'**
  String get selectBadge;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @badgeNameExists.
  ///
  /// In en, this message translates to:
  /// **'Badge name exists'**
  String get badgeNameExists;

  /// No description provided for @similarBadgeNameExists.
  ///
  /// In en, this message translates to:
  /// **'Similar badge name exists'**
  String get similarBadgeNameExists;

  /// No description provided for @badgeNameExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A badge with this name already exists. Do you want to overwrite it?'**
  String get badgeNameExistsMessage;

  /// No description provided for @similarBadgeNameMessage.
  ///
  /// In en, this message translates to:
  /// **'A badge with a similar name already exists. Do you want to overwrite it?'**
  String get similarBadgeNameMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Do you want to proceed?'**
  String get deleteConfirmation;

  /// No description provided for @deleteBadgeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this badge?'**
  String get deleteBadgeConfirmation;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noBadgesFound.
  ///
  /// In en, this message translates to:
  /// **'No badges found'**
  String get noBadgesFound;

  /// No description provided for @noClipartFound.
  ///
  /// In en, this message translates to:
  /// **'No clipart found'**
  String get noClipartFound;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @createBadges.
  ///
  /// In en, this message translates to:
  /// **'Create Badges'**
  String get createBadges;

  /// No description provided for @savedCliparts.
  ///
  /// In en, this message translates to:
  /// **'Saved Cliparts'**
  String get savedCliparts;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @buyBadge.
  ///
  /// In en, this message translates to:
  /// **'Buy Badge'**
  String get buyBadge;

  /// No description provided for @feedbackBugReports.
  ///
  /// In en, this message translates to:
  /// **'Feedback/Bug Reports'**
  String get feedbackBugReports;

  /// No description provided for @shareAppText.
  ///
  /// In en, this message translates to:
  /// **'Badge Magic is an app to control LED name badges. This app provides features to portray names, graphics and simple animations on LED badges. You can also download it from below link https://play.google.com/store/apps/details?id=org.fossasia.badgemagic'**
  String get shareAppText;

  /// No description provided for @noSavedClipart.
  ///
  /// In en, this message translates to:
  /// **'No saved clipart!'**
  String get noSavedClipart;

  /// No description provided for @noSavedClipartMessage.
  ///
  /// In en, this message translates to:
  /// **'Looks like there are no saved cliparts yet.'**
  String get noSavedClipartMessage;

  /// No description provided for @savedClipartTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Clipart'**
  String get savedClipartTitle;

  /// No description provided for @aboutBadgeMagic.
  ///
  /// In en, this message translates to:
  /// **'Badge Magic is an app to control LED name badges. The goal is to provide options to portray names, graphics, and simple animations on LED badges. For the data transfer from the smartphone to the LED badge we use Bluetooth. The project is based on the work of Nihlcem.'**
  String get aboutBadgeMagic;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developedBy;

  /// No description provided for @fossasiaContributors.
  ///
  /// In en, this message translates to:
  /// **'FOSSASIA contributors'**
  String get fossasiaContributors;

  /// No description provided for @contactWithUs.
  ///
  /// In en, this message translates to:
  /// **'Contact With Us'**
  String get contactWithUs;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @speedTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedTitle;

  /// No description provided for @animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// No description provided for @transition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get transition;

  /// No description provided for @transitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get transitionTitle;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @effectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effectsTitle;

  /// No description provided for @effectsTab.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effectsTab;

  /// No description provided for @pacman.
  ///
  /// In en, this message translates to:
  /// **'Pacman'**
  String get pacman;

  /// No description provided for @chevron.
  ///
  /// In en, this message translates to:
  /// **'Chevron'**
  String get chevron;

  /// No description provided for @diamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get diamond;

  /// No description provided for @brokenHearts.
  ///
  /// In en, this message translates to:
  /// **'Broken Hearts'**
  String get brokenHearts;

  /// No description provided for @cupid.
  ///
  /// In en, this message translates to:
  /// **'Cupid'**
  String get cupid;

  /// No description provided for @feet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get feet;

  /// No description provided for @fishKiss.
  ///
  /// In en, this message translates to:
  /// **'Fish Kiss'**
  String get fishKiss;

  /// No description provided for @diagonal.
  ///
  /// In en, this message translates to:
  /// **'Diagonal'**
  String get diagonal;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @beatingHearts.
  ///
  /// In en, this message translates to:
  /// **'Beating Hearts'**
  String get beatingHearts;

  /// No description provided for @fireworks.
  ///
  /// In en, this message translates to:
  /// **'Fireworks'**
  String get fireworks;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizer;

  /// No description provided for @switchToSpecialAnimation.
  ///
  /// In en, this message translates to:
  /// **'Switch to Special Animation?'**
  String get switchToSpecialAnimation;

  /// No description provided for @specialAnimationWarning.
  ///
  /// In en, this message translates to:
  /// **'Selecting this animation will overwrite your current text.'**
  String get specialAnimationWarning;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard!'**
  String get textCopied;

  /// No description provided for @githubDescription.
  ///
  /// In en, this message translates to:
  /// **'Fork the repo and push changes or submit new issues.'**
  String get githubDescription;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @editingBadge.
  ///
  /// In en, this message translates to:
  /// **'Editing badge'**
  String get editingBadge;

  /// No description provided for @failedToLoadBadgeData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load badge data'**
  String get failedToLoadBadgeData;

  /// No description provided for @saveBadge.
  ///
  /// In en, this message translates to:
  /// **'Save Badge'**
  String get saveBadge;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @createNewBadge.
  ///
  /// In en, this message translates to:
  /// **'Create New Badge'**
  String get createNewBadge;

  /// No description provided for @enterTextHere.
  ///
  /// In en, this message translates to:
  /// **'Enter text here...'**
  String get enterTextHere;

  /// No description provided for @applyEffects.
  ///
  /// In en, this message translates to:
  /// **'Apply Effects'**
  String get applyEffects;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @sendToBadge.
  ///
  /// In en, this message translates to:
  /// **'Send to Badge'**
  String get sendToBadge;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully!'**
  String get savedSuccessfully;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving badge'**
  String get errorSaving;

  /// No description provided for @enterBadgeName.
  ///
  /// In en, this message translates to:
  /// **'Enter badge name'**
  String get enterBadgeName;

  /// No description provided for @invertEffect.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get invertEffect;

  /// No description provided for @invertTitle.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get invertTitle;

  /// No description provided for @fixedAnimation.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixedAnimation;

  /// No description provided for @fixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixedTitle;

  /// No description provided for @flashEffect.
  ///
  /// In en, this message translates to:
  /// **'Flash Effect'**
  String get flashEffect;

  /// No description provided for @marqueeEffect.
  ///
  /// In en, this message translates to:
  /// **'Marquee Effect'**
  String get marqueeEffect;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @veryFast.
  ///
  /// In en, this message translates to:
  /// **'Very Fast'**
  String get veryFast;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectBadgeType.
  ///
  /// In en, this message translates to:
  /// **'Select Badge Type'**
  String get selectBadgeType;

  /// No description provided for @badgeTypeLsled.
  ///
  /// In en, this message translates to:
  /// **'LS LED'**
  String get badgeTypeLsled;

  /// No description provided for @badgeTypeVblab.
  ///
  /// In en, this message translates to:
  /// **'VB Lab'**
  String get badgeTypeVblab;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Badge Magic'**
  String get aboutApp;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Create and customize LED badge messages with ease. Design, save and share your creations.'**
  String get appDescription;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get allRightsReserved;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @snowflake.
  ///
  /// In en, this message translates to:
  /// **'Snowflake'**
  String get snowflake;

  /// No description provided for @picture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get picture;

  /// No description provided for @laser.
  ///
  /// In en, this message translates to:
  /// **'Laser'**
  String get laser;

  /// No description provided for @wipe.
  ///
  /// In en, this message translates to:
  /// **'Wipe'**
  String get wipe;

  /// No description provided for @inText.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inText;

  /// No description provided for @outText.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outText;

  /// No description provided for @animationLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get animationLeft;

  /// No description provided for @animationRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get animationRight;

  /// No description provided for @animationUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get animationUp;

  /// No description provided for @animationDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get animationDown;

  /// No description provided for @animationFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get animationFixed;

  /// No description provided for @animationSnowflake.
  ///
  /// In en, this message translates to:
  /// **'Snowflake'**
  String get animationSnowflake;

  /// No description provided for @animationPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get animationPicture;

  /// No description provided for @animationLaser.
  ///
  /// In en, this message translates to:
  /// **'Laser'**
  String get animationLaser;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @badgeImportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Badge imported successfully'**
  String get badgeImportedSuccessfully;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @clipartSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Clipart saved successfully'**
  String get clipartSavedSuccessfully;

  /// No description provided for @failedToSaveBadge.
  ///
  /// In en, this message translates to:
  /// **'Failed to save badge'**
  String get failedToSaveBadge;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get pleaseEnterMessage;

  /// No description provided for @badgeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Badge updated successfully'**
  String get badgeUpdatedSuccessfully;

  /// No description provided for @badgeExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A badge with this name already exists. What would you like to do?'**
  String get badgeExistsMessage;

  /// No description provided for @similarBadgeExists.
  ///
  /// In en, this message translates to:
  /// **'Similar badge name exists'**
  String get similarBadgeExists;

  /// No description provided for @similarBadgeExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A badge with a similar name already exists: \'{badgeName}\'. What would you like to do?'**
  String similarBadgeExistsMessage(Object badgeName);

  /// No description provided for @enterNewBadgeName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new badge name.'**
  String get enterNewBadgeName;

  /// No description provided for @deleteSelectedBadges.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Badges'**
  String get deleteSelectedBadges;

  /// No description provided for @deleteBadgesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected badges?'**
  String get deleteBadgesConfirmation;

  /// No description provided for @transferBadge.
  ///
  /// In en, this message translates to:
  /// **'Transfer Badge'**
  String get transferBadge;

  /// No description provided for @transferConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to transfer the badge to the device?'**
  String get transferConfirmation;

  /// No description provided for @editBadge.
  ///
  /// In en, this message translates to:
  /// **'Edit Badge'**
  String get editBadge;

  /// No description provided for @editBadgeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to edit this badge?'**
  String get editBadgeConfirmation;

  /// No description provided for @badgesDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Selected badges deleted successfully'**
  String get badgesDeletedSuccessfully;

  /// No description provided for @pleaseEnterNewBadgeName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new badge name.'**
  String get pleaseEnterNewBadgeName;

  /// No description provided for @badgeSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Badge saved successfully'**
  String get badgeSavedSuccessfully;

  /// No description provided for @badgeName.
  ///
  /// In en, this message translates to:
  /// **'Badge Name'**
  String get badgeName;

  /// No description provided for @invertColors.
  ///
  /// In en, this message translates to:
  /// **'Invert Colors'**
  String get invertColors;

  /// No description provided for @badge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get badge;

  /// No description provided for @shapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get shapes;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @square.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get square;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @circle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circle;

  /// No description provided for @connectToBadgesWithNames.
  ///
  /// In en, this message translates to:
  /// **'Connect to badges with the following names'**
  String get connectToBadgesWithNames;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @scanSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Scan settings saved'**
  String get scanSettingsSaved;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @connectToAnyBadge.
  ///
  /// In en, this message translates to:
  /// **'Connect to any badge'**
  String get connectToAnyBadge;

  /// No description provided for @badgeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Badge name'**
  String get badgeNameHint;

  /// No description provided for @triangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get triangle;

  /// No description provided for @badgeScanMode.
  ///
  /// In en, this message translates to:
  /// **'Badge Scan Mode'**
  String get badgeScanMode;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
