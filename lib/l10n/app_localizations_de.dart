// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get email => 'E-Mail';

  @override
  String get description => 'Beschreibung';

  @override
  String accessGrantedTo(Object email) {
    return 'Zugriff gewährt für $email';
  }

  @override
  String get accomplishmentDeleted => 'Erfolg gelöscht';

  @override
  String get accomplishmentsReordered => 'Erfolge neu geordnet';

  @override
  String get account => 'Konto';

  @override
  String get actionPhoto => 'Aktionsfoto';

  @override
  String get actionPhotoCards => 'Aktionsfotokarten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addAssistQuestion => 'Vorlage hinzufügen?';

  @override
  String get addAward => 'Auszeichnung hinzufügen';

  @override
  String get addAwardDialogTitle => 'Auszeichnung hinzufügen';

  @override
  String get addButton => 'Hinzufügen';

  @override
  String get addHighlight => 'Highlight hinzufügen';

  @override
  String get addHighlightDialogTitle => 'Highlight hinzufügen';

  @override
  String get addLink => 'Link hinzufügen';

  @override
  String get adminAddedSuccessfully => 'Administrator erfolgreich hinzugefügt';

  @override
  String get adminRemovedSuccessfully => 'Administrator erfolgreich entfernt';

  @override
  String get advanceGame => 'Spiel fortsetzen';

  @override
  String get allowPlayerEditProfile =>
      'Spieler erlauben, ihr Profil im Web zu bearbeiten';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Möchten Sie dieses Ereignis wirklich löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Möchten Sie dieses Spiel wirklich löschen? Alle mit diesem Spiel verbundenen Daten werden gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Möchten Sie diesen Spieler wirklich löschen? Alle mit diesem Spieler verbundenen Daten werden gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Möchten Sie diese Saison wirklich löschen? Alle mit dieser Saison verbundenen Daten werden gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get assistedBy => 'Vorlage von';

  @override
  String get assists => 'Vorlagen';

  @override
  String get automaticTheme => 'Automatisches Design';

  @override
  String get automaticThemeSwitchDescription =>
      'Design automatisch je nach Tageszeit wechseln';

  @override
  String get awardDeleted => 'Auszeichnung gelöscht';

  @override
  String get awardSaved => 'Auszeichnung erfolgreich gespeichert';

  @override
  String get awards => 'Auszeichnungen';

  @override
  String get away => 'AUSWÄRTS';

  @override
  String get backupDatabase => 'Aktuelle Datenbank auf Gerät sichern';

  @override
  String get bestGame => 'Bestes Spiel';

  @override
  String get bestSeason => 'Beste Saison';

  @override
  String get calculating => 'Wird berechnet...';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get career => 'Karriere';

  @override
  String get careerLeaders => 'Karriere-Anführer';

  @override
  String get careerStatsTitle => 'Karrierestatistiken';

  @override
  String get changeImage => 'Bild ändern';

  @override
  String get changeTeamColors => 'Teamfarben ändern';

  @override
  String get clearLogs => 'Protokolle löschen';

  @override
  String get close => 'Schließen';

  @override
  String get closeSidebar => 'Seitenleiste schließen';

  @override
  String get composeTweet => 'Tweet verfassen';

  @override
  String get confirmDelete => 'Löschen bestätigen';

  @override
  String get connectToTwitter => 'Mit Twitter verbinden';

  @override
  String get continueButton => 'Weiter';

  @override
  String get continueText => 'Weiter';

  @override
  String get continueWithoutSigningIn => 'Ohne Anmeldung fortfahren';

  @override
  String get convertToCloud => 'In eine Cloud-Datenbank konvertieren';

  @override
  String get corners => 'Ecken';

  @override
  String couldNotOpenUrl(Object url) {
    return 'URL konnte nicht geöffnet werden: $url';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get createAnyway => 'Trotzdem erstellen';

  @override
  String get createNewCloudDatabase => 'Neue Cloud-Datenbank erstellen';

  @override
  String get createNewDatabase => 'Neue Datenbank erstellen';

  @override
  String get createNewGameToStart =>
      'Erstellen Sie ein neues Spiel, um zu beginnen';

  @override
  String get createNewOpponent => 'Neuen Gegner erstellen';

  @override
  String get createNewSeason => 'Neue Saison erstellen';

  @override
  String get createNewSeasonToStart =>
      'Erstellen Sie eine neue Saison, um zu beginnen';

  @override
  String get createNewTeam => 'Neues Team erstellen';

  @override
  String get createNewTeamToStart =>
      'Erstellen Sie ein neues Team, um zu beginnen';

  @override
  String get createTeam => 'Team erstellen';

  @override
  String get creator => 'Ersteller';

  @override
  String get currently => 'Aktuell';

  @override
  String get dataImport => 'Datenimport';

  @override
  String get databaseAlreadyExists =>
      'Eine Cloud-Datenbank mit diesem Namen existiert bereits.';

  @override
  String get databaseImportInProgress => 'Datenbankimport läuft noch...';

  @override
  String get databaseImported => 'Datenbank erfolgreich importiert!';

  @override
  String get databaseName => 'Datenbankname';

  @override
  String get databaseNotFound => 'Datenbank nicht gefunden';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Debug: Firestore → Realtime Migration';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAccomplishment => 'Erfolg löschen';

  @override
  String get deleteAccomplishmentConfirmation =>
      'Möchten Sie diesen Erfolg wirklich löschen?';

  @override
  String deleteAwardConfirm(Object title) {
    return 'Möchten Sie \'$title\' wirklich löschen?';
  }

  @override
  String get deleteAwardTitle => 'Auszeichnung löschen';

  @override
  String deleteHighlightConfirm(Object title) {
    return 'Möchten Sie \'$title\' wirklich löschen?';
  }

  @override
  String get deleteHighlightTitle => 'Highlight löschen';

  @override
  String get displayOrder => 'Anzeigereihenfolge';

  @override
  String get downloadErrorReport => 'Fehlerbericht herunterladen';

  @override
  String get downloadTemplate => 'Vorlage herunterladen';

  @override
  String get duplicatePlayerName => 'Doppelter Spielername';

  @override
  String durationSeconds(Object seconds) {
    return 'Dauer: $seconds Sekunden';
  }

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editAward => 'Auszeichnung bearbeiten';

  @override
  String get editGame => 'Spiel bearbeiten';

  @override
  String get editHighlight => 'Highlight bearbeiten';

  @override
  String get editPlayer => 'Spieler bearbeiten';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get endGame => 'Spiel beenden';

  @override
  String get endOfGame => 'Spielende';

  @override
  String get endOfRegulation => 'Ende der regulären Spielzeit';

  @override
  String get enterEmailToAddAdmin =>
      'E-Mail eingeben, um als Administrator hinzuzufügen';

  @override
  String get enterFourDigitPin => '4-stellige PIN eingeben';

  @override
  String get enterPinToEdit => 'PIN eingeben, um Profil zu bearbeiten';

  @override
  String get enterTeamIdPrompt =>
      'Geben Sie eine 6-stellige Team-ID ein, um Statistiken anzuzeigen:';

  @override
  String get entityType => 'Entitätstyp';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Fehler beim Löschen des Erfolgs: $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Fehler beim Löschen der Auszeichnung: $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Fehler beim Löschen des Highlights: $error';
  }

  @override
  String get errorDuringShare => 'Fehler beim Teilen, bitte erneut versuchen';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Fehler beim Generieren der Aufstellung: $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Fehler beim Laden der Zugriffsliste: $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Fehler beim Laden der Auszeichnungen: $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Fehler beim Laden der Anmeldedaten: $error';
  }

  @override
  String get errorLoadingDatabase => 'Fehler beim Laden der Datenbank.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Fehler beim Laden der Duplikate: $error';
  }

  @override
  String get errorLoadingEvents => 'Fehler beim Laden der Ereignisse';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Fehler beim Laden der Highlights: $error';
  }

  @override
  String get errorLoadingHistory => 'Fehler beim Laden des Verlaufs';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Fehler beim Laden der Spielerstatistiken: $error\n\nStack-Trace: $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Fehler beim Laden der freigegebenen Datenbanken: $error';
  }

  @override
  String get errorLoadingStats => 'Fehler beim Laden der Statistiken';

  @override
  String errorLoggingOut(Object error) {
    return 'Fehler beim Abmelden: $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Fehler: $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Fehler beim Öffnen des Links: $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Fehler beim Neuordnen: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Fehler beim Speichern der Auszeichnung: $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Fehler beim Speichern des Highlights: $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Fehler beim Speichern der Einstellungen: $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Fehler beim Senden des Tweets: $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Fehler beim Teilen des Bildes: $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Fehler beim Teilen auf Twitter: $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Fehler beim Aktualisieren der Spielzeit: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Fehler beim Aktualisieren des Profils: $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Fehler beim Hochladen der Bilder: $error';
  }

  @override
  String get exitEditMode => 'Bearbeitungsmodus beenden';

  @override
  String get failedToGrantAccess =>
      'Zugriff konnte nicht gewährt werden. Benutzer existiert möglicherweise nicht.';

  @override
  String get failedToOpenDatabase => 'Datenbank konnte nicht geöffnet werden';

  @override
  String get failedToSendTweet =>
      'Fehler beim Senden des Tweets. Bitte erneut versuchen.';

  @override
  String get finalOT => 'Endstand n.V.';

  @override
  String get finalOTText => 'Endstand n.V.';

  @override
  String get finalPKs => 'Endstand n.E.';

  @override
  String get finalPKsText => 'Endstand n.E.';

  @override
  String get finalText => 'Endstand';

  @override
  String get firestoreDocumentPath => 'Firestore-Dokumentpfad';

  @override
  String get formation => 'Formation';

  @override
  String get fouls => 'Fouls';

  @override
  String get gallery => 'Galerie';

  @override
  String get game => 'Spiel';

  @override
  String get gameDayTweetSentSuccessfully =>
      'Spieltag-Tweet erfolgreich gesendet! 🎉';

  @override
  String get gameStats => 'Spielstatistiken';

  @override
  String get generate => 'Generieren';

  @override
  String get generateImage => 'Bild generieren';

  @override
  String get generateLineup => 'Aufstellung generieren';

  @override
  String get generateLineupImage => 'Aufstellungsbild generieren';

  @override
  String get generateNewMessage => 'Neue Nachricht generieren';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get goBack => 'Zurück';

  @override
  String get goPro => 'Auf Pro upgraden';

  @override
  String get goToGame => 'Zum Spiel gehen';

  @override
  String get goalCelebrationPosts => 'Torfeier-Posts';

  @override
  String get goals => 'Tore';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get hideHighlights => 'Highlights ausblenden';

  @override
  String get highlightDeleted => 'Highlight gelöscht';

  @override
  String get highlightSaved => 'Highlight erfolgreich gespeichert';

  @override
  String get highlights => 'Highlights';

  @override
  String get hintAwardTitle => 'z.B. MVP, All-Star, Torschützenkönig';

  @override
  String get hintDescriptionOptional => 'Optionale Beschreibung';

  @override
  String get hintTitleExample => 'z.B. Siegestor';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Analytik';

  @override
  String get historyVersus => 'Analytik';

  @override
  String get home => 'HEIM';

  @override
  String get importSeason => 'Saison importieren';

  @override
  String get importTeamsPlayersGamesStats =>
      'Teams, Spieler, Spiele und Statistiken importieren';

  @override
  String get importingDatabase => 'Datenbank wird importiert...';

  @override
  String get invalidPin => 'PIN muss 4 Ziffern haben';

  @override
  String get labelAwardImage => 'Auszeichnungsbild (optional)';

  @override
  String get labelAwardTitle => 'Auszeichnungstitel *';

  @override
  String get labelDate => 'Datum';

  @override
  String get labelDescription => 'Beschreibung';

  @override
  String get labelTitleRequired => 'Titel *';

  @override
  String get labelVideoUrlRequired => 'Video-URL *';

  @override
  String get language => 'Sprache';

  @override
  String get leaders => 'Führende';

  @override
  String get lightMode => 'Heller Modus';

  @override
  String get lineupGeneratorMobileOnly =>
      'Der Aufstellungsgenerator ist nur auf mobilen Geräten verfügbar';

  @override
  String get lineupSharedSuccessfully => 'Aufstellung erfolgreich geteilt!';

  @override
  String get lineupTweetedSuccessfully =>
      'Aufstellung erfolgreich getweetet! 🎉';

  @override
  String get linkURL => 'Link-URL';

  @override
  String get liveBannerTapToWatch => 'LIVE — Tippen, um den Stream zu sehen';

  @override
  String get liveUrlLabel => 'Live-URL';

  @override
  String get loadTeam => 'Team laden';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get loadingAllSeasons => 'Lade alle Saisons...';

  @override
  String get logOut => 'Abmelden';

  @override
  String get logOutConfirmation =>
      'Sind Sie sicher, dass Sie sich abmelden möchten? Sie müssen sich erneut anmelden, um auf Cloud-Datenbanken zuzugreifen.';

  @override
  String get loggedOutSuccessfully => 'Erfolgreich abgemeldet';

  @override
  String get logs => 'Protokolle';

  @override
  String get lossAbbreviation => 'N';

  @override
  String get matchDate => 'Spieldatum';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get mergeAllIntoFirst => 'Alle in den ersten zusammenführen';

  @override
  String get mergeComplete => 'Zusammenführung abgeschlossen';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthDec => 'Dez';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthSep => 'Sep';

  @override
  String get multipleCardStyles => 'Mehrere Kartenstile';

  @override
  String get multipleFiles => 'Mehrere Dateien:';

  @override
  String get newDatabase => 'Neue Datenbank';

  @override
  String get newEvent => 'Neues Ereignis';

  @override
  String get newPlayer => 'Neuer Spieler';

  @override
  String get newSeason => 'Neue Saison';

  @override
  String get newTeam => 'Neues Team';

  @override
  String get nextGamePrefix => 'Nächstes Spiel:';

  @override
  String get nextGameStayTuned =>
      'Bleiben Sie dran für den Live-Link, sobald es beginnt';

  @override
  String get noAdminsYet => 'Noch keine Administratoren';

  @override
  String get noAwardsAvailable => 'Keine Auszeichnungen verfügbar';

  @override
  String get noCloudDatabasesFound => 'Keine Cloud-Datenbanken gefunden';

  @override
  String get noData => 'Keine Daten';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get noDatabaseFoundMessage =>
      'Um zu beginnen, müssen Sie eine neue Datenbank erstellen oder eine bestehende öffnen. Möchten Sie Ihre Datenbank jetzt einrichten?';

  @override
  String get noDuplicatesToMerge => 'Keine Duplikate zum Zusammenführen';

  @override
  String get noEmail => 'Keine E-Mail';

  @override
  String get noGameAvailableToSetLiveLink =>
      'Kein Spiel verfügbar, um Live-Link zu setzen';

  @override
  String get noGameAvailableToTweetAbout => 'Kein Spiel verfügbar zum Tweeten';

  @override
  String get noGamesFound => 'Keine Spiele gefunden';

  @override
  String get noHighlightsAvailable => 'Keine Highlights verfügbar';

  @override
  String get noLogsYet => 'Noch keine Protokolle.';

  @override
  String get noPlayersFound => 'Keine Spieler gefunden';

  @override
  String get noSeasonsFound => 'Keine Saisons gefunden';

  @override
  String get noStatsAvailable => 'Keine Statistiken verfügbar';

  @override
  String get noTeamDataAvailable => 'Keine Teamdaten verfügbar';

  @override
  String get noTeamFound => 'Kein Team gefunden';

  @override
  String get noTeamSelected => 'Kein Team ausgewählt';

  @override
  String get notAnAdministrator => 'Kein Administrator';

  @override
  String get notSignedIn => 'Nicht angemeldet';

  @override
  String get offside => 'Abseits';

  @override
  String get openDatabase => 'Datenbank öffnen';

  @override
  String get openExistingCloudDatabase => 'Bestehende Cloud-Datenbank öffnen';

  @override
  String get openFromBackup => 'Aus Backup öffnen';

  @override
  String openedDatabase(Object name) {
    return 'Datenbank geöffnet: $name';
  }

  @override
  String get optionalDetails => 'Optionale Details';

  @override
  String get optionalExternalLink => 'Optionaler externer Link';

  @override
  String get other => 'Sonstiges';

  @override
  String get overall => 'Gesamt';

  @override
  String get overview => 'Übersicht';

  @override
  String get password => 'Passwort';

  @override
  String get pickAColor => 'Farbe auswählen';

  @override
  String get pickTeamColors => 'Teamfarben auswählen';

  @override
  String get pinLabel => 'PIN';

  @override
  String get playerName => 'Spielername';

  @override
  String get playerNotFound => 'Spieler nicht gefunden';

  @override
  String get playerNumber => 'Spielernummer';

  @override
  String get playerProfilesProFeature =>
      'Spielerprofile sind Teil der Pro-Version. Upgraden Sie, um auf detaillierte Spielerstatistiken und Karriereverlauf zuzugreifen.';

  @override
  String get players => 'Spieler';

  @override
  String get pleaseAddPlayersFirst =>
      'Bitte fügen Sie zuerst Spieler zur Saison hinzu';

  @override
  String get pleaseCorrectFormErrors =>
      'Bitte korrigieren Sie die Fehler im Formular.';

  @override
  String get pleaseCreateOrOpenADatabase =>
      'Bitte erstellen oder öffnen Sie eine Datenbank';

  @override
  String get pleaseCreateSeasonFirst =>
      'Bitte erstellen Sie zuerst eine Saison, um eine Aufstellung zu generieren';

  @override
  String get pleaseEnterEmailAddress =>
      'Bitte geben Sie eine E-Mail-Adresse ein';

  @override
  String get pleaseSelectAll11Players => 'Bitte wählen Sie alle 11 Spieler aus';

  @override
  String get postGameResults => 'Spielergebnisse posten';

  @override
  String get postGameStats => 'Spielstatistiken posten';

  @override
  String get postSeasonStats => 'Saisonstatistiken posten';

  @override
  String get preparingShare => 'Wird vorbereitet...';

  @override
  String get preview => 'Vorschau';

  @override
  String get previousLineupRestored =>
      'Vorherige Aufstellung wiederhergestellt';

  @override
  String get primaryColor => 'Primärfarbe';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Pro-Funktion';

  @override
  String get proSubscriptionFeatures => 'PRO-ABONNEMENT-FUNKTIONEN';

  @override
  String get profilePhoto => 'Profilfoto';

  @override
  String get profilePicture => 'Profilbild';

  @override
  String get profileUpdated => 'Profil erfolgreich aktualisiert';

  @override
  String get recentGames => 'Letzte Spiele';

  @override
  String get recentHighlights => 'Aktuelle Highlights';

  @override
  String get recordHolders => 'Rekordhalter';

  @override
  String get records => 'Rekorde';

  @override
  String get redCards => 'Rote Karten';

  @override
  String get remindMeLater => 'Später erinnern';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeButton => 'Entfernen';

  @override
  String get removeImage => 'Bild entfernen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get revokeAccess => 'Zugriff widerrufen';

  @override
  String rowNumber(Object number) {
    return 'Zeile $number';
  }

  @override
  String get save => 'Speichern';

  @override
  String get saves => 'Paraden';

  @override
  String get scoringSummary => 'Torzusammenfassung';

  @override
  String get season => 'Saison';

  @override
  String get seasonName => 'Saisonname';

  @override
  String get seasonNotFound => 'Saison nicht gefunden';

  @override
  String get seasonStats => 'Saisonstatistiken';

  @override
  String get seasons => 'Saisons';

  @override
  String get secondaryColor => 'Sekundärfarbe';

  @override
  String get selectACloudDatabase => 'Cloud-Datenbank auswählen';

  @override
  String get selectADatabase => 'Datenbank auswählen';

  @override
  String get selectEventType => 'Ereignistyp auswählen';

  @override
  String get selectImageSource => 'Bildquelle auswählen';

  @override
  String get selectOpponent => 'Gegner auswählen';

  @override
  String get selectPeriod => 'Periode auswählen';

  @override
  String get selectPlayer => 'Spieler auswählen';

  @override
  String get sendTweet => 'Tweet senden';

  @override
  String get setGameTime => 'Spielzeit festlegen';

  @override
  String get setLiveLink => 'Live-Link festlegen';

  @override
  String get setLiveStreamLink => 'Live-Stream-Link setzen';

  @override
  String get setTeamColors => 'Teamfarben festlegen';

  @override
  String get setTime => 'Zeit festlegen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get shareDatabase => 'Datenbank teilen';

  @override
  String get shareImage => 'Bild teilen';

  @override
  String get shareToSocialMedia => 'In sozialen Medien teilen';

  @override
  String get sharedSuccessfully => 'Erfolgreich geteilt!';

  @override
  String get shots => 'Schüsse';

  @override
  String get shotsOnGoal => 'Schüsse aufs Tor';

  @override
  String get showHighlights => 'Highlights anzeigen';

  @override
  String get signIn => 'Anmelden';

  @override
  String signInFailed(Object error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get signInRequired => 'Anmeldung erforderlich';

  @override
  String get signInToAccessCloudDatabases =>
      'Melden Sie sich an, um auf Cloud-Datenbanken zuzugreifen';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String signedInWith(Object provider) {
    return 'Angemeldet mit $provider';
  }

  @override
  String get skip => 'Überspringen';

  @override
  String get soccerAnalytics => 'Fußball-Analytik';

  @override
  String get startImport => 'Import starten';

  @override
  String get systemDefaultLanguage => 'Systemstandard';

  @override
  String get systemDefaultTheme => 'Systemstandard';

  @override
  String get team => 'Team';

  @override
  String get teamAccomplishments => 'Team-Erfolge';

  @override
  String get teamId => 'Team-ID';

  @override
  String get teamName => 'Teamname';

  @override
  String get teamShortName => 'Team-Kurzname';

  @override
  String get teamStandings => 'Teamwertung';

  @override
  String get teamSummary => 'Über das Team';

  @override
  String get editTeamSummary => 'Team-Zusammenfassung bearbeiten';

  @override
  String get teamSummaryHint =>
      'Geben Sie eine kurze Beschreibung Ihres Teams ein...';

  @override
  String get teamSummarySaved => 'Team-Zusammenfassung erfolgreich gespeichert';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer => 'TeamSync-Datenbank-Viewer';

  @override
  String get teamSyncViewer => 'TeamSync-Viewer';

  @override
  String get termsOfUse => 'Nutzungsbedingungen';

  @override
  String get themeClassic => 'Klassisch';

  @override
  String get themeDarkMode => 'Dunkelmodus';

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
      'Dies wird die folgenden Spieler zusammenführen:';

  @override
  String get tieAbbreviation => 'U';

  @override
  String get time => 'Zeit';

  @override
  String get titleUrlRequired => 'Titel und URL sind erforderlich';

  @override
  String get tweetGameDay => 'Spieltag tweeten';

  @override
  String get tweetSentSuccessfully => 'Tweet erfolgreich gesendet!';

  @override
  String get tweetedSuccessfully => 'Erfolgreich getweetet!';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Twitter-Einstellungen';

  @override
  String get twitterSettingsSavedSuccessfully =>
      'Twitter-Einstellungen erfolgreich gespeichert!';

  @override
  String get unableToOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get unableToOpenLiveLink => 'Live-Link kann nicht geöffnet werden';

  @override
  String get unexpectedDatabaseFormat => 'Unerwartetes Datenbankformat';

  @override
  String get unlockButton => 'Entsperren';

  @override
  String get update => 'Aktualisieren';

  @override
  String get updateButton => 'Aktualisieren';

  @override
  String get upgradeToPro => 'Auf Pro upgraden';

  @override
  String get uploadImage => 'Bild hochladen';

  @override
  String get uploadingImage => 'Bild wird hochgeladen...';

  @override
  String get addLogo => 'Logo hinzufügen';

  @override
  String get changeLogo => 'Logo ändern';

  @override
  String get removeLogo => 'Logo entfernen';

  @override
  String get confirmRemoveLogo =>
      'Sind Sie sicher, dass Sie dieses Logo entfernen möchten?';

  @override
  String get logoUpdated => 'Logo erfolgreich aktualisiert';

  @override
  String get logoRemoved => 'Logo erfolgreich entfernt';

  @override
  String get useDeviceLanguage => 'Gerätesprache verwenden';

  @override
  String get userEmail => 'Benutzer-E-Mail';

  @override
  String get validateOnly => 'Nur validieren';

  @override
  String get videoLabel => 'Video';

  @override
  String get viewMore => 'Mehr anzeigen';

  @override
  String get watchLabel => 'Ansehen';

  @override
  String get welcomeToTeamSync => 'Willkommen bei TeamSync!';

  @override
  String get winAbbreviation => 'S';

  @override
  String get year => 'Jahr';

  @override
  String get yellowCards => 'Gelbe Karten';

  @override
  String get noGamesYet => 'Noch keine Spiele';

  @override
  String get live => 'LIVE';

  @override
  String get win => 'SIEG';

  @override
  String get loss => 'NIEDERLAGE';

  @override
  String get tie => 'UNENTSCHIEDEN';

  @override
  String get teamPerformance => 'Team-Leistung';

  @override
  String teamPerformanceSince(Object year) {
    return 'Team-Leistung (Seit $year)';
  }

  @override
  String get addAccomplishment => 'Erfolg hinzufügen';

  @override
  String get editAccomplishment => 'Erfolg bearbeiten';

  @override
  String get titleRequired => 'Titel *';

  @override
  String get titleIsRequired => 'Titel ist erforderlich';

  @override
  String get exampleStateChampions => 'z.B. Staatsmeister';

  @override
  String get exampleYear => 'z.B. 2023';

  @override
  String get saving => 'Wird gespeichert...';

  @override
  String get since => 'Seit';

  @override
  String get images => 'Bilder';

  @override
  String get tapImageToPrimary =>
      'Tippen Sie auf ein Bild, um es als Hauptbild festzulegen';

  @override
  String get selectMultipleImages =>
      'Sie können mehrere Bilder gleichzeitig auswählen';

  @override
  String get primary => 'Haupt';

  @override
  String get notAuthorizedUploadImages =>
      'Nicht berechtigt, Bilder hochzuladen. Melden Sie sich auf dem Handy an, um Bilder hinzuzufügen.';

  @override
  String get games => 'Spiele';

  @override
  String gameTimeSet(Object time) {
    return 'Spielzeit auf $time festgelegt';
  }

  @override
  String get noTimeSetPrompt =>
      'Dieses Spiel hat keine Uhrzeit festgelegt (aktuell 00:00). Möchten Sie die Spielzeit vor dem Tweeten festlegen?';

  @override
  String get sortByTeamName => 'Teamname';

  @override
  String get sortByMostGames => 'Meiste Spiele';

  @override
  String get sortByMostWins => 'Meiste Siege';

  @override
  String get sortByWinPercentage => '% Sieg';

  @override
  String get sortByRecent => 'Aktuell';

  @override
  String get noMatchupHistoryYet => 'Noch kein Vergleichsverlauf';

  @override
  String get gamesSingular => 'Spiel';

  @override
  String get gamesPlural => 'Spiele';

  @override
  String gamesPlayed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Spiele',
      one: 'Spiel',
    );
    return '$count $_temp0 gespielt';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get editSeasonName => 'Saisonname bearbeiten';

  @override
  String get seasonNameRequired => 'Saisonname ist erforderlich';

  @override
  String get seasonNameUpdated => 'Saisonname erfolgreich aktualisiert';

  @override
  String get analytics => 'Analytik';

  @override
  String get avgGoalsFor => 'Durchschn. Tore Für';

  @override
  String get avgGoalsAgainst => 'Durchschn. Tore Gegen';

  @override
  String get biggestWin => 'Größter Sieg';

  @override
  String get biggestLoss => 'Größte Niederlage';

  @override
  String get currentStreak => 'Aktuelle Serie';

  @override
  String get longestWinStreak => 'Längste Siegesserie';

  @override
  String get recentForm => 'Aktuelle Form (Letzte 5)';

  @override
  String get cleanSheets => 'Zu Null';

  @override
  String get goalDifferential => 'Tordifferenz';

  @override
  String get homeRecord => 'Heimbilanz';

  @override
  String get awayRecord => 'Auswärtsbilanz';

  @override
  String get pointsPerGame => 'Punkte pro Spiel';

  @override
  String get shootingAccuracy => 'Schussgenauigkeit';

  @override
  String get comebackWins => 'Aufholjagd-Siege';

  @override
  String get lateGoals => 'Späte Tore (80+)';

  @override
  String get cardsPerGame => 'Karten pro Spiel';

  @override
  String get statistics => 'Statistiken';

  @override
  String get scoringEvents => 'Torereignisse';

  @override
  String get noScoringEventsYet => 'Noch keine Torereignisse';

  @override
  String get gameStatistics => 'Spielstatistiken';

  @override
  String get shotsOnTarget => 'Schüsse aufs Tor';

  @override
  String get goalAnalytics => 'Tor-Analyse';

  @override
  String get totalGoalsScored => 'Gesamt Erzielte Tore';

  @override
  String get totalGoalsConceded => 'Gesamt Kassierte Tore';

  @override
  String get avgGoalsPerGame => 'Durchschn. Tore Pro Spiel';

  @override
  String get streaksRecords => 'Serien & Rekorde';

  @override
  String get longestUnbeatenStreak => 'Längste Ungeschlagene Serie';

  @override
  String get mostGoalsInGame => 'Meiste Tore in einem Spiel';

  @override
  String get biggestVictory => 'Größter Sieg';

  @override
  String get homeAwayAnalysis => 'Heim vs Auswärts';

  @override
  String get homeWinPercentage => 'Heim Sieg %';

  @override
  String get awayWinPercentage => 'Auswärts Sieg %';

  @override
  String get defensiveStats => 'Defensive Statistiken';

  @override
  String get cleanSheetPercentage => 'Zu Null %';

  @override
  String get avgGoalsConceded => 'Durchschn. Kassierte Tore';

  @override
  String get shutoutsRecorded => 'Aufgezeichnete Zu-Null-Spiele';

  @override
  String get allTime => 'Alle Zeiten';

  @override
  String get currentSeason => 'Aktuelle Saison';

  @override
  String get lastSeason => 'Letzte Saison';

  @override
  String get last3Years => 'Letzte 3 Saisons';

  @override
  String get last5Years => 'Letzte 5 Saisons';

  @override
  String get last10Years => 'Letzte 10 Saisons';

  @override
  String get overallStatistics => 'Gesamtstatistiken';

  @override
  String get recordSummary => 'Rekordzusammenfassung';

  @override
  String get totalGames => 'Gesamte Spiele';

  @override
  String get wins => 'Siege';

  @override
  String get losses => 'Niederlagen';

  @override
  String get ties => 'Unentschieden';

  @override
  String get winPercentage => 'Sieg %';

  @override
  String get playerProfileQRCode => 'Spielerprofil QR-Code';

  @override
  String get scanQRCodeToViewProfile =>
      'QR-Code scannen, um dieses Spielerprofil anzuzeigen';

  @override
  String get tapToEnlarge => 'Tippen zum Vergrößern';

  @override
  String playerProfileLink(Object playerName) {
    return 'Spielerprofil: $playerName';
  }

  @override
  String get errorSharingLink => 'Fehler beim Teilen des Links';

  @override
  String get share => 'Teilen';

  @override
  String get sending => 'Sending...';

  @override
  String get twitterNotConfigured =>
      'Twitter is not configured. Please configure Twitter in Settings.';

  @override
  String get opponents => 'Gegner';
}
