// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get email => 'Email';

  @override
  String get description => 'Descrizione';

  @override
  String accessGrantedTo(Object email) {
    return 'Accesso concesso a $email';
  }

  @override
  String get accomplishmentDeleted => 'Risultato eliminato';

  @override
  String get accomplishmentsReordered => 'Risultati riordinati';

  @override
  String get account => 'Account';

  @override
  String get actionPhoto => 'Foto azione';

  @override
  String get actionPhotoCards => 'Carte foto azione';

  @override
  String get add => 'Aggiungi';

  @override
  String get addAssistQuestion => 'Aggiungi assist?';

  @override
  String get addAward => 'Aggiungi riconoscimento';

  @override
  String get addAwardDialogTitle => 'Aggiungi riconoscimento';

  @override
  String get addButton => 'Aggiungi';

  @override
  String get addHighlight => 'Aggiungi highlight';

  @override
  String get addHighlightDialogTitle => 'Aggiungi highlight';

  @override
  String get addLink => 'Aggiungi link';

  @override
  String get adminAddedSuccessfully => 'Amministratore aggiunto con successo';

  @override
  String get adminRemovedSuccessfully => 'Amministratore rimosso con successo';

  @override
  String get advanceGame => 'Avanza partita';

  @override
  String get allowPlayerEditProfile =>
      'Consenti al giocatore di modificare il proprio profilo sul web';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Aspetto';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Sei sicuro di voler eliminare questo evento? Questa azione non può essere annullata.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Sei sicuro di voler eliminare questa partita? Tutti i dati associati a questa partita verranno eliminati. Questa azione non può essere annullata.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Sei sicuro di voler eliminare questo giocatore? Tutti i dati associati a questo giocatore verranno eliminati. Questa azione non può essere annullata.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Sei sicuro di voler eliminare questa stagione? Tutti i dati associati a questa stagione verranno eliminati. Questa azione non può essere annullata.';

  @override
  String get assistedBy => 'Assist di';

  @override
  String get assists => 'Assist';

  @override
  String get automaticTheme => 'Tema automatico';

  @override
  String get automaticThemeSwitchDescription =>
      'Cambia automaticamente il tema in base all\'ora del giorno';

  @override
  String get awardDeleted => 'Riconoscimento eliminato';

  @override
  String get awardSaved => 'Riconoscimento salvato con successo';

  @override
  String get awards => 'Riconoscimenti';

  @override
  String get away => 'TRASFERTA';

  @override
  String get backupDatabase => 'Backup del database corrente su dispositivo';

  @override
  String get bestGame => 'Miglior partita';

  @override
  String get bestSeason => 'Miglior stagione';

  @override
  String get calculating => 'Calcolo in corso...';

  @override
  String get camera => 'Fotocamera';

  @override
  String get cancel => 'Annulla';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get career => 'Carriera';

  @override
  String get careerLeaders => 'Leader di carriera';

  @override
  String get careerStatsTitle => 'Statistiche di carriera';

  @override
  String get changeImage => 'Cambia immagine';

  @override
  String get changeTeamColors => 'Cambia colori squadra';

  @override
  String get clearLogs => 'Cancella log';

  @override
  String get close => 'Chiudi';

  @override
  String get closeSidebar => 'Chiudi barra laterale';

  @override
  String get composeTweet => 'Componi tweet';

  @override
  String get confirmDelete => 'Conferma eliminazione';

  @override
  String get connectToTwitter => 'Connetti a Twitter';

  @override
  String get continueButton => 'Continua';

  @override
  String get continueText => 'Continua';

  @override
  String get continueWithoutSigningIn => 'Continua senza accedere';

  @override
  String get convertToCloud => 'Converti in database cloud';

  @override
  String get corners => 'Calci d\'Angolo';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Impossibile aprire l\'URL: $url';
  }

  @override
  String get create => 'Crea';

  @override
  String get createAnyway => 'Crea comunque';

  @override
  String get createNewCloudDatabase => 'Crea nuovo database cloud';

  @override
  String get createNewDatabase => 'Crea nuovo database';

  @override
  String get createNewGameToStart => 'Crea una nuova partita per iniziare';

  @override
  String get createNewOpponent => 'Crea nuovo avversario';

  @override
  String get createNewSeason => 'Crea nuova stagione';

  @override
  String get createNewSeasonToStart => 'Crea una nuova stagione per iniziare';

  @override
  String get createNewTeam => 'Crea nuova squadra';

  @override
  String get createNewTeamToStart => 'Crea una nuova squadra per iniziare';

  @override
  String get createTeam => 'Crea squadra';

  @override
  String get creator => 'Creatore';

  @override
  String get currently => 'Attualmente';

  @override
  String get dataImport => 'Importazione dati';

  @override
  String get databaseAlreadyExists =>
      'Esiste già un database cloud con questo nome.';

  @override
  String get databaseImportInProgress =>
      'Importazione database ancora in corso...';

  @override
  String get databaseImported => 'Database importato con successo!';

  @override
  String get databaseName => 'Nome database';

  @override
  String get databaseNotFound => 'Database non trovato';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Debug: Migrazione Firestore → Realtime';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteAccomplishment => 'Elimina risultato';

  @override
  String get deleteAccomplishmentConfirmation =>
      'Sei sicuro di voler eliminare questo risultato?';

  @override
  String deleteAwardConfirm(Object title) {
    return 'Sei sicuro di voler eliminare \"$title\"?';
  }

  @override
  String get deleteAwardTitle => 'Elimina riconoscimento';

  @override
  String deleteHighlightConfirm(Object title) {
    return 'Sei sicuro di voler eliminare \"$title\"?';
  }

  @override
  String get deleteHighlightTitle => 'Elimina highlight';

  @override
  String get displayOrder => 'Ordine di visualizzazione';

  @override
  String get downloadErrorReport => 'Scarica report errori';

  @override
  String get downloadTemplate => 'Scarica modello';

  @override
  String get duplicatePlayerName => 'Nome giocatore duplicato';

  @override
  String durationSeconds(Object seconds) {
    return 'Durata: $seconds secondi';
  }

  @override
  String get edit => 'Modifica';

  @override
  String get editAward => 'Modifica riconoscimento';

  @override
  String get editGame => 'Modifica partita';

  @override
  String get editHighlight => 'Modifica highlight';

  @override
  String get editPlayer => 'Modifica giocatore';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get endGame => 'Termina partita';

  @override
  String get endOfGame => 'Fine partita';

  @override
  String get endOfRegulation => 'Fine tempo regolamentare';

  @override
  String get enterEmailToAddAdmin =>
      'Inserisci email per aggiungere come amministratore';

  @override
  String get enterFourDigitPin => 'Inserisci un PIN di 4 cifre';

  @override
  String get enterPinToEdit => 'Inserisci il PIN per modificare il profilo';

  @override
  String get enterTeamIdPrompt =>
      'Inserisci un ID squadra di 6 cifre per visualizzare le statistiche:';

  @override
  String get entityType => 'Tipo entità';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Errore nell\'eliminazione del risultato: $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Errore nell\'eliminazione del riconoscimento: $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Errore nell\'eliminazione dell\'highlight: $error';
  }

  @override
  String get errorDuringShare => 'Errore durante la condivisione, riprova';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Errore nella generazione della formazione: $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Errore nel caricamento dell\'elenco accessi: $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Errore nel caricamento dei riconoscimenti: $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Errore nel caricamento delle credenziali: $error';
  }

  @override
  String get errorLoadingDatabase => 'Errore nel caricamento del database.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Errore nel caricamento dei duplicati: $error';
  }

  @override
  String get errorLoadingEvents => 'Errore nel caricamento degli eventi';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Errore nel caricamento degli highlights: $error';
  }

  @override
  String get errorLoadingHistory => 'Errore nel caricamento dello storico';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Errore nel caricamento delle statistiche del giocatore: $error\n\nStack trace: $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Errore nel caricamento dei database condivisi: $error';
  }

  @override
  String get errorLoadingStats => 'Errore nel caricamento delle statistiche';

  @override
  String errorLoggingOut(Object error) {
    return 'Errore durante la disconnessione: $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Errore: $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Errore nell\'apertura del link: $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Errore nel riordinamento: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Errore nel salvataggio: $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Errore nel salvataggio del riconoscimento: $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Errore nel salvataggio dell\'highlight: $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Errore nel salvataggio delle impostazioni: $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Errore nell\'invio del tweet: $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Errore nella condivisione dell\'immagine: $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Errore nella condivisione su Twitter: $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Errore nell\'aggiornamento dell\'orario della partita: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Errore nell\'aggiornamento del profilo: $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Errore nel caricamento delle immagini: $error';
  }

  @override
  String get exitEditMode => 'Esci dalla modalità modifica';

  @override
  String get failedToGrantAccess =>
      'Concessione accesso fallita. L\'utente potrebbe non esistere.';

  @override
  String get failedToOpenDatabase => 'Apertura database fallita';

  @override
  String get failedToSendTweet => 'Invio del tweet fallito. Riprova.';

  @override
  String get finalOT => 'Finale TS';

  @override
  String get finalOTText => 'Finale TS';

  @override
  String get finalPKs => 'Finale Rigori';

  @override
  String get finalPKsText => 'Finale Rigori';

  @override
  String get finalText => 'Finale';

  @override
  String get firestoreDocumentPath => 'Percorso documento Firestore';

  @override
  String get formation => 'Formazione';

  @override
  String get fouls => 'Falli';

  @override
  String get gallery => 'Galleria';

  @override
  String get game => 'Partita';

  @override
  String get gameDayTweetSentSuccessfully =>
      'Tweet del giorno della partita inviato con successo! 🎉';

  @override
  String get gameStats => 'Statistiche partita';

  @override
  String get generate => 'Genera';

  @override
  String get generateImage => 'Genera immagine';

  @override
  String get generateLineup => 'Genera formazione';

  @override
  String get generateLineupImage => 'Genera immagine formazione';

  @override
  String get generateNewMessage => 'Genera nuovo messaggio';

  @override
  String get getStarted => 'Inizia';

  @override
  String get goBack => 'Indietro';

  @override
  String get goPro => 'Passa a Pro';

  @override
  String get goToGame => 'Vai alla partita';

  @override
  String get goalCelebrationPosts => 'Post di celebrazione gol';

  @override
  String get goals => 'Gol';

  @override
  String get gotIt => 'Capito';

  @override
  String get hideHighlights => 'Nascondi highlights';

  @override
  String get highlightDeleted => 'Highlight eliminato';

  @override
  String get highlightSaved => 'Highlight salvato con successo';

  @override
  String get highlights => 'Highlights';

  @override
  String get hintAwardTitle => 'es. MVP, All-Star, Capocannoniere';

  @override
  String get hintDescriptionOptional => 'Descrizione opzionale';

  @override
  String get hintTitleExample => 'es. Gol della vittoria';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Analitica';

  @override
  String get historyVersus => 'Analitica';

  @override
  String get home => 'CASA';

  @override
  String get importSeason => 'Importa stagione';

  @override
  String get importTeamsPlayersGamesStats =>
      'Importa squadre, giocatori, partite e statistiche';

  @override
  String get importingDatabase => 'Importazione database...';

  @override
  String get invalidPin => 'Il PIN deve essere di 4 cifre';

  @override
  String get labelAwardImage => 'Immagine riconoscimento (opzionale)';

  @override
  String get labelAwardTitle => 'Titolo riconoscimento *';

  @override
  String get labelDate => 'Data';

  @override
  String get labelDescription => 'Descrizione';

  @override
  String get labelTitleRequired => 'Titolo *';

  @override
  String get labelVideoUrlRequired => 'URL video *';

  @override
  String get language => 'Lingua';

  @override
  String get leaders => 'Leader';

  @override
  String get lightMode => 'Modalità chiara';

  @override
  String get lineupGeneratorMobileOnly =>
      'Il generatore di formazioni è disponibile solo su dispositivi mobili';

  @override
  String get lineupSharedSuccessfully => 'Formazione condivisa con successo!';

  @override
  String get lineupTweetedSuccessfully =>
      'Formazione twittata con successo! 🎉';

  @override
  String get linkURL => 'URL link';

  @override
  String get liveBannerTapToWatch => 'LIVE — Tocca per guardare lo stream';

  @override
  String get liveUrlLabel => 'URL Live';

  @override
  String get loadTeam => 'Carica squadra';

  @override
  String get loading => 'Caricamento...';

  @override
  String get loadingAllSeasons => 'Caricamento di tutte le stagioni...';

  @override
  String get logOut => 'Disconnetti';

  @override
  String get logOutConfirmation =>
      'Sei sicuro di voler uscire? Dovrai accedere nuovamente per accedere ai database cloud.';

  @override
  String get loggedOutSuccessfully => 'Disconnesso con successo';

  @override
  String get logs => 'Log';

  @override
  String get lossAbbreviation => 'P';

  @override
  String get matchDate => 'Data partita';

  @override
  String get maybeLater => 'Forse più tardi';

  @override
  String get mergeAllIntoFirst => 'Unisci tutto nel primo';

  @override
  String get mergeComplete => 'Unione completata';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthDec => 'Dic';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthJan => 'Gen';

  @override
  String get monthJul => 'Lug';

  @override
  String get monthJun => 'Giu';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthMay => 'Mag';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthOct => 'Ott';

  @override
  String get monthSep => 'Set';

  @override
  String get multipleCardStyles => 'Stili di carte multipli';

  @override
  String get multipleFiles => 'File multipli:';

  @override
  String get newDatabase => 'Nuovo database';

  @override
  String get newEvent => 'Nuovo evento';

  @override
  String get newPlayer => 'Nuovo giocatore';

  @override
  String get newSeason => 'Nuova stagione';

  @override
  String get newTeam => 'Nuova squadra';

  @override
  String get nextGamePrefix => 'Prossima partita:';

  @override
  String get nextGameStayTuned =>
      'Resta sintonizzato per il link live quando inizia';

  @override
  String get noAdminsYet => 'Nessun amministratore ancora';

  @override
  String get noAwardsAvailable => 'Nessun riconoscimento disponibile';

  @override
  String get noCloudDatabasesFound => 'Nessun database cloud trovato';

  @override
  String get noData => 'Nessun dato';

  @override
  String get noDataAvailable => 'Nessun dato disponibile';

  @override
  String get noDatabaseFoundMessage =>
      'Per iniziare, dovrai creare un nuovo database o aprirne uno esistente. Vuoi configurare il tuo database ora?';

  @override
  String get noDuplicatesToMerge => 'Nessun duplicato da unire';

  @override
  String get noEmail => 'Nessuna email';

  @override
  String get noGameAvailableToSetLiveLink =>
      'Nessuna partita disponibile per impostare il link live';

  @override
  String get noGameAvailableToTweetAbout =>
      'Nessuna partita disponibile per twittare';

  @override
  String get noGamesFound => 'Nessuna partita trovata';

  @override
  String get noHighlightsAvailable => 'Nessun highlight disponibile';

  @override
  String get noLogsYet => 'Nessun log ancora.';

  @override
  String get noPlayersFound => 'Nessun giocatore trovato';

  @override
  String get noSeasonsFound => 'Nessuna stagione trovata';

  @override
  String get noStatsAvailable => 'Nessuna statistica disponibile';

  @override
  String get noTeamDataAvailable => 'Nessun dato squadra disponibile';

  @override
  String get noTeamFound => 'Nessuna squadra trovata';

  @override
  String get noTeamSelected => 'Nessuna squadra selezionata';

  @override
  String get notAnAdministrator => 'Non un amministratore';

  @override
  String get notSignedIn => 'Non connesso';

  @override
  String get offside => 'Fuorigioco';

  @override
  String get openDatabase => 'Apri database';

  @override
  String get openExistingDatabase => 'Open Existing Database';

  @override
  String get openExistingCloudDatabase => 'Apri database cloud esistente';

  @override
  String get openFromBackup => 'Apri da backup';

  @override
  String openedDatabase(Object name) {
    return 'Database aperto: $name';
  }

  @override
  String get optionalDetails => 'Dettagli opzionali';

  @override
  String get optionalExternalLink => 'Link esterno opzionale';

  @override
  String get other => 'Altro';

  @override
  String get overall => 'Totale';

  @override
  String get overview => 'Panoramica';

  @override
  String get password => 'Password';

  @override
  String get pickAColor => 'Scegli un colore';

  @override
  String get pickTeamColors => 'Scegli colori squadra';

  @override
  String get pinLabel => 'PIN';

  @override
  String get playerName => 'Nome giocatore';

  @override
  String get playerNotFound => 'Giocatore non trovato';

  @override
  String get playerNumber => 'Numero giocatore';

  @override
  String get playerProfilesProFeature =>
      'I profili giocatore fanno parte della versione Pro. Effettua l\'upgrade per accedere alle statistiche dettagliate e alla cronologia di carriera.';

  @override
  String get players => 'Giocatori';

  @override
  String get pleaseAddPlayersFirst =>
      'Aggiungi prima i giocatori alla stagione';

  @override
  String get pleaseCorrectFormErrors => 'Correggi gli errori nel modulo.';

  @override
  String get pleaseCreateOrOpenADatabase => 'Crea o apri un database';

  @override
  String get pleaseCreateSeasonFirst =>
      'Crea prima una stagione per generare una formazione';

  @override
  String get pleaseEnterEmailAddress => 'Inserisci un indirizzo email';

  @override
  String get pleaseSelectAll11Players => 'Seleziona tutti gli 11 giocatori';

  @override
  String get postGameResults => 'Pubblica risultati partita';

  @override
  String get postGameStats => 'Pubblica statistiche partita';

  @override
  String get postSeasonStats => 'Pubblica statistiche stagione';

  @override
  String get preparingShare => 'Preparazione...';

  @override
  String get preview => 'Anteprima';

  @override
  String get previousLineupRestored => 'Formazione precedente ripristinata';

  @override
  String get primaryColor => 'Colore primario';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Funzionalità Pro';

  @override
  String get proSubscriptionFeatures => 'FUNZIONALITÀ ABBONAMENTO PRO';

  @override
  String get profilePhoto => 'Foto profilo';

  @override
  String get profilePicture => 'Foto profilo';

  @override
  String get profileUpdated => 'Profilo aggiornato con successo';

  @override
  String get recentGames => 'Partite recenti';

  @override
  String get recentHighlights => 'Highlights recenti';

  @override
  String get recordHolders => 'Detentori di record';

  @override
  String get records => 'Record';

  @override
  String get redCards => 'Cartellini Rossi';

  @override
  String get remindMeLater => 'Ricordamelo più tardi';

  @override
  String get remove => 'Rimuovi';

  @override
  String get removeButton => 'Rimuovi';

  @override
  String get removeImage => 'Rimuovi immagine';

  @override
  String get retry => 'Riprova';

  @override
  String get revokeAccess => 'Revoca accesso';

  @override
  String rowNumber(Object number) {
    return 'Riga $number';
  }

  @override
  String get save => 'Salva';

  @override
  String get saves => 'Parate';

  @override
  String get scoringSummary => 'Riepilogo punteggi';

  @override
  String get season => 'Stagione';

  @override
  String get seasonName => 'Nome stagione';

  @override
  String get seasonNotFound => 'Stagione non trovata';

  @override
  String get seasonStats => 'Statistiche stagione';

  @override
  String get seasons => 'Stagioni';

  @override
  String get secondaryColor => 'Colore secondario';

  @override
  String get selectACloudDatabase => 'Seleziona un database cloud';

  @override
  String get selectADatabase => 'Seleziona un database';

  @override
  String get selectEventType => 'Seleziona tipo di evento';

  @override
  String get selectImageSource => 'Seleziona origine immagine';

  @override
  String get selectOpponent => 'Seleziona avversario';

  @override
  String get selectPeriod => 'Seleziona periodo';

  @override
  String get selectPlayer => 'Seleziona giocatore';

  @override
  String get sendTweet => 'Invia tweet';

  @override
  String get setGameTime => 'Imposta orario partita';

  @override
  String get setLiveLink => 'Imposta link live';

  @override
  String get setLiveStreamLink => 'Imposta link streaming live';

  @override
  String get setTeamColors => 'Imposta colori squadra';

  @override
  String get setTime => 'Imposta orario';

  @override
  String get settings => 'Impostazioni';

  @override
  String get shareDatabase => 'Condividi database';

  @override
  String get shareImage => 'Condividi immagine';

  @override
  String get shareToSocialMedia => 'Condividi sui social media';

  @override
  String get sharedSuccessfully => 'Condiviso con successo!';

  @override
  String get shots => 'Tiri';

  @override
  String get shotsOnGoal => 'Tiri in porta';

  @override
  String get showHighlights => 'Mostra highlights';

  @override
  String get signIn => 'Accedi';

  @override
  String signInFailed(Object error) {
    return 'Accesso fallito: $error';
  }

  @override
  String get signInRequired => 'Accesso richiesto';

  @override
  String get signInToAccessCloudDatabases =>
      'Accedi per accedere ai database cloud';

  @override
  String get signInWithApple => 'Accedi con Apple';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String get signOut => 'Disconnetti';

  @override
  String signedInWith(Object provider) {
    return 'Accesso effettuato con $provider';
  }

  @override
  String get skip => 'Salta';

  @override
  String get soccerAnalytics => 'Analisi Calcio';

  @override
  String get startImport => 'Avvia importazione';

  @override
  String get systemDefaultLanguage => 'Predefinito di sistema';

  @override
  String get systemDefaultTheme => 'Predefinito di sistema';

  @override
  String get team => 'Squadra';

  @override
  String get teamAccomplishments => 'Risultati della squadra';

  @override
  String get teamId => 'ID squadra';

  @override
  String get teamName => 'Nome squadra';

  @override
  String get teamShortName => 'Nome breve squadra';

  @override
  String get teamStandings => 'Classifica squadre';

  @override
  String get teamSummary => 'Informazioni sulla squadra';

  @override
  String get editTeamSummary => 'Modifica riepilogo squadra';

  @override
  String get teamSummaryHint =>
      'Inserisci una breve descrizione della tua squadra...';

  @override
  String get teamSummarySaved => 'Riepilogo squadra salvato con successo';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer => 'Visualizzatore database TeamSync';

  @override
  String get teamSyncViewer => 'Visualizzatore TeamSync';

  @override
  String get termsOfUse => 'Termini di utilizzo';

  @override
  String get themeClassic => 'Classico';

  @override
  String get themeDarkMode => 'Modalità scura';

  @override
  String get themeElegant => 'Elegante';

  @override
  String get themeMinimal => 'Minimale';

  @override
  String get themeNeon => 'Neon';

  @override
  String get themeRetro => 'Retrò';

  @override
  String get thisWillMergeFollowingPlayers =>
      'Questo unirà i seguenti giocatori:';

  @override
  String get tieAbbreviation => 'P';

  @override
  String get time => 'Ora';

  @override
  String get titleUrlRequired => 'Titolo e URL sono obbligatori';

  @override
  String get tweetGameDay => 'Twitta giorno partita';

  @override
  String get tweetSentSuccessfully => 'Tweet inviato con successo!';

  @override
  String get tweetedSuccessfully => 'Twittato con successo!';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Impostazioni Twitter';

  @override
  String get twitterSettingsSavedSuccessfully =>
      'Impostazioni Twitter salvate con successo!';

  @override
  String get unableToOpenLink => 'Impossibile aprire il link';

  @override
  String get unableToOpenLiveLink => 'Impossibile aprire il link live';

  @override
  String get unexpectedDatabaseFormat => 'Formato database inaspettato';

  @override
  String get unlockButton => 'Sblocca';

  @override
  String get update => 'Aggiorna';

  @override
  String get updateButton => 'Aggiorna';

  @override
  String get upgradeToPro => 'Passa a Pro';

  @override
  String get uploadImage => 'Carica immagine';

  @override
  String get uploadingImage => 'Caricamento immagine...';

  @override
  String get addLogo => 'Aggiungi logo';

  @override
  String get changeLogo => 'Cambia logo';

  @override
  String get removeLogo => 'Rimuovi logo';

  @override
  String get confirmRemoveLogo => 'Sei sicuro di voler rimuovere questo logo?';

  @override
  String get logoUpdated => 'Logo aggiornato con successo';

  @override
  String get logoRemoved => 'Logo rimosso con successo';

  @override
  String get useDeviceLanguage => 'Usa lingua del dispositivo';

  @override
  String get userEmail => 'Email utente';

  @override
  String get validateOnly => 'Solo convalida';

  @override
  String get videoLabel => 'Video';

  @override
  String get viewMore => 'Vedi altro';

  @override
  String get watchLabel => 'Guarda';

  @override
  String get welcomeToTeamSync => 'Benvenuto su TeamSync!';

  @override
  String get winAbbreviation => 'V';

  @override
  String get year => 'Anno';

  @override
  String get yellowCards => 'Cartellini Gialli';

  @override
  String get noGamesYet => 'Nessuna partita ancora';

  @override
  String get live => 'LIVE';

  @override
  String get win => 'VITTORIA';

  @override
  String get loss => 'SCONFITTA';

  @override
  String get tie => 'PAREGGIO';

  @override
  String get teamPerformance => 'Prestazioni della squadra';

  @override
  String teamPerformanceSince(Object year) {
    return 'Prestazioni della squadra (Dal $year)';
  }

  @override
  String get addAccomplishment => 'Aggiungi risultato';

  @override
  String get editAccomplishment => 'Modifica risultato';

  @override
  String get titleRequired => 'Titolo *';

  @override
  String get titleIsRequired => 'Il titolo è obbligatorio';

  @override
  String get exampleStateChampions => 'es. Campioni statali';

  @override
  String get exampleYear => 'es. 2023';

  @override
  String get saving => 'Salvataggio...';

  @override
  String get since => 'Dal';

  @override
  String get images => 'Immagini';

  @override
  String get tapImageToPrimary => 'Tocca un\'immagine per renderla principale';

  @override
  String get selectMultipleImages =>
      'Puoi selezionare più immagini contemporaneamente';

  @override
  String get primary => 'Principale';

  @override
  String get notAuthorizedUploadImages =>
      'Non autorizzato a caricare immagini. Accedi da mobile per aggiungere immagini.';

  @override
  String get games => 'Partite';

  @override
  String gameTimeSet(Object time) {
    return 'Orario della partita impostato su $time';
  }

  @override
  String get noTimeSetPrompt =>
      'Questa partita non ha un orario impostato (attualmente 00:00). Vuoi impostare l\'orario prima di twittare?';

  @override
  String get sortByTeamName => 'Nome squadra';

  @override
  String get sortByMostGames => 'Più partite';

  @override
  String get sortByMostWins => 'Più vittorie';

  @override
  String get sortByWinPercentage => '% Vittoria';

  @override
  String get sortByRecent => 'Recente';

  @override
  String get noMatchupHistoryYet => 'Nessuno storico degli scontri ancora';

  @override
  String get gamesSingular => 'partita';

  @override
  String get gamesPlural => 'partite';

  @override
  String gamesPlayed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'partite',
      one: 'partita',
    );
    return '$count $_temp0 giocate';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get editSeasonName => 'Modifica nome stagione';

  @override
  String get seasonNameRequired => 'Il nome della stagione è obbligatorio';

  @override
  String get seasonNameUpdated => 'Nome della stagione aggiornato con successo';

  @override
  String get analytics => 'Analitica';

  @override
  String get avgGoalsFor => 'Media Gol Fatti';

  @override
  String get avgGoalsAgainst => 'Media Gol Subiti';

  @override
  String get biggestWin => 'Vittoria Più Grande';

  @override
  String get biggestLoss => 'Sconfitta Più Grande';

  @override
  String get currentStreak => 'Serie Attuale';

  @override
  String get longestWinStreak => 'Serie di Vittorie Più Lunga';

  @override
  String get recentForm => 'Forma Recente (Ultime 5)';

  @override
  String get cleanSheets => 'Porta Inviolata';

  @override
  String get goalDifferential => 'Differenza Reti';

  @override
  String get homeRecord => 'Record in Casa';

  @override
  String get awayRecord => 'Record in Trasferta';

  @override
  String get pointsPerGame => 'Punti per Partita';

  @override
  String get shootingAccuracy => 'Precisione di Tiro';

  @override
  String get comebackWins => 'Vittorie in Rimonta';

  @override
  String get lateGoals => 'Gol Tardivi (80+)';

  @override
  String get cardsPerGame => 'Cartellini per Partita';

  @override
  String get statistics => 'Statistiche';

  @override
  String get scoringEvents => 'Eventi di Gol';

  @override
  String get noScoringEventsYet => 'Nessun evento di gol ancora';

  @override
  String get gameStatistics => 'Statistiche della Partita';

  @override
  String get shotsOnTarget => 'Tiri in Porta';

  @override
  String get goalAnalytics => 'Analisi Gol';

  @override
  String get totalGoalsScored => 'Totale Gol Segnati';

  @override
  String get totalGoalsConceded => 'Totale Gol Subiti';

  @override
  String get avgGoalsPerGame => 'Media Gol Per Partita';

  @override
  String get streaksRecords => 'Serie e Record';

  @override
  String get longestUnbeatenStreak => 'Più Lunga Serie Imbattuto';

  @override
  String get mostGoalsInGame => 'Più Gol in una Partita';

  @override
  String get biggestVictory => 'Vittoria Più Grande';

  @override
  String get homeAwayAnalysis => 'Casa vs Trasferta';

  @override
  String get homeWinPercentage => '% Vittorie Casa';

  @override
  String get awayWinPercentage => '% Vittorie Trasferta';

  @override
  String get defensiveStats => 'Statistiche Difensive';

  @override
  String get cleanSheetPercentage => '% Porta Inviolata';

  @override
  String get avgGoalsConceded => 'Media Gol Subiti';

  @override
  String get shutoutsRecorded => 'Porte Inviolate Registrate';

  @override
  String get allTime => 'Tutti i Tempi';

  @override
  String get currentSeason => 'Stagione Corrente';

  @override
  String get lastSeason => 'Ultima Stagione';

  @override
  String get last3Years => 'Ultime 3 Stagioni';

  @override
  String get last5Years => 'Ultime 5 Stagioni';

  @override
  String get last10Years => 'Ultime 10 Stagioni';

  @override
  String get overallStatistics => 'Statistiche Generali';

  @override
  String get recordSummary => 'Riepilogo Record';

  @override
  String get totalGames => 'Totale Partite';

  @override
  String get wins => 'Vittorie';

  @override
  String get losses => 'Sconfitte';

  @override
  String get ties => 'Pareggi';

  @override
  String get winPercentage => '% Vittorie';

  @override
  String get playerProfileQRCode => 'Codice QR del Profilo Giocatore';

  @override
  String get scanQRCodeToViewProfile =>
      'Scansiona il codice QR per visualizzare il profilo di questo giocatore';

  @override
  String get tapToEnlarge => 'Tocca per ingrandire';

  @override
  String playerProfileLink(Object playerName) {
    return 'Profilo Giocatore: $playerName';
  }

  @override
  String get errorSharingLink => 'Errore nella condivisione del link';

  @override
  String get share => 'Condividi';

  @override
  String get sending => 'Sending...';

  @override
  String get twitterNotConfigured =>
      'Twitter is not configured. Please configure Twitter in Settings.';

  @override
  String get opponents => 'Avversari';

  @override
  String get addGame => 'Add Game';

  @override
  String get opponent => 'Opponent';

  @override
  String get date => 'Date';

  @override
  String get timeOptional => 'Time (optional)';
}
