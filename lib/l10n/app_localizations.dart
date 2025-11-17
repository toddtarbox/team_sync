import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TeamSync'**
  String get appTitle;

  /// No description provided for @soccerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Soccer Analytics'**
  String get soccerAnalytics;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @pleaseCreateOrOpenADatabase.
  ///
  /// In en, this message translates to:
  /// **'Please create or open a database'**
  String get pleaseCreateOrOpenADatabase;

  /// No description provided for @noTeamFound.
  ///
  /// In en, this message translates to:
  /// **'No Team Found'**
  String get noTeamFound;

  /// No description provided for @createNewTeamToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Team to start'**
  String get createNewTeamToStart;

  /// No description provided for @noSeasonsFound.
  ///
  /// In en, this message translates to:
  /// **'No Seasons Found'**
  String get noSeasonsFound;

  /// No description provided for @createNewSeasonToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Season to start'**
  String get createNewSeasonToStart;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @areYouSureYouWantToDeleteThisSeason.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Season? All data associated with this Season will be deleted. This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisSeason;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @openExistingCloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Open Existing Cloud Database'**
  String get openExistingCloudDatabase;

  /// No description provided for @openDatabase.
  ///
  /// In en, this message translates to:
  /// **'Open Database'**
  String get openDatabase;

  /// No description provided for @createNewCloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Create New Cloud Database'**
  String get createNewCloudDatabase;

  /// No description provided for @convertToCloud.
  ///
  /// In en, this message translates to:
  /// **'Convert to a Cloud Database'**
  String get convertToCloud;

  /// No description provided for @createNewDatabase.
  ///
  /// In en, this message translates to:
  /// **'Create New Database'**
  String get createNewDatabase;

  /// No description provided for @openFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Open From Backup'**
  String get openFromBackup;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup Current Database to Device'**
  String get backupDatabase;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @createNewSeason.
  ///
  /// In en, this message translates to:
  /// **'Create New Season'**
  String get createNewSeason;

  /// No description provided for @newDatabase.
  ///
  /// In en, this message translates to:
  /// **'New Database'**
  String get newDatabase;

  /// No description provided for @databaseName.
  ///
  /// In en, this message translates to:
  /// **'Database Name'**
  String get databaseName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectACloudDatabase.
  ///
  /// In en, this message translates to:
  /// **'Select a Cloud Database'**
  String get selectACloudDatabase;

  /// No description provided for @noCloudDatabasesFound.
  ///
  /// In en, this message translates to:
  /// **'No cloud databases found'**
  String get noCloudDatabasesFound;

  /// No description provided for @selectADatabase.
  ///
  /// In en, this message translates to:
  /// **'Select a Database'**
  String get selectADatabase;

  /// No description provided for @newTeam.
  ///
  /// In en, this message translates to:
  /// **'New Team'**
  String get newTeam;

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

  /// No description provided for @newSeason.
  ///
  /// In en, this message translates to:
  /// **'New Season'**
  String get newSeason;

  /// No description provided for @seasonName.
  ///
  /// In en, this message translates to:
  /// **'Season Name'**
  String get seasonName;

  /// No description provided for @careerLeaders.
  ///
  /// In en, this message translates to:
  /// **'Career Leaders'**
  String get careerLeaders;

  /// No description provided for @winAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get winAbbreviation;

  /// No description provided for @lossAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get lossAbbreviation;

  /// No description provided for @tieAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tieAbbreviation;

  /// No description provided for @historyVersus.
  ///
  /// In en, this message translates to:
  /// **'History Versus'**
  String get historyVersus;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @newPlayer.
  ///
  /// In en, this message translates to:
  /// **'New Player'**
  String get newPlayer;

  /// No description provided for @editPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Player'**
  String get editPlayer;

  /// No description provided for @playerName.
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerName;

  /// No description provided for @playerNumber.
  ///
  /// In en, this message translates to:
  /// **'Player Number'**
  String get playerNumber;

  /// No description provided for @finalText.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get finalText;

  /// No description provided for @finalOTText.
  ///
  /// In en, this message translates to:
  /// **'Final OT'**
  String get finalOTText;

  /// No description provided for @finalPKsText.
  ///
  /// In en, this message translates to:
  /// **'Final PKs'**
  String get finalPKsText;

  /// No description provided for @areYouSureYouWantToDeleteThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this event? This cannot be undone.'**
  String get areYouSureYouWantToDeleteThisEvent;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No Games Found'**
  String get noGamesFound;

  /// No description provided for @createNewGameToStart.
  ///
  /// In en, this message translates to:
  /// **'Create a new Game to start'**
  String get createNewGameToStart;

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

  /// No description provided for @editGame.
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get editGame;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @createNewOpponent.
  ///
  /// In en, this message translates to:
  /// **'Create New Opponent'**
  String get createNewOpponent;

  /// No description provided for @selectOpponent.
  ///
  /// In en, this message translates to:
  /// **'Select Opponent'**
  String get selectOpponent;

  /// No description provided for @goToGame.
  ///
  /// In en, this message translates to:
  /// **'Go to game'**
  String get goToGame;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @seasonStats.
  ///
  /// In en, this message translates to:
  /// **'Season Stats'**
  String get seasonStats;

  /// No description provided for @leaders.
  ///
  /// In en, this message translates to:
  /// **'Leaders'**
  String get leaders;

  /// No description provided for @twitterSettings.
  ///
  /// In en, this message translates to:
  /// **'Twitter Settings'**
  String get twitterSettings;

  /// No description provided for @connectToTwitter.
  ///
  /// In en, this message translates to:
  /// **'Connect to Twitter'**
  String get connectToTwitter;

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

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get noPlayersFound;

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

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get assists;

  /// No description provided for @offside.
  ///
  /// In en, this message translates to:
  /// **'Offside'**
  String get offside;

  /// No description provided for @fouls.
  ///
  /// In en, this message translates to:
  /// **'Fouls'**
  String get fouls;

  /// No description provided for @corners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get corners;

  /// No description provided for @yellowCards.
  ///
  /// In en, this message translates to:
  /// **'Yellow Cards'**
  String get yellowCards;

  /// No description provided for @redCards.
  ///
  /// In en, this message translates to:
  /// **'Red Cards'**
  String get redCards;

  /// No description provided for @saves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get saves;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @importingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Importing database...'**
  String get importingDatabase;

  /// No description provided for @databaseAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A cloud database with this name already exists.'**
  String get databaseAlreadyExists;

  /// No description provided for @databaseImported.
  ///
  /// In en, this message translates to:
  /// **'Database imported successfully!'**
  String get databaseImported;

  /// No description provided for @databaseImportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Database import still in progress...'**
  String get databaseImportInProgress;

  /// No description provided for @proSubscriptionFeatures.
  ///
  /// In en, this message translates to:
  /// **'PRO SUBSCRIPTION FEATURES'**
  String get proSubscriptionFeatures;

  /// No description provided for @setTeamColors.
  ///
  /// In en, this message translates to:
  /// **'Set team colors'**
  String get setTeamColors;

  /// No description provided for @pickTeamColors.
  ///
  /// In en, this message translates to:
  /// **'Pick team colors'**
  String get pickTeamColors;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get primaryColor;

  /// No description provided for @secondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get secondaryColor;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @shareDatabase.
  ///
  /// In en, this message translates to:
  /// **'Share Database'**
  String get shareDatabase;

  /// No description provided for @career.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get career;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @bestSeason.
  ///
  /// In en, this message translates to:
  /// **'Best Season'**
  String get bestSeason;

  /// No description provided for @bestGame.
  ///
  /// In en, this message translates to:
  /// **'Best Game'**
  String get bestGame;

  /// No description provided for @welcomeToTeamSync.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TeamSync!'**
  String get welcomeToTeamSync;

  /// No description provided for @noDatabaseFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'To get started, you\'ll need to create a new database or open an existing one. Would you like to set up your database now?'**
  String get noDatabaseFoundMessage;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get remindMeLater;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @proFeature.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get proFeature;

  /// No description provided for @playerProfilesProFeature.
  ///
  /// In en, this message translates to:
  /// **'Player Profiles are part of the Pro version. Upgrade to access detailed player statistics and career history.'**
  String get playerProfilesProFeature;

  /// No description provided for @liveBannerTapToWatch.
  ///
  /// In en, this message translates to:
  /// **'LIVE — Tap to watch the stream'**
  String get liveBannerTapToWatch;

  /// No description provided for @unableToOpenLiveLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open live link'**
  String get unableToOpenLiveLink;

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

  /// No description provided for @setLiveLink.
  ///
  /// In en, this message translates to:
  /// **'Set Live Link'**
  String get setLiveLink;

  /// No description provided for @liveUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Live URL'**
  String get liveUrlLabel;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// Label prefix for numbered video buttons, e.g. "Video 1"
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// Label for a single watch/play button
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchLabel;

  /// Tooltip text to hide highlights panel
  ///
  /// In en, this message translates to:
  /// **'Hide Highlights'**
  String get hideHighlights;

  /// Tooltip text to show highlights panel
  ///
  /// In en, this message translates to:
  /// **'Show Highlights'**
  String get showHighlights;

  /// Error message when player stats load fails
  ///
  /// In en, this message translates to:
  /// **'Error loading player stats: {error}\n\nStack trace: {stack}'**
  String errorLoadingPlayerStats(Object error, Object stack);

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stats available'**
  String get noStatsAvailable;

  /// No description provided for @careerStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Stats'**
  String get careerStatsTitle;

  /// Header for the highlights section
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// Tooltip/title for adding a highlight
  ///
  /// In en, this message translates to:
  /// **'Add Highlight'**
  String get addHighlight;

  /// No description provided for @noHighlightsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No highlights available'**
  String get noHighlightsAvailable;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editHighlight.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlight'**
  String get editHighlight;

  /// No description provided for @addHighlightDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Highlight'**
  String get addHighlightDialogTitle;

  /// No description provided for @labelTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get labelTitleRequired;

  /// No description provided for @hintTitleExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Game-Winning Goal'**
  String get hintTitleExample;

  /// No description provided for @labelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get labelDescription;

  /// No description provided for @hintDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get hintDescriptionOptional;

  /// No description provided for @labelVideoUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Video URL *'**
  String get labelVideoUrlRequired;

  /// No description provided for @hintVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get hintVideoUrl;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @titleUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and URL are required'**
  String get titleUrlRequired;

  /// Snackbar text when a URL can't be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open URL: {url}'**
  String couldNotOpenUrl(Object url);

  /// No description provided for @highlightSaved.
  ///
  /// In en, this message translates to:
  /// **'Highlight saved successfully'**
  String get highlightSaved;

  /// No description provided for @errorSavingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Error saving highlight: {error}'**
  String errorSavingHighlight(Object error);

  /// No description provided for @deleteHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Highlight'**
  String get deleteHighlightTitle;

  /// No description provided for @deleteHighlightConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteHighlightConfirm(Object title);

  /// No description provided for @highlightDeleted.
  ///
  /// In en, this message translates to:
  /// **'Highlight deleted'**
  String get highlightDeleted;

  /// No description provided for @errorDeletingHighlight.
  ///
  /// In en, this message translates to:
  /// **'Error deleting highlight: {error}'**
  String errorDeletingHighlight(Object error);

  /// Error when highlights fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading highlights: {error}'**
  String errorLoadingHighlights(Object error);

  /// Header for recent highlights on the team home page
  ///
  /// In en, this message translates to:
  /// **'Recent highlights'**
  String get recentHighlights;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
