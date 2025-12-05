import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @accessGrantedTo.
  ///
  /// In en, this message translates to:
  /// **'Access granted to {email}'**
  String accessGrantedTo(Object email);

  /// No description provided for @accomplishmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Accomplishment deleted'**
  String get accomplishmentDeleted;

  /// No description provided for @accomplishmentsReordered.
  ///
  /// In en, this message translates to:
  /// **'Accomplishments reordered'**
  String get accomplishmentsReordered;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @actionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Action Photo'**
  String get actionPhoto;

  /// No description provided for @actionPhotoCards.
  ///
  /// In en, this message translates to:
  /// **'Action photo cards'**
  String get actionPhotoCards;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addAssistQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Assist?'**
  String get addAssistQuestion;

  /// No description provided for @addAward.
  ///
  /// In en, this message translates to:
  /// **'Add Award'**
  String get addAward;

  /// No description provided for @addAwardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Award'**
  String get addAwardDialogTitle;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @addHighlight.
  ///
  /// In en, this message translates to:
  /// **'Add Highlight'**
  String get addHighlight;

  /// No description provided for @addHighlightDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Highlight'**
  String get addHighlightDialogTitle;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @adminAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Admin added successfully'**
  String get adminAddedSuccessfully;

  /// No description provided for @adminRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Admin removed successfully'**
  String get adminRemovedSuccessfully;

  /// No description provided for @advanceGame.
  ///
  /// In en, this message translates to:
  /// **'Advance Game'**
  String get advanceGame;

  /// No description provided for @allowPlayerEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Allow player to edit their profile on web'**
  String get allowPlayerEditProfile;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TeamSync'**
  String get appTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @areYouSureYouWantToDeleteThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event? This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisEvent;

  /// No description provided for @areYouSureYouWantToDeleteThisGame.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Game? All data associated with this Game will be deleted. This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisGame;

  /// No description provided for @areYouSureYouWantToDeleteThisPlayer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Player? All data associated with this Player will be deleted. This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisPlayer;

  /// No description provided for @areYouSureYouWantToDeleteThisSeason.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Season? All data associated with this Season will be deleted. This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisSeason;

  /// No description provided for @assistedBy.
  ///
  /// In en, this message translates to:
  /// **'Assisted by'**
  String get assistedBy;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get assists;

  /// No description provided for @automaticTheme.
  ///
  /// In en, this message translates to:
  /// **'Automatic Theme'**
  String get automaticTheme;

  /// No description provided for @automaticThemeSwitchDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically switch theme based on the time of day'**
  String get automaticThemeSwitchDescription;

  /// No description provided for @awardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Award deleted'**
  String get awardDeleted;

  /// No description provided for @awardSaved.
  ///
  /// In en, this message translates to:
  /// **'Award saved successfully'**
  String get awardSaved;

  /// No description provided for @awards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get awards;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'AWAY'**
  String get away;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup Current Database to Device'**
  String get backupDatabase;

  /// No description provided for @bestGame.
  ///
  /// In en, this message translates to:
  /// **'Best Game'**
  String get bestGame;

  /// No description provided for @bestSeason.
  ///
  /// In en, this message translates to:
  /// **'Best Season'**
  String get bestSeason;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @career.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get career;

  /// No description provided for @careerLeaders.
  ///
  /// In en, this message translates to:
  /// **'Career Leaders'**
  String get careerLeaders;

  /// No description provided for @careerStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Stats'**
  String get careerStatsTitle;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @changeTeamColors.
  ///
  /// In en, this message translates to:
  /// **'Change Team Colors'**
  String get changeTeamColors;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeSidebar.
  ///
  /// In en, this message translates to:
  /// **'Close sidebar'**
  String get closeSidebar;

  /// No description provided for @clubDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get clubDescription;

  /// No description provided for @clubDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your club'**
  String get clubDescriptionHint;

  /// No description provided for @clubName.
  ///
  /// In en, this message translates to:
  /// **'Club Name'**
  String get clubName;

  /// No description provided for @clubSyncAvailable.
  ///
  /// In en, this message translates to:
  /// **'ClubSync Available'**
  String get clubSyncAvailable;

  /// No description provided for @composeTweet.
  ///
  /// In en, this message translates to:
  /// **'Compose Tweet'**
  String get composeTweet;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @connectToTwitter.
  ///
  /// In en, this message translates to:
  /// **'Connect to Twitter'**
  String get connectToTwitter;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @continueWithoutSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing in'**
  String get continueWithoutSigningIn;

  /// No description provided for @convertToCloud.
  ///
  /// In en, this message translates to:
  /// **'Convert to a Cloud Database'**
  String get convertToCloud;

  /// No description provided for @corners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get corners;

  /// No description provided for @couldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open URL: {url}'**
  String couldNotOpenUrl(Object url);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAnyway.
  ///
  /// In en, this message translates to:
  /// **'Create Anyway'**
  String get createAnyway;

  /// No description provided for @createClub.
  ///
  /// In en, this message translates to:
  /// **'Create Club'**
  String get createClub;

  /// No description provided for @createNewCloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Create New Cloud Database'**
  String get createNewCloudDatabase;

  /// No description provided for @createNewClub.
  ///
  /// In en, this message translates to:
  /// **'Create New Club'**
  String get createNewClub;

  /// No description provided for @createNewDatabase.
  ///
  /// In en, this message translates to:
  /// **'Create New Database'**
  String get createNewDatabase;

  /// No description provided for @createNewGameToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Game to start'**
  String get createNewGameToStart;

  /// No description provided for @createNewOpponent.
  ///
  /// In en, this message translates to:
  /// **'Create New Opponent'**
  String get createNewOpponent;

  /// No description provided for @createNewSeason.
  ///
  /// In en, this message translates to:
  /// **'Create New Season'**
  String get createNewSeason;

  /// No description provided for @createNewSeasonToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Season to start'**
  String get createNewSeasonToStart;

  /// No description provided for @createNewTeam.
  ///
  /// In en, this message translates to:
  /// **'Create New Team'**
  String get createNewTeam;

  /// No description provided for @createNewTeamToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Team to start'**
  String get createNewTeamToStart;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @currently.
  ///
  /// In en, this message translates to:
  /// **'Currently'**
  String get currently;

  /// No description provided for @dataImport.
  ///
  /// In en, this message translates to:
  /// **'Data Import'**
  String get dataImport;

  /// No description provided for @databaseAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A cloud database with this name already exists.'**
  String get databaseAlreadyExists;

  /// No description provided for @databaseImportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Database import still in progress...'**
  String get databaseImportInProgress;

  /// No description provided for @databaseImported.
  ///
  /// In en, this message translates to:
  /// **'Database imported successfully!'**
  String get databaseImported;

  /// No description provided for @databaseName.
  ///
  /// In en, this message translates to:
  /// **'Database Name'**
  String get databaseName;

  /// No description provided for @databaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Database not found'**
  String get databaseNotFound;

  /// No description provided for @debugFirestoreRealtimeMigration.
  ///
  /// In en, this message translates to:
  /// **'Debug: Firestore → Realtime Migration'**
  String get debugFirestoreRealtimeMigration;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccomplishment.
  ///
  /// In en, this message translates to:
  /// **'Delete Accomplishment'**
  String get deleteAccomplishment;

  /// No description provided for @deleteAccomplishmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this accomplishment?'**
  String get deleteAccomplishmentConfirmation;

  /// No description provided for @deleteAwardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteAwardConfirm(Object title);

  /// No description provided for @deleteAwardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Award'**
  String get deleteAwardTitle;

  /// No description provided for @deleteHighlightConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteHighlightConfirm(Object title);

  /// No description provided for @deleteHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Highlight'**
  String get deleteHighlightTitle;

  /// No description provided for @displayOrder.
  ///
  /// In en, this message translates to:
  /// **'Display Order'**
  String get displayOrder;

  /// No description provided for @downloadErrorReport.
  ///
  /// In en, this message translates to:
  /// **'Download Error Report'**
  String get downloadErrorReport;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get downloadTemplate;

  /// No description provided for @duplicatePlayerName.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Player Name'**
  String get duplicatePlayerName;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Duration: {seconds} seconds'**
  String durationSeconds(Object seconds);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editAward.
  ///
  /// In en, this message translates to:
  /// **'Edit Award'**
  String get editAward;

  /// No description provided for @editGame.
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get editGame;

  /// No description provided for @editHighlight.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlight'**
  String get editHighlight;

  /// No description provided for @editPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Player'**
  String get editPlayer;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get endGame;

  /// No description provided for @endOfGame.
  ///
  /// In en, this message translates to:
  /// **'End of Game'**
  String get endOfGame;

  /// No description provided for @endOfRegulation.
  ///
  /// In en, this message translates to:
  /// **'End of Regulation'**
  String get endOfRegulation;

  /// No description provided for @enterEmailToAddAdmin.
  ///
  /// In en, this message translates to:
  /// **'Enter email to add as admin'**
  String get enterEmailToAddAdmin;

  /// No description provided for @enterFourDigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit PIN'**
  String get enterFourDigitPin;

  /// No description provided for @enterPinToEdit.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to Edit Profile'**
  String get enterPinToEdit;

  /// No description provided for @enterTeamIdPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a 6-digit Team ID to view stats:'**
  String get enterTeamIdPrompt;

  /// No description provided for @entityType.
  ///
  /// In en, this message translates to:
  /// **'Entity Type'**
  String get entityType;

  /// No description provided for @errorDeletingAccomplishment.
  ///
  /// In en, this message translates to:
  /// **'Error deleting accomplishment: {error}'**
  String errorDeletingAccomplishment(Object error);

  /// No description provided for @errorDeletingAward.
  ///
  /// In en, this message translates to:
  /// **'Error deleting award: {error}'**
  String errorDeletingAward(Object error);

  /// No description provided for @errorDeletingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Error deleting highlight: {error}'**
  String errorDeletingHighlight(Object error);

  /// No description provided for @errorDuringShare.
  ///
  /// In en, this message translates to:
  /// **'Error during share, please try again'**
  String get errorDuringShare;

  /// No description provided for @errorGeneratingLineup.
  ///
  /// In en, this message translates to:
  /// **'Error generating lineup: {error}'**
  String errorGeneratingLineup(Object error);

  /// No description provided for @errorLoadingAccessList.
  ///
  /// In en, this message translates to:
  /// **'Error loading access list: {error}'**
  String errorLoadingAccessList(Object error);

  /// No description provided for @errorLoadingAwards.
  ///
  /// In en, this message translates to:
  /// **'Error loading awards: {error}'**
  String errorLoadingAwards(Object error);

  /// No description provided for @errorLoadingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Error loading credentials: {error}'**
  String errorLoadingCredentials(Object error);

  /// No description provided for @errorLoadingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Error loading database.'**
  String get errorLoadingDatabase;

  /// No description provided for @errorLoadingDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Error loading duplicates: {error}'**
  String errorLoadingDuplicates(Object error);

  /// No description provided for @errorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get errorLoadingEvents;

  /// No description provided for @errorLoadingHighlights.
  ///
  /// In en, this message translates to:
  /// **'Error loading highlights: {error}'**
  String errorLoadingHighlights(Object error);

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @errorLoadingPlayerStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading player stats: {error}\n\nStack trace: {stack}'**
  String errorLoadingPlayerStats(Object error, Object stack);

  /// No description provided for @errorLoadingSharedDatabases.
  ///
  /// In en, this message translates to:
  /// **'Error loading shared databases: {error}'**
  String errorLoadingSharedDatabases(Object error);

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;

  /// No description provided for @errorLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String errorLoggingOut(Object error);

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(Object error);

  /// No description provided for @errorOpeningLink.
  ///
  /// In en, this message translates to:
  /// **'Error opening link: {error}'**
  String errorOpeningLink(Object error);

  /// No description provided for @errorReordering.
  ///
  /// In en, this message translates to:
  /// **'Error reordering: {error}'**
  String errorReordering(Object error);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(Object error);

  /// No description provided for @errorSavingAward.
  ///
  /// In en, this message translates to:
  /// **'Error saving award: {error}'**
  String errorSavingAward(Object error);

  /// No description provided for @errorSavingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Error saving highlight: {error}'**
  String errorSavingHighlight(Object error);

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String errorSavingSettings(Object error);

  /// No description provided for @errorSendingTweet.
  ///
  /// In en, this message translates to:
  /// **'Error sending tweet: {error}'**
  String errorSendingTweet(Object error);

  /// No description provided for @errorSharingImage.
  ///
  /// In en, this message translates to:
  /// **'Error sharing image: {error}'**
  String errorSharingImage(Object error);

  /// No description provided for @errorSharingToTwitter.
  ///
  /// In en, this message translates to:
  /// **'Error sharing to Twitter: {error}'**
  String errorSharingToTwitter(Object error);

  /// No description provided for @errorUpdatingGameTime.
  ///
  /// In en, this message translates to:
  /// **'Error updating game time: {error}'**
  String errorUpdatingGameTime(Object error);

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorUpdatingProfile(Object error);

  /// No description provided for @errorUploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Error uploading images: {error}'**
  String errorUploadingImages(Object error);

  /// No description provided for @exitEditMode.
  ///
  /// In en, this message translates to:
  /// **'Exit Edit Mode'**
  String get exitEditMode;

  /// No description provided for @failedToGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to grant access. User may not exist.'**
  String get failedToGrantAccess;

  /// No description provided for @failedToOpenDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to open database'**
  String get failedToOpenDatabase;

  /// No description provided for @failedToSendTweet.
  ///
  /// In en, this message translates to:
  /// **'Failed to send tweet. Please try again.'**
  String get failedToSendTweet;

  /// No description provided for @finalOT.
  ///
  /// In en, this message translates to:
  /// **'Final OT'**
  String get finalOT;

  /// No description provided for @finalOTText.
  ///
  /// In en, this message translates to:
  /// **'Final OT'**
  String get finalOTText;

  /// No description provided for @finalPKs.
  ///
  /// In en, this message translates to:
  /// **'Final PKs'**
  String get finalPKs;

  /// No description provided for @finalPKsText.
  ///
  /// In en, this message translates to:
  /// **'Final PKs'**
  String get finalPKsText;

  /// No description provided for @finalText.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get finalText;

  /// No description provided for @firestoreDocumentPath.
  ///
  /// In en, this message translates to:
  /// **'Firestore document path'**
  String get firestoreDocumentPath;

  /// No description provided for @formation.
  ///
  /// In en, this message translates to:
  /// **'Formation'**
  String get formation;

  /// No description provided for @fouls.
  ///
  /// In en, this message translates to:
  /// **'Fouls'**
  String get fouls;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @gameDayTweetSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Game day tweet sent successfully! 🎉'**
  String get gameDayTweetSentSuccessfully;

  /// No description provided for @gameStats.
  ///
  /// In en, this message translates to:
  /// **'Game Stats'**
  String get gameStats;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generateImage.
  ///
  /// In en, this message translates to:
  /// **'Generate Image'**
  String get generateImage;

  /// No description provided for @generateLineup.
  ///
  /// In en, this message translates to:
  /// **'Generate Lineup'**
  String get generateLineup;

  /// No description provided for @generateLineupImage.
  ///
  /// In en, this message translates to:
  /// **'Generate Lineup Image'**
  String get generateLineupImage;

  /// No description provided for @generateNewMessage.
  ///
  /// In en, this message translates to:
  /// **'Generate new message'**
  String get generateNewMessage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @goToGame.
  ///
  /// In en, this message translates to:
  /// **'Go to game'**
  String get goToGame;

  /// No description provided for @goalCelebrationPosts.
  ///
  /// In en, this message translates to:
  /// **'Goal celebration posts'**
  String get goalCelebrationPosts;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @hideHighlights.
  ///
  /// In en, this message translates to:
  /// **'Hide Highlights'**
  String get hideHighlights;

  /// No description provided for @highlightDeleted.
  ///
  /// In en, this message translates to:
  /// **'Highlight deleted'**
  String get highlightDeleted;

  /// No description provided for @highlightSaved.
  ///
  /// In en, this message translates to:
  /// **'Highlight saved successfully'**
  String get highlightSaved;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @hintAwardTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g., MVP, All-Star, Top Scorer'**
  String get hintAwardTitle;

  /// No description provided for @hintDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get hintDescriptionOptional;

  /// No description provided for @hintTitleExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Game-Winning Goal'**
  String get hintTitleExample;

  /// No description provided for @hintVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get hintVideoUrl;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get history;

  /// No description provided for @historyVersus.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get historyVersus;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get home;

  /// No description provided for @importSeason.
  ///
  /// In en, this message translates to:
  /// **'Import Season'**
  String get importSeason;

  /// No description provided for @importTeamsPlayersGamesStats.
  ///
  /// In en, this message translates to:
  /// **'Import teams, players, games & stats'**
  String get importTeamsPlayersGamesStats;

  /// No description provided for @importingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Importing database...'**
  String get importingDatabase;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits'**
  String get invalidPin;

  /// No description provided for @labelAwardImage.
  ///
  /// In en, this message translates to:
  /// **'Award Image (optional)'**
  String get labelAwardImage;

  /// No description provided for @labelAwardTitle.
  ///
  /// In en, this message translates to:
  /// **'Award Title *'**
  String get labelAwardTitle;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @labelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get labelDescription;

  /// No description provided for @labelTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get labelTitleRequired;

  /// No description provided for @labelVideoUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Video URL *'**
  String get labelVideoUrlRequired;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @leaders.
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get leaders;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @lineupGeneratorMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Lineup generator is only available on mobile devices'**
  String get lineupGeneratorMobileOnly;

  /// No description provided for @lineupSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lineup shared successfully!'**
  String get lineupSharedSuccessfully;

  /// No description provided for @lineupTweetedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lineup tweeted successfully! 🎉'**
  String get lineupTweetedSuccessfully;

  /// No description provided for @linkURL.
  ///
  /// In en, this message translates to:
  /// **'Link URL'**
  String get linkURL;

  /// No description provided for @liveBannerTapToWatch.
  ///
  /// In en, this message translates to:
  /// **'LIVE — Tap to watch the stream'**
  String get liveBannerTapToWatch;

  /// No description provided for @liveUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Live URL'**
  String get liveUrlLabel;

  /// No description provided for @loadTeam.
  ///
  /// In en, this message translates to:
  /// **'Load Team'**
  String get loadTeam;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingAllSeasons.
  ///
  /// In en, this message translates to:
  /// **'Loading all seasons...'**
  String get loadingAllSeasons;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out? You will need to sign in again to access cloud databases.'**
  String get logOutConfirmation;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @lossAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lossAbbreviation;

  /// No description provided for @matchDate.
  ///
  /// In en, this message translates to:
  /// **'Match Date'**
  String get matchDate;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @mergeAllIntoFirst.
  ///
  /// In en, this message translates to:
  /// **'Merge All into First'**
  String get mergeAllIntoFirst;

  /// No description provided for @mergeComplete.
  ///
  /// In en, this message translates to:
  /// **'Merge Complete'**
  String get mergeComplete;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @multipleCardStyles.
  ///
  /// In en, this message translates to:
  /// **'Multiple card styles'**
  String get multipleCardStyles;

  /// No description provided for @multipleFiles.
  ///
  /// In en, this message translates to:
  /// **'Multiple files:'**
  String get multipleFiles;

  /// No description provided for @newDatabase.
  ///
  /// In en, this message translates to:
  /// **'New Database'**
  String get newDatabase;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @newPlayer.
  ///
  /// In en, this message translates to:
  /// **'New Player'**
  String get newPlayer;

  /// No description provided for @newSeason.
  ///
  /// In en, this message translates to:
  /// **'New Season'**
  String get newSeason;

  /// No description provided for @newTeam.
  ///
  /// In en, this message translates to:
  /// **'New Team'**
  String get newTeam;

  /// No description provided for @nextGamePrefix.
  ///
  /// In en, this message translates to:
  /// **'Next game:'**
  String get nextGamePrefix;

  /// No description provided for @nextGameStayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned for the live link once it starts'**
  String get nextGameStayTuned;

  /// No description provided for @noAdminsYet.
  ///
  /// In en, this message translates to:
  /// **'No admins yet'**
  String get noAdminsYet;

  /// No description provided for @noAwardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No awards available'**
  String get noAwardsAvailable;

  /// No description provided for @noCloudDatabasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cloud databases found'**
  String get noCloudDatabasesFound;

  /// No description provided for @noClubDatabasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cloud databases found'**
  String get noClubDatabasesFound;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @noDatabaseFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'To get started, you\'ll need to create a new database or open an existing one. Would you like to set up your database now?'**
  String get noDatabaseFoundMessage;

  /// No description provided for @noDuplicatesToMerge.
  ///
  /// In en, this message translates to:
  /// **'No duplicates to merge'**
  String get noDuplicatesToMerge;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @noGameAvailableToSetLiveLink.
  ///
  /// In en, this message translates to:
  /// **'No game available to set live link'**
  String get noGameAvailableToSetLiveLink;

  /// No description provided for @noGameAvailableToTweetAbout.
  ///
  /// In en, this message translates to:
  /// **'No game available to tweet about'**
  String get noGameAvailableToTweetAbout;

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No Games Found'**
  String get noGamesFound;

  /// No description provided for @noHighlightsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No highlights available'**
  String get noHighlightsAvailable;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet.'**
  String get noLogsYet;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get noPlayersFound;

  /// No description provided for @noSeasonsFound.
  ///
  /// In en, this message translates to:
  /// **'No Seasons Found'**
  String get noSeasonsFound;

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stats available'**
  String get noStatsAvailable;

  /// No description provided for @noTeamDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No team data available'**
  String get noTeamDataAvailable;

  /// No description provided for @noTeamFound.
  ///
  /// In en, this message translates to:
  /// **'No Team Found'**
  String get noTeamFound;

  /// No description provided for @noTeamSelected.
  ///
  /// In en, this message translates to:
  /// **'No team selected'**
  String get noTeamSelected;

  /// No description provided for @notAnAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Not an Administrator'**
  String get notAnAdministrator;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @offside.
  ///
  /// In en, this message translates to:
  /// **'Offside'**
  String get offside;

  /// No description provided for @openDatabase.
  ///
  /// In en, this message translates to:
  /// **'Open Database'**
  String get openDatabase;

  /// No description provided for @openExistingCloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Open Existing Cloud Database'**
  String get openExistingCloudDatabase;

  /// No description provided for @openFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Open From Backup'**
  String get openFromBackup;

  /// No description provided for @openedDatabase.
  ///
  /// In en, this message translates to:
  /// **'Opened database: {name}'**
  String openedDatabase(Object name);

  /// No description provided for @optionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional details'**
  String get optionalDetails;

  /// No description provided for @optionalExternalLink.
  ///
  /// In en, this message translates to:
  /// **'Optional external link'**
  String get optionalExternalLink;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @pickTeamColors.
  ///
  /// In en, this message translates to:
  /// **'Pick team colors'**
  String get pickTeamColors;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @playerName.
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerName;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player not found'**
  String get playerNotFound;

  /// No description provided for @playerNumber.
  ///
  /// In en, this message translates to:
  /// **'Player Number'**
  String get playerNumber;

  /// No description provided for @playerProfilesProFeature.
  ///
  /// In en, this message translates to:
  /// **'Player Profiles are part of the Pro version. Upgrade to access detailed player statistics and career history.'**
  String get playerProfilesProFeature;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @pleaseAddPlayersFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add players to the season first'**
  String get pleaseAddPlayersFirst;

  /// No description provided for @pleaseCorrectFormErrors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the errors in the form.'**
  String get pleaseCorrectFormErrors;

  /// No description provided for @pleaseCreateOrOpenADatabase.
  ///
  /// In en, this message translates to:
  /// **'Please create or open a database'**
  String get pleaseCreateOrOpenADatabase;

  /// No description provided for @pleaseCreateSeasonFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a season first to generate a lineup'**
  String get pleaseCreateSeasonFirst;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @pleaseSelectAll11Players.
  ///
  /// In en, this message translates to:
  /// **'Please select all 11 players'**
  String get pleaseSelectAll11Players;

  /// No description provided for @postGameResults.
  ///
  /// In en, this message translates to:
  /// **'Post Game Results'**
  String get postGameResults;

  /// No description provided for @postGameStats.
  ///
  /// In en, this message translates to:
  /// **'Post Game Stats'**
  String get postGameStats;

  /// No description provided for @postSeasonStats.
  ///
  /// In en, this message translates to:
  /// **'Post Season Stats'**
  String get postSeasonStats;

  /// No description provided for @preparingShare.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparingShare;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previousLineupRestored.
  ///
  /// In en, this message translates to:
  /// **'Previous lineup restored'**
  String get previousLineupRestored;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @proFeature.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get proFeature;

  /// No description provided for @proSubscriptionFeatures.
  ///
  /// In en, this message translates to:
  /// **'PRO SUBSCRIPTION FEATURES'**
  String get proSubscriptionFeatures;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @recentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent Games'**
  String get recentGames;

  /// No description provided for @recentHighlights.
  ///
  /// In en, this message translates to:
  /// **'Recent highlights'**
  String get recentHighlights;

  /// No description provided for @recordHolders.
  ///
  /// In en, this message translates to:
  /// **'Record Holders'**
  String get recordHolders;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @redCards.
  ///
  /// In en, this message translates to:
  /// **'Red Cards'**
  String get redCards;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get remindMeLater;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @removeFromClub.
  ///
  /// In en, this message translates to:
  /// **'Remove from Club'**
  String get removeFromClub;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get revokeAccess;

  /// No description provided for @rowNumber.
  ///
  /// In en, this message translates to:
  /// **'Row {number}'**
  String rowNumber(Object number);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get saves;

  /// No description provided for @scoringSummary.
  ///
  /// In en, this message translates to:
  /// **'Scoring Summary'**
  String get scoringSummary;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @seasonName.
  ///
  /// In en, this message translates to:
  /// **'Season Name'**
  String get seasonName;

  /// No description provided for @seasonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Season not found'**
  String get seasonNotFound;

  /// No description provided for @seasonStats.
  ///
  /// In en, this message translates to:
  /// **'Season Stats'**
  String get seasonStats;

  /// No description provided for @seasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seasons;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get secondaryColor;

  /// No description provided for @selectACloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Select a Cloud Database'**
  String get selectACloudDatabase;

  /// No description provided for @selectAClub.
  ///
  /// In en, this message translates to:
  /// **'Select a Club'**
  String get selectAClub;

  /// No description provided for @selectADatabase.
  ///
  /// In en, this message translates to:
  /// **'Select a Database'**
  String get selectADatabase;

  /// No description provided for @selectEventType.
  ///
  /// In en, this message translates to:
  /// **'Select Event Type'**
  String get selectEventType;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @selectOpponent.
  ///
  /// In en, this message translates to:
  /// **'Select Opponent'**
  String get selectOpponent;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @selectPlayer.
  ///
  /// In en, this message translates to:
  /// **'Select player'**
  String get selectPlayer;

  /// No description provided for @sendTweet.
  ///
  /// In en, this message translates to:
  /// **'Send Tweet'**
  String get sendTweet;

  /// No description provided for @setGameTime.
  ///
  /// In en, this message translates to:
  /// **'Set Game Time'**
  String get setGameTime;

  /// No description provided for @setLiveLink.
  ///
  /// In en, this message translates to:
  /// **'Set Live Link'**
  String get setLiveLink;

  /// No description provided for @setLiveStreamLink.
  ///
  /// In en, this message translates to:
  /// **'Set Live Stream Link'**
  String get setLiveStreamLink;

  /// No description provided for @setTeamColors.
  ///
  /// In en, this message translates to:
  /// **'Set team colors'**
  String get setTeamColors;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTime;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shareDatabase.
  ///
  /// In en, this message translates to:
  /// **'Share Database'**
  String get shareDatabase;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get shareImage;

  /// No description provided for @shareToSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Share to social media'**
  String get shareToSocialMedia;

  /// No description provided for @sharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully!'**
  String get sharedSuccessfully;

  /// No description provided for @shots.
  ///
  /// In en, this message translates to:
  /// **'Shots'**
  String get shots;

  /// No description provided for @shotsOnGoal.
  ///
  /// In en, this message translates to:
  /// **'Shots on Goal'**
  String get shotsOnGoal;

  /// No description provided for @showHighlights.
  ///
  /// In en, this message translates to:
  /// **'Show Highlights'**
  String get showHighlights;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String signInFailed(Object error);

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequired;

  /// No description provided for @signInToAccessCloudDatabases.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access cloud databases'**
  String get signInToAccessCloudDatabases;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signedInWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with {provider}'**
  String signedInWith(Object provider);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @soccerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Soccer Analytics'**
  String get soccerAnalytics;

  /// No description provided for @startImport.
  ///
  /// In en, this message translates to:
  /// **'Start Import'**
  String get startImport;

  /// No description provided for @systemDefaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefaultLanguage;

  /// No description provided for @systemDefaultTheme.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefaultTheme;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teamAccomplishments.
  ///
  /// In en, this message translates to:
  /// **'Team Accomplishments'**
  String get teamAccomplishments;

  /// No description provided for @teamId.
  ///
  /// In en, this message translates to:
  /// **'Team ID'**
  String get teamId;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// No description provided for @teamShortName.
  ///
  /// In en, this message translates to:
  /// **'Team Short Name'**
  String get teamShortName;

  /// No description provided for @teamStandings.
  ///
  /// In en, this message translates to:
  /// **'Team Standings'**
  String get teamStandings;

  /// No description provided for @teamSummary.
  ///
  /// In en, this message translates to:
  /// **'About the Team'**
  String get teamSummary;

  /// No description provided for @editTeamSummary.
  ///
  /// In en, this message translates to:
  /// **'Edit Team Summary'**
  String get editTeamSummary;

  /// No description provided for @teamSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a brief description of your team...'**
  String get teamSummaryHint;

  /// No description provided for @teamSummarySaved.
  ///
  /// In en, this message translates to:
  /// **'Team summary saved successfully'**
  String get teamSummarySaved;

  /// No description provided for @teamSync.
  ///
  /// In en, this message translates to:
  /// **'TeamSync'**
  String get teamSync;

  /// No description provided for @teamSyncDatabaseViewer.
  ///
  /// In en, this message translates to:
  /// **'TeamSync Database Viewer'**
  String get teamSyncDatabaseViewer;

  /// No description provided for @teamSyncViewer.
  ///
  /// In en, this message translates to:
  /// **'TeamSync Viewer'**
  String get teamSyncViewer;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @themeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get themeClassic;

  /// No description provided for @themeDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDarkMode;

  /// No description provided for @themeElegant.
  ///
  /// In en, this message translates to:
  /// **'Elegant'**
  String get themeElegant;

  /// No description provided for @themeMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get themeMinimal;

  /// No description provided for @themeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get themeNeon;

  /// No description provided for @themeRetro.
  ///
  /// In en, this message translates to:
  /// **'Retro'**
  String get themeRetro;

  /// No description provided for @thisWillMergeFollowingPlayers.
  ///
  /// In en, this message translates to:
  /// **'This will merge the following players:'**
  String get thisWillMergeFollowingPlayers;

  /// No description provided for @tieAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tieAbbreviation;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @titleUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and URL are required'**
  String get titleUrlRequired;

  /// No description provided for @tweetGameDay.
  ///
  /// In en, this message translates to:
  /// **'Tweet Game Day'**
  String get tweetGameDay;

  /// No description provided for @tweetSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tweet sent successfully!'**
  String get tweetSentSuccessfully;

  /// No description provided for @tweetedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tweeted successfully!'**
  String get tweetedSuccessfully;

  /// No description provided for @twitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get twitter;

  /// No description provided for @twitterSettings.
  ///
  /// In en, this message translates to:
  /// **'Twitter Settings'**
  String get twitterSettings;

  /// No description provided for @twitterSettingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Twitter settings saved successfully!'**
  String get twitterSettingsSavedSuccessfully;

  /// No description provided for @unableToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get unableToOpenLink;

  /// No description provided for @unableToOpenLiveLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open live link'**
  String get unableToOpenLiveLink;

  /// No description provided for @unexpectedDatabaseFormat.
  ///
  /// In en, this message translates to:
  /// **'Unexpected database format'**
  String get unexpectedDatabaseFormat;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @addLogo.
  ///
  /// In en, this message translates to:
  /// **'Add Logo'**
  String get addLogo;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// No description provided for @confirmRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this logo?'**
  String get confirmRemoveLogo;

  /// No description provided for @logoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated successfully'**
  String get logoUpdated;

  /// No description provided for @logoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Logo removed successfully'**
  String get logoRemoved;

  /// No description provided for @useDeviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get useDeviceLanguage;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @validateOnly.
  ///
  /// In en, this message translates to:
  /// **'Validate Only'**
  String get validateOnly;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @watchLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchLabel;

  /// No description provided for @welcomeToTeamSync.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TeamSync!'**
  String get welcomeToTeamSync;

  /// No description provided for @winAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get winAbbreviation;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @yellowCards.
  ///
  /// In en, this message translates to:
  /// **'Yellow Cards'**
  String get yellowCards;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get noGamesYet;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'WIN'**
  String get win;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'LOSS'**
  String get loss;

  /// No description provided for @tie.
  ///
  /// In en, this message translates to:
  /// **'TIE'**
  String get tie;

  /// No description provided for @teamPerformance.
  ///
  /// In en, this message translates to:
  /// **'Team Performance'**
  String get teamPerformance;

  /// No description provided for @teamPerformanceSince.
  ///
  /// In en, this message translates to:
  /// **'Team Performance (Since {year})'**
  String teamPerformanceSince(Object year);

  /// No description provided for @addAccomplishment.
  ///
  /// In en, this message translates to:
  /// **'Add Accomplishment'**
  String get addAccomplishment;

  /// No description provided for @editAccomplishment.
  ///
  /// In en, this message translates to:
  /// **'Edit Accomplishment'**
  String get editAccomplishment;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @exampleStateChampions.
  ///
  /// In en, this message translates to:
  /// **'e.g., State Champions'**
  String get exampleStateChampions;

  /// No description provided for @exampleYear.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2023'**
  String get exampleYear;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @tapImageToPrimary.
  ///
  /// In en, this message translates to:
  /// **'Tap an image to make it primary'**
  String get tapImageToPrimary;

  /// No description provided for @selectMultipleImages.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple images at once'**
  String get selectMultipleImages;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @notAuthorizedUploadImages.
  ///
  /// In en, this message translates to:
  /// **'Not authorized to upload images. Please sign in on mobile to add images.'**
  String get notAuthorizedUploadImages;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gameTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Game time set to {time}'**
  String gameTimeSet(Object time);

  /// No description provided for @noTimeSetPrompt.
  ///
  /// In en, this message translates to:
  /// **'This game doesn\'t have a time set (currently 00:00). Would you like to set the game time before tweeting?'**
  String get noTimeSetPrompt;

  /// No description provided for @sortByTeamName.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get sortByTeamName;

  /// No description provided for @sortByMostGames.
  ///
  /// In en, this message translates to:
  /// **'Most Games'**
  String get sortByMostGames;

  /// No description provided for @sortByMostWins.
  ///
  /// In en, this message translates to:
  /// **'Most Wins'**
  String get sortByMostWins;

  /// No description provided for @sortByWinPercentage.
  ///
  /// In en, this message translates to:
  /// **'Win %'**
  String get sortByWinPercentage;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortByRecent;

  /// No description provided for @noMatchupHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No matchup history yet'**
  String get noMatchupHistoryYet;

  /// No description provided for @gamesSingular.
  ///
  /// In en, this message translates to:
  /// **'game'**
  String get gamesSingular;

  /// No description provided for @gamesPlural.
  ///
  /// In en, this message translates to:
  /// **'games'**
  String get gamesPlural;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{game} other{games}} played'**
  String gamesPlayed(num count);

  /// No description provided for @versus.
  ///
  /// In en, this message translates to:
  /// **'vs.'**
  String get versus;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @editSeasonName.
  ///
  /// In en, this message translates to:
  /// **'Edit Season Name'**
  String get editSeasonName;

  /// No description provided for @seasonNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Season name is required'**
  String get seasonNameRequired;

  /// No description provided for @seasonNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Season name updated successfully'**
  String get seasonNameUpdated;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @avgGoalsFor.
  ///
  /// In en, this message translates to:
  /// **'Avg Goals For'**
  String get avgGoalsFor;

  /// No description provided for @avgGoalsAgainst.
  ///
  /// In en, this message translates to:
  /// **'Avg Goals Against'**
  String get avgGoalsAgainst;

  /// No description provided for @biggestWin.
  ///
  /// In en, this message translates to:
  /// **'Biggest Win'**
  String get biggestWin;

  /// No description provided for @biggestLoss.
  ///
  /// In en, this message translates to:
  /// **'Biggest Loss'**
  String get biggestLoss;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @longestWinStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Win Streak'**
  String get longestWinStreak;

  /// No description provided for @recentForm.
  ///
  /// In en, this message translates to:
  /// **'Recent Form (Last 5)'**
  String get recentForm;

  /// No description provided for @cleanSheets.
  ///
  /// In en, this message translates to:
  /// **'Clean Sheets'**
  String get cleanSheets;

  /// No description provided for @goalDifferential.
  ///
  /// In en, this message translates to:
  /// **'Goal Differential'**
  String get goalDifferential;

  /// No description provided for @homeRecord.
  ///
  /// In en, this message translates to:
  /// **'Home Record'**
  String get homeRecord;

  /// No description provided for @awayRecord.
  ///
  /// In en, this message translates to:
  /// **'Away Record'**
  String get awayRecord;

  /// No description provided for @pointsPerGame.
  ///
  /// In en, this message translates to:
  /// **'Points Per Game'**
  String get pointsPerGame;

  /// No description provided for @shootingAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Shooting Accuracy'**
  String get shootingAccuracy;

  /// No description provided for @comebackWins.
  ///
  /// In en, this message translates to:
  /// **'Comeback Wins'**
  String get comebackWins;

  /// No description provided for @lateGoals.
  ///
  /// In en, this message translates to:
  /// **'Late Goals (80+)'**
  String get lateGoals;

  /// No description provided for @cardsPerGame.
  ///
  /// In en, this message translates to:
  /// **'Cards Per Game'**
  String get cardsPerGame;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @scoringEvents.
  ///
  /// In en, this message translates to:
  /// **'Scoring Events'**
  String get scoringEvents;

  /// No description provided for @noScoringEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No scoring events yet'**
  String get noScoringEventsYet;

  /// No description provided for @gameStatistics.
  ///
  /// In en, this message translates to:
  /// **'Game Statistics'**
  String get gameStatistics;

  /// No description provided for @shotsOnTarget.
  ///
  /// In en, this message translates to:
  /// **'Shots on Target'**
  String get shotsOnTarget;

  /// No description provided for @goalAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Goal Analytics'**
  String get goalAnalytics;

  /// No description provided for @totalGoalsScored.
  ///
  /// In en, this message translates to:
  /// **'Total Goals Scored'**
  String get totalGoalsScored;

  /// No description provided for @totalGoalsConceded.
  ///
  /// In en, this message translates to:
  /// **'Total Goals Conceded'**
  String get totalGoalsConceded;

  /// No description provided for @avgGoalsPerGame.
  ///
  /// In en, this message translates to:
  /// **'Avg Goals Per Game'**
  String get avgGoalsPerGame;

  /// No description provided for @streaksRecords.
  ///
  /// In en, this message translates to:
  /// **'Streaks & Records'**
  String get streaksRecords;

  /// No description provided for @longestUnbeatenStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Unbeaten Streak'**
  String get longestUnbeatenStreak;

  /// No description provided for @mostGoalsInGame.
  ///
  /// In en, this message translates to:
  /// **'Most Goals in Game'**
  String get mostGoalsInGame;

  /// No description provided for @biggestVictory.
  ///
  /// In en, this message translates to:
  /// **'Biggest Victory'**
  String get biggestVictory;

  /// No description provided for @homeAwayAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Home vs Away'**
  String get homeAwayAnalysis;

  /// No description provided for @homeWinPercentage.
  ///
  /// In en, this message translates to:
  /// **'Home Win %'**
  String get homeWinPercentage;

  /// No description provided for @awayWinPercentage.
  ///
  /// In en, this message translates to:
  /// **'Away Win %'**
  String get awayWinPercentage;

  /// No description provided for @defensiveStats.
  ///
  /// In en, this message translates to:
  /// **'Defensive Stats'**
  String get defensiveStats;

  /// No description provided for @cleanSheetPercentage.
  ///
  /// In en, this message translates to:
  /// **'Clean Sheet %'**
  String get cleanSheetPercentage;

  /// No description provided for @avgGoalsConceded.
  ///
  /// In en, this message translates to:
  /// **'Avg Goals Conceded'**
  String get avgGoalsConceded;

  /// No description provided for @shutoutsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Shutouts Recorded'**
  String get shutoutsRecorded;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @currentSeason.
  ///
  /// In en, this message translates to:
  /// **'Current Season'**
  String get currentSeason;

  /// No description provided for @lastSeason.
  ///
  /// In en, this message translates to:
  /// **'Last Season'**
  String get lastSeason;

  /// No description provided for @last3Years.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Seasons'**
  String get last3Years;

  /// No description provided for @last5Years.
  ///
  /// In en, this message translates to:
  /// **'Last 5 Seasons'**
  String get last5Years;

  /// No description provided for @last10Years.
  ///
  /// In en, this message translates to:
  /// **'Last 10 Seasons'**
  String get last10Years;

  /// No description provided for @overallStatistics.
  ///
  /// In en, this message translates to:
  /// **'Overall Statistics'**
  String get overallStatistics;

  /// No description provided for @recordSummary.
  ///
  /// In en, this message translates to:
  /// **'Record Summary'**
  String get recordSummary;

  /// No description provided for @totalGames.
  ///
  /// In en, this message translates to:
  /// **'Total Games'**
  String get totalGames;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @ties.
  ///
  /// In en, this message translates to:
  /// **'Ties'**
  String get ties;

  /// No description provided for @winPercentage.
  ///
  /// In en, this message translates to:
  /// **'Win %'**
  String get winPercentage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
