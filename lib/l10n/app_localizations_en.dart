// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get email => 'Email';

  @override
  String get description => 'Description';

  @override
  String accessGrantedTo(Object email) {
    return 'Access granted to $email';
  }

  @override
  String get accomplishmentDeleted => 'Accomplishment deleted';

  @override
  String get accomplishmentsReordered => 'Accomplishments reordered';

  @override
  String get account => 'Account';

  @override
  String get actionPhoto => 'Action Photo';

  @override
  String get actionPhotoCards => 'Action photo cards';

  @override
  String get add => 'Add';

  @override
  String get addAssistQuestion => 'Add Assist?';

  @override
  String get addAward => 'Add Award';

  @override
  String get addAwardDialogTitle => 'Add Award';

  @override
  String get addButton => 'Add';

  @override
  String get addHighlight => 'Add Highlight';

  @override
  String get addHighlightDialogTitle => 'Add Highlight';

  @override
  String get addLink => 'Add Link';

  @override
  String get adminAddedSuccessfully => 'Admin added successfully';

  @override
  String get adminRemovedSuccessfully => 'Admin removed successfully';

  @override
  String get advanceGame => 'Advance Game';

  @override
  String get allowPlayerEditProfile =>
      'Allow player to edit their profile on web';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Appearance';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Are you sure you want to delete this event? This cannot be undone.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Are you sure you want to delete this Game? All data associated with this Game will be deleted. This cannot be undone.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Are you sure you want to delete this Player? All data associated with this Player will be deleted. This cannot be undone.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Are you sure you want to delete this Season? All data associated with this Season will be deleted. This cannot be undone.';

  @override
  String get assistedBy => 'Assisted by';

  @override
  String get assists => 'Assists';

  @override
  String get automaticTheme => 'Automatic Theme';

  @override
  String get automaticThemeSwitchDescription =>
      'Automatically switch theme based on the time of day';

  @override
  String get awardDeleted => 'Award deleted';

  @override
  String get awardSaved => 'Award saved successfully';

  @override
  String get awards => 'Awards';

  @override
  String get away => 'AWAY';

  @override
  String get backupDatabase => 'Backup Current Database to Device';

  @override
  String get bestGame => 'Best Game';

  @override
  String get bestSeason => 'Best Season';

  @override
  String get calculating => 'Calculating...';

  @override
  String get camera => 'Camera';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get career => 'Career';

  @override
  String get careerLeaders => 'Career Leaders';

  @override
  String get careerStatsTitle => 'Career Stats';

  @override
  String get changeImage => 'Change Image';

  @override
  String get changeTeamColors => 'Change Team Colors';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get close => 'Close';

  @override
  String get closeSidebar => 'Close sidebar';

  @override
  String get composeTweet => 'Compose Tweet';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get connectToTwitter => 'Connect to Twitter';

  @override
  String get continueButton => 'Continue';

  @override
  String get continueText => 'Continue';

  @override
  String get continueWithoutSigningIn => 'Continue without signing in';

  @override
  String get convertToCloud => 'Convert to a Cloud Database';

  @override
  String get corners => 'Corners';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Could not open URL: $url';
  }

  @override
  String get create => 'Create';

  @override
  String get createAnyway => 'Create Anyway';

  @override
  String get createNewCloudDatabase => 'Create New Cloud Database';

  @override
  String get createNewDatabase => 'Create New Database';

  @override
  String get createNewGameToStart => 'Create a new Game to start';

  @override
  String get createNewOpponent => 'Create New Opponent';

  @override
  String get createNewSeason => 'Create New Season';

  @override
  String get createNewSeasonToStart => 'Create a new Season to start';

  @override
  String get createNewTeam => 'Create New Team';

  @override
  String get createNewTeamToStart => 'Create a new Team to start';

  @override
  String get createTeam => 'Create Team';

  @override
  String get creator => 'Creator';

  @override
  String get currently => 'Currently';

  @override
  String get dataImport => 'Data Import';

  @override
  String get databaseAlreadyExists =>
      'A cloud database with this name already exists.';

  @override
  String get databaseImportInProgress => 'Database import still in progress...';

  @override
  String get databaseImported => 'Database imported successfully!';

  @override
  String get databaseName => 'Database Name';

  @override
  String get databaseNotFound => 'Database not found';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Debug: Firestore → Realtime Migration';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccomplishment => 'Delete Accomplishment';

  @override
  String get deleteAccomplishmentConfirmation =>
      'Are you sure you want to delete this accomplishment?';

  @override
  String deleteAwardConfirm(Object title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteAwardTitle => 'Delete Award';

  @override
  String deleteHighlightConfirm(Object title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get deleteHighlightTitle => 'Delete Highlight';

  @override
  String get displayOrder => 'Display Order';

  @override
  String get downloadErrorReport => 'Download Error Report';

  @override
  String get downloadTemplate => 'Download Template';

  @override
  String get duplicatePlayerName => 'Duplicate Player Name';

  @override
  String durationSeconds(Object seconds) {
    return 'Duration: $seconds seconds';
  }

  @override
  String get edit => 'Edit';

  @override
  String get editAward => 'Edit Award';

  @override
  String get editGame => 'Edit Game';

  @override
  String get editHighlight => 'Edit Highlight';

  @override
  String get editPlayer => 'Edit Player';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get endGame => 'End Game';

  @override
  String get endOfGame => 'End of Game';

  @override
  String get endOfRegulation => 'End of Regulation';

  @override
  String get enterEmailToAddAdmin => 'Enter email to add as admin';

  @override
  String get enterFourDigitPin => 'Enter 4-digit PIN';

  @override
  String get enterPinToEdit => 'Enter PIN to Edit Profile';

  @override
  String get enterTeamIdPrompt => 'Enter a 6-digit Team ID to view stats:';

  @override
  String get entityType => 'Entity Type';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Error deleting accomplishment: $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Error deleting award: $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Error deleting highlight: $error';
  }

  @override
  String get errorDuringShare => 'Error during share, please try again';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Error generating lineup: $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Error loading access list: $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Error loading awards: $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Error loading credentials: $error';
  }

  @override
  String get errorLoadingDatabase => 'Error loading database.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Error loading duplicates: $error';
  }

  @override
  String get errorLoadingEvents => 'Error loading events';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Error loading highlights: $error';
  }

  @override
  String get errorLoadingHistory => 'Error loading history';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Error loading player stats: $error\n\nStack trace: $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Error loading shared databases: $error';
  }

  @override
  String get errorLoadingStats => 'Error loading stats';

  @override
  String errorLoggingOut(Object error) {
    return 'Error logging out: $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Error opening link: $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Error reordering: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Error saving: $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Error saving award: $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Error saving highlight: $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Error saving settings: $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Error sending tweet: $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Error sharing image: $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Error sharing to Twitter: $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Error updating game time: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Error updating profile: $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Error uploading images: $error';
  }

  @override
  String get exitEditMode => 'Exit Edit Mode';

  @override
  String get failedToGrantAccess =>
      'Failed to grant access. User may not exist.';

  @override
  String get failedToOpenDatabase => 'Failed to open database';

  @override
  String get failedToSendTweet => 'Failed to send tweet. Please try again.';

  @override
  String get finalOT => 'Final OT';

  @override
  String get finalOTText => 'Final OT';

  @override
  String get finalPKs => 'Final PKs';

  @override
  String get finalPKsText => 'Final PKs';

  @override
  String get finalText => 'Final';

  @override
  String get firestoreDocumentPath => 'Firestore document path';

  @override
  String get formation => 'Formation';

  @override
  String get fouls => 'Fouls';

  @override
  String get gallery => 'Gallery';

  @override
  String get game => 'Game';

  @override
  String get gameDayTweetSentSuccessfully =>
      'Game day tweet sent successfully! 🎉';

  @override
  String get gameStats => 'Game Stats';

  @override
  String get generate => 'Generate';

  @override
  String get generateImage => 'Generate Image';

  @override
  String get generateLineup => 'Generate Lineup';

  @override
  String get generateLineupImage => 'Generate Lineup Image';

  @override
  String get generateNewMessage => 'Generate new message';

  @override
  String get getStarted => 'Get Started';

  @override
  String get goBack => 'Go Back';

  @override
  String get goPro => 'Go Pro';

  @override
  String get goToGame => 'Go to game';

  @override
  String get goalCelebrationPosts => 'Goal celebration posts';

  @override
  String get goals => 'Goals';

  @override
  String get gotIt => 'Got it';

  @override
  String get hideHighlights => 'Hide Highlights';

  @override
  String get highlightDeleted => 'Highlight deleted';

  @override
  String get highlightSaved => 'Highlight saved successfully';

  @override
  String get highlights => 'Highlights';

  @override
  String get hintAwardTitle => 'e.g., MVP, All-Star, Top Scorer';

  @override
  String get hintDescriptionOptional => 'Optional description';

  @override
  String get hintTitleExample => 'e.g., Game-Winning Goal';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Analytics';

  @override
  String get historyVersus => 'Analytics';

  @override
  String get home => 'HOME';

  @override
  String get importSeason => 'Import Season';

  @override
  String get importTeamsPlayersGamesStats =>
      'Import teams, players, games & stats';

  @override
  String get importingDatabase => 'Importing database...';

  @override
  String get invalidPin => 'PIN must be 4 digits';

  @override
  String get labelAwardImage => 'Award Image (optional)';

  @override
  String get labelAwardTitle => 'Award Title *';

  @override
  String get labelDate => 'Date';

  @override
  String get labelDescription => 'Description';

  @override
  String get labelTitleRequired => 'Title *';

  @override
  String get labelVideoUrlRequired => 'Video URL *';

  @override
  String get language => 'Language';

  @override
  String get leaders => 'Leaders';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get lineupGeneratorMobileOnly =>
      'Lineup generator is only available on mobile devices';

  @override
  String get lineupSharedSuccessfully => 'Lineup shared successfully!';

  @override
  String get lineupTweetedSuccessfully => 'Lineup tweeted successfully! 🎉';

  @override
  String get linkURL => 'Link URL';

  @override
  String get liveBannerTapToWatch => 'LIVE — Tap to watch the stream';

  @override
  String get liveUrlLabel => 'Live URL';

  @override
  String get loadTeam => 'Load Team';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingAllSeasons => 'Loading all seasons...';

  @override
  String get logOut => 'Log Out';

  @override
  String get logOutConfirmation =>
      'Are you sure you want to log out? You will need to sign in again to access cloud databases.';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get logs => 'Logs';

  @override
  String get lossAbbreviation => 'L';

  @override
  String get matchDate => 'Match Date';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get mergeAllIntoFirst => 'Merge All into First';

  @override
  String get mergeComplete => 'Merge Complete';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthDec => 'Dec';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthMay => 'May';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthSep => 'Sep';

  @override
  String get multipleCardStyles => 'Multiple card styles';

  @override
  String get multipleFiles => 'Multiple files:';

  @override
  String get newDatabase => 'New Database';

  @override
  String get newEvent => 'New Event';

  @override
  String get newPlayer => 'New Player';

  @override
  String get newSeason => 'New Season';

  @override
  String get newTeam => 'New Team';

  @override
  String get nextGamePrefix => 'Next game:';

  @override
  String get nextGameStayTuned => 'Stay tuned for the live link once it starts';

  @override
  String get noAdminsYet => 'No admins yet';

  @override
  String get noAwardsAvailable => 'No awards available';

  @override
  String get noCloudDatabasesFound => 'No cloud databases found';

  @override
  String get noData => 'No data';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get noDatabaseFoundMessage =>
      'To get started, you\'ll need to create a new database or open an existing one. Would you like to set up your database now?';

  @override
  String get noDuplicatesToMerge => 'No duplicates to merge';

  @override
  String get noEmail => 'No email';

  @override
  String get noGameAvailableToSetLiveLink =>
      'No game available to set live link';

  @override
  String get noGameAvailableToTweetAbout => 'No game available to tweet about';

  @override
  String get noGamesFound => 'No Games Found';

  @override
  String get noHighlightsAvailable => 'No highlights available';

  @override
  String get noLogsYet => 'No logs yet.';

  @override
  String get noPlayersFound => 'No players found';

  @override
  String get noSeasonsFound => 'No Seasons Found';

  @override
  String get noStatsAvailable => 'No stats available';

  @override
  String get noTeamDataAvailable => 'No team data available';

  @override
  String get noTeamFound => 'No Team Found';

  @override
  String get noTeamSelected => 'No team selected';

  @override
  String get notAnAdministrator => 'Not an Administrator';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get offside => 'Offside';

  @override
  String get openDatabase => 'Open Database';

  @override
  String get openExistingDatabase => 'Open Existing Database';

  @override
  String get openExistingCloudDatabase => 'Open Existing Cloud Database';

  @override
  String get openFromBackup => 'Open From Backup';

  @override
  String openedDatabase(Object name) {
    return 'Opened database: $name';
  }

  @override
  String get optionalDetails => 'Optional details';

  @override
  String get optionalExternalLink => 'Optional external link';

  @override
  String get other => 'Other';

  @override
  String get overall => 'Overall';

  @override
  String get overview => 'Overview';

  @override
  String get password => 'Password';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get pickTeamColors => 'Pick team colors';

  @override
  String get pinLabel => 'PIN';

  @override
  String get playerName => 'Player Name';

  @override
  String get playerNotFound => 'Player not found';

  @override
  String get playerNumber => 'Player Number';

  @override
  String get playerProfilesProFeature =>
      'Player Profiles are part of the Pro version. Upgrade to access detailed player statistics and career history.';

  @override
  String get players => 'Players';

  @override
  String get pleaseAddPlayersFirst => 'Please add players to the season first';

  @override
  String get pleaseCorrectFormErrors =>
      'Please correct the errors in the form.';

  @override
  String get pleaseCreateOrOpenADatabase => 'Please create or open a database';

  @override
  String get pleaseCreateSeasonFirst =>
      'Please create a season first to generate a lineup';

  @override
  String get pleaseEnterEmailAddress => 'Please enter an email address';

  @override
  String get pleaseSelectAll11Players => 'Please select all 11 players';

  @override
  String get postGameResults => 'Post Game Results';

  @override
  String get postGameStats => 'Post Game Stats';

  @override
  String get postSeasonStats => 'Post Season Stats';

  @override
  String get preparingShare => 'Preparing...';

  @override
  String get preview => 'Preview';

  @override
  String get previousLineupRestored => 'Previous lineup restored';

  @override
  String get primaryColor => 'Primary color';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Pro Feature';

  @override
  String get proSubscriptionFeatures => 'PRO SUBSCRIPTION FEATURES';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get recentGames => 'Recent Games';

  @override
  String get recentHighlights => 'Recent highlights';

  @override
  String get recordHolders => 'Record Holders';

  @override
  String get records => 'Records';

  @override
  String get redCards => 'Red Cards';

  @override
  String get remindMeLater => 'Remind Me Later';

  @override
  String get remove => 'Remove';

  @override
  String get removeButton => 'Remove';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get retry => 'Retry';

  @override
  String get revokeAccess => 'Revoke access';

  @override
  String rowNumber(Object number) {
    return 'Row $number';
  }

  @override
  String get save => 'Save';

  @override
  String get saves => 'Saves';

  @override
  String get scoringSummary => 'Scoring Summary';

  @override
  String get season => 'Season';

  @override
  String get seasonName => 'Season Name';

  @override
  String get seasonNotFound => 'Season not found';

  @override
  String get seasonStats => 'Season Stats';

  @override
  String get seasons => 'Seasons';

  @override
  String get secondaryColor => 'Secondary color';

  @override
  String get selectACloudDatabase => 'Select a Cloud Database';

  @override
  String get selectADatabase => 'Select a Database';

  @override
  String get selectEventType => 'Select Event Type';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get selectOpponent => 'Select Opponent';

  @override
  String get selectPeriod => 'Select Period';

  @override
  String get selectPlayer => 'Select player';

  @override
  String get sendTweet => 'Send Tweet';

  @override
  String get setGameTime => 'Set Game Time';

  @override
  String get setLiveLink => 'Set Live Link';

  @override
  String get setLiveStreamLink => 'Set Live Stream Link';

  @override
  String get setTeamColors => 'Set team colors';

  @override
  String get setTime => 'Set Time';

  @override
  String get settings => 'Settings';

  @override
  String get shareDatabase => 'Share Database';

  @override
  String get shareImage => 'Share Image';

  @override
  String get shareToSocialMedia => 'Share to social media';

  @override
  String get sharedSuccessfully => 'Shared successfully!';

  @override
  String get shots => 'Shots';

  @override
  String get shotsOnGoal => 'Shots on Goal';

  @override
  String get showHighlights => 'Show Highlights';

  @override
  String get signIn => 'Sign In';

  @override
  String signInFailed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get signInRequired => 'Sign In Required';

  @override
  String get signInToAccessCloudDatabases =>
      'Sign in to access cloud databases';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signOut => 'Sign Out';

  @override
  String signedInWith(Object provider) {
    return 'Signed in with $provider';
  }

  @override
  String get skip => 'Skip';

  @override
  String get soccerAnalytics => 'Soccer Analytics';

  @override
  String get startImport => 'Start Import';

  @override
  String get systemDefaultLanguage => 'System Default';

  @override
  String get systemDefaultTheme => 'System Default';

  @override
  String get team => 'Team';

  @override
  String get teamAccomplishments => 'Team Accomplishments';

  @override
  String get teamId => 'Team ID';

  @override
  String get teamName => 'Team Name';

  @override
  String get teamShortName => 'Team Short Name';

  @override
  String get teamStandings => 'Team Standings';

  @override
  String get teamSummary => 'About the Team';

  @override
  String get editTeamSummary => 'Edit Team Summary';

  @override
  String get teamSummaryHint => 'Enter a brief description of your team...';

  @override
  String get teamSummarySaved => 'Team summary saved successfully';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer => 'TeamSync Database Viewer';

  @override
  String get teamSyncViewer => 'TeamSync Viewer';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get themeClassic => 'Classic';

  @override
  String get themeDarkMode => 'Dark Mode';

  @override
  String get themeElegant => 'Elegant';

  @override
  String get themeMinimal => 'Minimal';

  @override
  String get themeNeon => 'Neon';

  @override
  String get themeRetro => 'Retro';

  @override
  String get thisWillMergeFollowingPlayers =>
      'This will merge the following players:';

  @override
  String get tieAbbreviation => 'T';

  @override
  String get time => 'Time';

  @override
  String get titleUrlRequired => 'Title and URL are required';

  @override
  String get tweetGameDay => 'Tweet Game Day';

  @override
  String get tweetSentSuccessfully => 'Tweet sent successfully!';

  @override
  String get tweetedSuccessfully => 'Tweeted successfully!';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Twitter Settings';

  @override
  String get twitterSettingsSavedSuccessfully =>
      'Twitter settings saved successfully!';

  @override
  String get unableToOpenLink => 'Unable to open link';

  @override
  String get unableToOpenLiveLink => 'Unable to open live link';

  @override
  String get unexpectedDatabaseFormat => 'Unexpected database format';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get update => 'Update';

  @override
  String get updateButton => 'Update';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get addLogo => 'Add Logo';

  @override
  String get changeLogo => 'Change Logo';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get confirmRemoveLogo => 'Are you sure you want to remove this logo?';

  @override
  String get logoUpdated => 'Logo updated successfully';

  @override
  String get logoRemoved => 'Logo removed successfully';

  @override
  String get useDeviceLanguage => 'Use device language';

  @override
  String get userEmail => 'User Email';

  @override
  String get validateOnly => 'Validate Only';

  @override
  String get videoLabel => 'Video';

  @override
  String get viewMore => 'View More';

  @override
  String get watchLabel => 'Watch';

  @override
  String get welcomeToTeamSync => 'Welcome to TeamSync!';

  @override
  String get winAbbreviation => 'W';

  @override
  String get year => 'Year';

  @override
  String get yellowCards => 'Yellow Cards';

  @override
  String get noGamesYet => 'No games yet';

  @override
  String get live => 'LIVE';

  @override
  String get win => 'WIN';

  @override
  String get loss => 'LOSS';

  @override
  String get tie => 'TIE';

  @override
  String get teamPerformance => 'Team Performance';

  @override
  String teamPerformanceSince(Object year) {
    return 'Team Performance (Since $year)';
  }

  @override
  String get addAccomplishment => 'Add Accomplishment';

  @override
  String get editAccomplishment => 'Edit Accomplishment';

  @override
  String get titleRequired => 'Title *';

  @override
  String get titleIsRequired => 'Title is required';

  @override
  String get exampleStateChampions => 'e.g., State Champions';

  @override
  String get exampleYear => 'e.g., 2023';

  @override
  String get saving => 'Saving...';

  @override
  String get since => 'Since';

  @override
  String get images => 'Images';

  @override
  String get tapImageToPrimary => 'Tap an image to make it primary';

  @override
  String get selectMultipleImages => 'You can select multiple images at once';

  @override
  String get primary => 'Primary';

  @override
  String get notAuthorizedUploadImages =>
      'Not authorized to upload images. Please sign in on mobile to add images.';

  @override
  String get games => 'Games';

  @override
  String gameTimeSet(Object time) {
    return 'Game time set to $time';
  }

  @override
  String get noTimeSetPrompt =>
      'This game doesn\'t have a time set (currently 00:00). Would you like to set the game time before tweeting?';

  @override
  String get sortByTeamName => 'Team Name';

  @override
  String get sortByMostGames => 'Most Games';

  @override
  String get sortByMostWins => 'Most Wins';

  @override
  String get sortByWinPercentage => 'Win %';

  @override
  String get sortByRecent => 'Recent';

  @override
  String get noMatchupHistoryYet => 'No matchup history yet';

  @override
  String get gamesSingular => 'game';

  @override
  String get gamesPlural => 'games';

  @override
  String gamesPlayed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'games',
      one: 'game',
    );
    return '$count $_temp0 played';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Unknown';

  @override
  String get editSeasonName => 'Edit Season Name';

  @override
  String get seasonNameRequired => 'Season name is required';

  @override
  String get seasonNameUpdated => 'Season name updated successfully';

  @override
  String get analytics => 'Analytics';

  @override
  String get avgGoalsFor => 'Avg Goals For';

  @override
  String get avgGoalsAgainst => 'Avg Goals Against';

  @override
  String get biggestWin => 'Biggest Win';

  @override
  String get biggestLoss => 'Biggest Loss';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get longestWinStreak => 'Longest Win Streak';

  @override
  String get recentForm => 'Recent Form (Last 5)';

  @override
  String get cleanSheets => 'Clean Sheets';

  @override
  String get goalDifferential => 'Goal Differential';

  @override
  String get homeRecord => 'Home Record';

  @override
  String get awayRecord => 'Away Record';

  @override
  String get pointsPerGame => 'Points Per Game';

  @override
  String get shootingAccuracy => 'Shooting Accuracy';

  @override
  String get comebackWins => 'Comeback Wins';

  @override
  String get lateGoals => 'Late Goals (80+)';

  @override
  String get cardsPerGame => 'Cards Per Game';

  @override
  String get statistics => 'Statistics';

  @override
  String get scoringEvents => 'Scoring Events';

  @override
  String get noScoringEventsYet => 'No scoring events yet';

  @override
  String get gameStatistics => 'Game Statistics';

  @override
  String get shotsOnTarget => 'Shots on Target';

  @override
  String get goalAnalytics => 'Goal Analytics';

  @override
  String get totalGoalsScored => 'Total Goals Scored';

  @override
  String get totalGoalsConceded => 'Total Goals Conceded';

  @override
  String get avgGoalsPerGame => 'Avg Goals Per Game';

  @override
  String get streaksRecords => 'Streaks & Records';

  @override
  String get longestUnbeatenStreak => 'Longest Unbeaten Streak';

  @override
  String get mostGoalsInGame => 'Most Goals in Game';

  @override
  String get biggestVictory => 'Biggest Victory';

  @override
  String get homeAwayAnalysis => 'Home vs Away';

  @override
  String get homeWinPercentage => 'Home Win %';

  @override
  String get awayWinPercentage => 'Away Win %';

  @override
  String get defensiveStats => 'Defensive Stats';

  @override
  String get cleanSheetPercentage => 'Clean Sheet %';

  @override
  String get avgGoalsConceded => 'Avg Goals Conceded';

  @override
  String get shutoutsRecorded => 'Shutouts Recorded';

  @override
  String get allTime => 'All Time';

  @override
  String get currentSeason => 'Current Season';

  @override
  String get lastSeason => 'Last Season';

  @override
  String get last3Years => 'Last 3 Seasons';

  @override
  String get last5Years => 'Last 5 Seasons';

  @override
  String get last10Years => 'Last 10 Seasons';

  @override
  String get overallStatistics => 'Overall Statistics';

  @override
  String get recordSummary => 'Record Summary';

  @override
  String get totalGames => 'Total Games';

  @override
  String get wins => 'Wins';

  @override
  String get losses => 'Losses';

  @override
  String get ties => 'Ties';

  @override
  String get winPercentage => 'Win %';

  @override
  String get playerProfileQRCode => 'Player Profile QR Code';

  @override
  String get scanQRCodeToViewProfile =>
      'Scan QR code to view this player\'s profile';

  @override
  String get tapToEnlarge => 'Tap to enlarge';

  @override
  String playerProfileLink(Object playerName) {
    return 'Player Profile: $playerName';
  }

  @override
  String get errorSharingLink => 'Error sharing link';

  @override
  String get share => 'Share';

  @override
  String get sending => 'Sending...';

  @override
  String get twitterNotConfigured =>
      'Twitter is not configured. Please configure Twitter in Settings.';

  @override
  String get opponents => 'Opponents';

  @override
  String get addGame => 'Add Game';

  @override
  String get opponent => 'Opponent';

  @override
  String get date => 'Date';

  @override
  String get timeOptional => 'Time (optional)';
}
