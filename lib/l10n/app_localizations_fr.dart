// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get email => 'E-mail';

  @override
  String get description => 'Description';

  @override
  String accessGrantedTo(Object email) {
    return 'Accès accordé à $email';
  }

  @override
  String get accomplishmentDeleted => 'Réalisation supprimée';

  @override
  String get accomplishmentsReordered => 'Réalisations réordonnées';

  @override
  String get account => 'Compte';

  @override
  String get actionPhoto => 'Photo d\'action';

  @override
  String get actionPhotoCards => 'Cartes photo d\'action';

  @override
  String get add => 'Ajouter';

  @override
  String get addAssistQuestion => 'Ajouter une assistance ?';

  @override
  String get addAward => 'Ajouter une récompense';

  @override
  String get addAwardDialogTitle => 'Ajouter une récompense';

  @override
  String get addButton => 'Ajouter';

  @override
  String get addHighlight => 'Ajouter un moment fort';

  @override
  String get addHighlightDialogTitle => 'Ajouter un moment fort';

  @override
  String get addLink => 'Ajouter un lien';

  @override
  String get adminAddedSuccessfully => 'Administrateur ajouté avec succès';

  @override
  String get adminRemovedSuccessfully => 'Administrateur supprimé avec succès';

  @override
  String get advanceGame => 'Avancer le match';

  @override
  String get allowPlayerEditProfile =>
      'Autoriser le joueur à modifier son profil sur le web';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Apparence';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Êtes-vous sûr de vouloir supprimer cet événement ? Cette action ne peut pas être annulée.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Êtes-vous sûr de vouloir supprimer ce match ? Toutes les données associées à ce match seront supprimées. Cette action ne peut pas être annulée.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Êtes-vous sûr de vouloir supprimer ce joueur ? Toutes les données associées à ce joueur seront supprimées. Cette action ne peut pas être annulée.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Êtes-vous sûr de vouloir supprimer cette saison ? Toutes les données associées à cette saison seront supprimées. Cette action ne peut pas être annulée.';

  @override
  String get assistedBy => 'Assisté par';

  @override
  String get assists => 'Passes décisives';

  @override
  String get automaticTheme => 'Thème automatique';

  @override
  String get automaticThemeSwitchDescription =>
      'Changer automatiquement le thème selon l\'heure de la journée';

  @override
  String get awardDeleted => 'Récompense supprimée';

  @override
  String get awardSaved => 'Récompense enregistrée avec succès';

  @override
  String get awards => 'Récompenses';

  @override
  String get away => 'EXTÉRIEUR';

  @override
  String get backupDatabase =>
      'Sauvegarder la base de données actuelle sur l\'appareil';

  @override
  String get bestGame => 'Meilleur match';

  @override
  String get bestSeason => 'Meilleure saison';

  @override
  String get calculating => 'Calcul en cours...';

  @override
  String get camera => 'Appareil photo';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get career => 'Carrière';

  @override
  String get careerLeaders => 'Meilleurs de carrière';

  @override
  String get careerStatsTitle => 'Statistiques de carrière';

  @override
  String get changeImage => 'Changer l\'image';

  @override
  String get changeTeamColors => 'Changer les couleurs de l\'équipe';

  @override
  String get clearLogs => 'Effacer les journaux';

  @override
  String get close => 'Fermer';

  @override
  String get closeSidebar => 'Fermer la barre latérale';

  @override
  String get composeTweet => 'Composer un tweet';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get connectToTwitter => 'Se connecter à Twitter';

  @override
  String get continueButton => 'Continuer';

  @override
  String get continueText => 'Continuer';

  @override
  String get continueWithoutSigningIn => 'Continuer sans se connecter';

  @override
  String get convertToCloud => 'Convertir en base de données cloud';

  @override
  String get corners => 'Corners';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Impossible d\'ouvrir l\'URL : $url';
  }

  @override
  String get create => 'Créer';

  @override
  String get createAnyway => 'Créer quand même';

  @override
  String get createNewCloudDatabase =>
      'Créer une nouvelle base de données cloud';

  @override
  String get createNewDatabase => 'Créer une nouvelle base de données';

  @override
  String get createNewGameToStart => 'Créez un nouveau match pour commencer';

  @override
  String get createNewOpponent => 'Créer un nouvel adversaire';

  @override
  String get createNewSeason => 'Créer une nouvelle saison';

  @override
  String get createNewSeasonToStart =>
      'Créez une nouvelle saison pour commencer';

  @override
  String get createNewTeam => 'Créer une nouvelle équipe';

  @override
  String get createNewTeamToStart => 'Créez une nouvelle équipe pour commencer';

  @override
  String get createTeam => 'Créer une équipe';

  @override
  String get creator => 'Créateur';

  @override
  String get currently => 'Actuellement';

  @override
  String get dataImport => 'Importation de données';

  @override
  String get databaseAlreadyExists =>
      'Une base de données cloud avec ce nom existe déjà.';

  @override
  String get databaseImportInProgress =>
      'L\'importation de la base de données est toujours en cours...';

  @override
  String get databaseImported => 'Base de données importée avec succès !';

  @override
  String get databaseName => 'Nom de la base de données';

  @override
  String get databaseNotFound => 'Base de données non trouvée';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Débogage : Migration Firestore → Realtime';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAccomplishment => 'Supprimer la réalisation';

  @override
  String get deleteAccomplishmentConfirmation =>
      'Êtes-vous sûr de vouloir supprimer cette réalisation ?';

  @override
  String deleteAwardConfirm(Object title) {
    return 'Êtes-vous sûr de vouloir supprimer « $title » ?';
  }

  @override
  String get deleteAwardTitle => 'Supprimer la récompense';

  @override
  String deleteHighlightConfirm(Object title) {
    return 'Êtes-vous sûr de vouloir supprimer « $title » ?';
  }

  @override
  String get deleteHighlightTitle => 'Supprimer le moment fort';

  @override
  String get displayOrder => 'Ordre d\'affichage';

  @override
  String get downloadErrorReport => 'Télécharger le rapport d\'erreurs';

  @override
  String get downloadTemplate => 'Télécharger le modèle';

  @override
  String get duplicatePlayerName => 'Nom de joueur en double';

  @override
  String durationSeconds(Object seconds) {
    return 'Durée : $seconds secondes';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get editAward => 'Modifier la récompense';

  @override
  String get editGame => 'Modifier le match';

  @override
  String get editHighlight => 'Modifier le moment fort';

  @override
  String get editPlayer => 'Modifier le joueur';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get endGame => 'Terminer le match';

  @override
  String get endOfGame => 'Fin du match';

  @override
  String get endOfRegulation => 'Fin du temps réglementaire';

  @override
  String get enterEmailToAddAdmin =>
      'Entrez l\'e-mail pour ajouter comme administrateur';

  @override
  String get enterFourDigitPin => 'Entrez un code PIN à 4 chiffres';

  @override
  String get enterPinToEdit => 'Entrez le code PIN pour modifier le profil';

  @override
  String get enterTeamIdPrompt =>
      'Entrez un ID d\'équipe à 6 chiffres pour voir les statistiques :';

  @override
  String get entityType => 'Type d\'entité';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Erreur lors de la suppression de la réalisation : $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Erreur lors de la suppression de la récompense : $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Erreur lors de la suppression du moment fort : $error';
  }

  @override
  String get errorDuringShare => 'Erreur lors du partage, veuillez réessayer';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Erreur lors de la génération de la composition : $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Erreur lors du chargement de la liste d\'accès : $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Erreur lors du chargement des récompenses : $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Erreur lors du chargement des identifiants : $error';
  }

  @override
  String get errorLoadingDatabase =>
      'Erreur lors du chargement de la base de données.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Erreur lors du chargement des doublons : $error';
  }

  @override
  String get errorLoadingEvents => 'Erreur lors du chargement des événements';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Erreur lors du chargement des moments forts : $error';
  }

  @override
  String get errorLoadingHistory =>
      'Erreur lors du chargement de l\'historique';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Erreur lors du chargement des statistiques du joueur : $error\n\nTrace de pile : $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Erreur lors du chargement des bases de données partagées : $error';
  }

  @override
  String get errorLoadingStats => 'Erreur lors du chargement des statistiques';

  @override
  String errorLoggingOut(Object error) {
    return 'Erreur lors de la déconnexion : $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Erreur : $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Erreur lors de l\'ouverture du lien : $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Erreur lors du réordonnancement : $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Erreur lors de l\'enregistrement : $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Erreur lors de l\'enregistrement de la récompense : $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Erreur lors de l\'enregistrement du moment fort : $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Erreur lors de l\'enregistrement des paramètres : $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Erreur lors de l\'envoi du tweet : $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Erreur lors du partage de l\'image : $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Erreur lors du partage sur Twitter : $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Erreur lors de la mise à jour de l\'heure du match : $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Erreur lors de la mise à jour du profil : $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Erreur lors du téléchargement des images : $error';
  }

  @override
  String get exitEditMode => 'Quitter le mode édition';

  @override
  String get failedToGrantAccess =>
      'Échec de l\'octroi de l\'accès. L\'utilisateur n\'existe peut-être pas.';

  @override
  String get failedToOpenDatabase =>
      'Échec de l\'ouverture de la base de données';

  @override
  String get failedToSendTweet =>
      'Échec de l\'envoi du tweet. Veuillez réessayer.';

  @override
  String get finalOT => 'Final AP';

  @override
  String get finalOTText => 'Final AP';

  @override
  String get finalPKs => 'Final TAB';

  @override
  String get finalPKsText => 'Final TAB';

  @override
  String get finalText => 'Final';

  @override
  String get firestoreDocumentPath => 'Chemin du document Firestore';

  @override
  String get formation => 'Formation';

  @override
  String get fouls => 'Fautes';

  @override
  String get gallery => 'Galerie';

  @override
  String get game => 'Match';

  @override
  String get gameDayTweetSentSuccessfully =>
      'Tweet du jour du match envoyé avec succès ! 🎉';

  @override
  String get gameStats => 'Statistiques du match';

  @override
  String get generate => 'Générer';

  @override
  String get generateImage => 'Générer l\'image';

  @override
  String get generateLineup => 'Générer la composition';

  @override
  String get generateLineupImage => 'Générer l\'image de composition';

  @override
  String get generateNewMessage => 'Générer un nouveau message';

  @override
  String get getStarted => 'Commencer';

  @override
  String get goBack => 'Retour';

  @override
  String get goPro => 'Passer à Pro';

  @override
  String get goToGame => 'Aller au match';

  @override
  String get goalCelebrationPosts => 'Publications de célébration de but';

  @override
  String get goals => 'Buts';

  @override
  String get gotIt => 'Compris';

  @override
  String get hideHighlights => 'Masquer les moments forts';

  @override
  String get highlightDeleted => 'Moment fort supprimé';

  @override
  String get highlightSaved => 'Moment fort enregistré avec succès';

  @override
  String get highlights => 'Moments forts';

  @override
  String get hintAwardTitle => 'par ex., MVP, All-Star, Meilleur buteur';

  @override
  String get hintDescriptionOptional => 'Description facultative';

  @override
  String get hintTitleExample => 'par ex., But gagnant';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Analytique';

  @override
  String get historyVersus => 'Analytique';

  @override
  String get home => 'DOMICILE';

  @override
  String get importSeason => 'Importer la saison';

  @override
  String get importTeamsPlayersGamesStats =>
      'Importer équipes, joueurs, matchs et statistiques';

  @override
  String get importingDatabase => 'Importation de la base de données...';

  @override
  String get invalidPin => 'Le code PIN doit comporter 4 chiffres';

  @override
  String get labelAwardImage => 'Image de la récompense (facultative)';

  @override
  String get labelAwardTitle => 'Titre de la récompense *';

  @override
  String get labelDate => 'Date';

  @override
  String get labelDescription => 'Description';

  @override
  String get labelTitleRequired => 'Titre *';

  @override
  String get labelVideoUrlRequired => 'URL de la vidéo *';

  @override
  String get language => 'Langue';

  @override
  String get leaders => 'Leaders';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get lineupGeneratorMobileOnly =>
      'Le générateur de composition n\'est disponible que sur les appareils mobiles';

  @override
  String get lineupSharedSuccessfully => 'Composition partagée avec succès !';

  @override
  String get lineupTweetedSuccessfully =>
      'Composition tweetée avec succès ! 🎉';

  @override
  String get linkURL => 'URL du lien';

  @override
  String get liveBannerTapToWatch =>
      'EN DIRECT — Appuyez pour regarder le stream';

  @override
  String get liveUrlLabel => 'URL en direct';

  @override
  String get loadTeam => 'Charger l\'équipe';

  @override
  String get loading => 'Chargement...';

  @override
  String get loadingAllSeasons => 'Chargement de toutes les saisons...';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get logOutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ? Vous devrez vous reconnecter pour accéder aux bases de données cloud.';

  @override
  String get loggedOutSuccessfully => 'Déconnecté avec succès';

  @override
  String get logs => 'Journaux';

  @override
  String get lossAbbreviation => 'D';

  @override
  String get matchDate => 'Date du match';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get mergeAllIntoFirst => 'Tout fusionner dans le premier';

  @override
  String get mergeComplete => 'Fusion terminée';

  @override
  String get monthApr => 'Avr';

  @override
  String get monthAug => 'Aoû';

  @override
  String get monthDec => 'Déc';

  @override
  String get monthFeb => 'Fév';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthSep => 'Sep';

  @override
  String get multipleCardStyles => 'Plusieurs styles de cartes';

  @override
  String get multipleFiles => 'Fichiers multiples :';

  @override
  String get newDatabase => 'Nouvelle base de données';

  @override
  String get newEvent => 'Nouvel événement';

  @override
  String get newPlayer => 'Nouveau joueur';

  @override
  String get newSeason => 'Nouvelle saison';

  @override
  String get newTeam => 'Nouvelle équipe';

  @override
  String get nextGamePrefix => 'Prochain match :';

  @override
  String get nextGameStayTuned =>
      'Restez à l\'écoute pour le lien en direct une fois qu\'il commence';

  @override
  String get noAdminsYet => 'Pas encore d\'administrateurs';

  @override
  String get noAwardsAvailable => 'Aucune récompense disponible';

  @override
  String get noCloudDatabasesFound => 'Aucune base de données cloud trouvée';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get noDatabaseFoundMessage =>
      'Pour commencer, vous devrez créer une nouvelle base de données ou ouvrir une base de données existante. Voulez-vous configurer votre base de données maintenant ?';

  @override
  String get noDuplicatesToMerge => 'Aucun doublon à fusionner';

  @override
  String get noEmail => 'Aucun e-mail';

  @override
  String get noGameAvailableToSetLiveLink =>
      'Aucun match disponible pour définir le lien en direct';

  @override
  String get noGameAvailableToTweetAbout =>
      'Aucun match disponible pour tweeter';

  @override
  String get noGamesFound => 'Aucun match trouvé';

  @override
  String get noHighlightsAvailable => 'Aucun moment fort disponible';

  @override
  String get noLogsYet => 'Aucun journal pour le moment.';

  @override
  String get noPlayersFound => 'Aucun joueur trouvé';

  @override
  String get noSeasonsFound => 'Aucune saison trouvée';

  @override
  String get noStatsAvailable => 'Aucune statistique disponible';

  @override
  String get noTeamDataAvailable => 'Aucune donnée d\'équipe disponible';

  @override
  String get noTeamFound => 'Aucune équipe trouvée';

  @override
  String get noTeamSelected => 'Aucune équipe sélectionnée';

  @override
  String get notAnAdministrator => 'Pas un administrateur';

  @override
  String get notSignedIn => 'Non connecté';

  @override
  String get offside => 'Hors-jeu';

  @override
  String get openDatabase => 'Ouvrir une base de données';

  @override
  String get openExistingDatabase => 'Open Existing Database';

  @override
  String get openExistingCloudDatabase =>
      'Ouvrir une base de données cloud existante';

  @override
  String get openFromBackup => 'Ouvrir depuis une sauvegarde';

  @override
  String openedDatabase(Object name) {
    return 'Base de données ouverte : $name';
  }

  @override
  String get optionalDetails => 'Détails facultatifs';

  @override
  String get optionalExternalLink => 'Lien externe facultatif';

  @override
  String get other => 'Autre';

  @override
  String get overall => 'Global';

  @override
  String get overview => 'Aperçu';

  @override
  String get password => 'Mot de passe';

  @override
  String get pickAColor => 'Choisir une couleur';

  @override
  String get pickTeamColors => 'Choisir les couleurs de l\'équipe';

  @override
  String get pinLabel => 'Code PIN';

  @override
  String get playerName => 'Nom du joueur';

  @override
  String get playerNotFound => 'Joueur non trouvé';

  @override
  String get playerNumber => 'Numéro du joueur';

  @override
  String get playerProfilesProFeature =>
      'Les profils des joueurs font partie de la version Pro. Mettez à niveau pour accéder aux statistiques détaillées et à l\'historique de carrière.';

  @override
  String get players => 'Joueurs';

  @override
  String get pleaseAddPlayersFirst =>
      'Veuillez d\'abord ajouter des joueurs à la saison';

  @override
  String get pleaseCorrectFormErrors =>
      'Veuillez corriger les erreurs dans le formulaire.';

  @override
  String get pleaseCreateOrOpenADatabase =>
      'Veuillez créer ou ouvrir une base de données';

  @override
  String get pleaseCreateSeasonFirst =>
      'Veuillez d\'abord créer une saison pour générer une composition';

  @override
  String get pleaseEnterEmailAddress => 'Veuillez entrer une adresse e-mail';

  @override
  String get pleaseSelectAll11Players => 'Veuillez sélectionner les 11 joueurs';

  @override
  String get postGameResults => 'Publier les résultats du match';

  @override
  String get postGameStats => 'Publier les statistiques du match';

  @override
  String get postSeasonStats => 'Publier les statistiques de la saison';

  @override
  String get preparingShare => 'Préparation...';

  @override
  String get preview => 'Aperçu';

  @override
  String get previousLineupRestored => 'Composition précédente restaurée';

  @override
  String get primaryColor => 'Couleur principale';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Fonction Pro';

  @override
  String get proSubscriptionFeatures => 'FONCTIONNALITÉS D\'ABONNEMENT PRO';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get profilePicture => 'Photo de profil';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String get recentGames => 'Matchs récents';

  @override
  String get recentHighlights => 'Moments forts récents';

  @override
  String get recordHolders => 'Détenteurs de records';

  @override
  String get records => 'Records';

  @override
  String get redCards => 'Cartons Rouges';

  @override
  String get remindMeLater => 'Me le rappeler plus tard';

  @override
  String get remove => 'Supprimer';

  @override
  String get removeButton => 'Supprimer';

  @override
  String get removeImage => 'Supprimer l\'image';

  @override
  String get retry => 'Réessayer';

  @override
  String get revokeAccess => 'Révoquer l\'accès';

  @override
  String rowNumber(Object number) {
    return 'Ligne $number';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get saves => 'Arrêts';

  @override
  String get scoringSummary => 'Résumé des scores';

  @override
  String get season => 'Saison';

  @override
  String get seasonName => 'Nom de la saison';

  @override
  String get seasonNotFound => 'Saison non trouvée';

  @override
  String get seasonStats => 'Statistiques de la saison';

  @override
  String get seasons => 'Saisons';

  @override
  String get secondaryColor => 'Couleur secondaire';

  @override
  String get selectACloudDatabase => 'Sélectionner une base de données cloud';

  @override
  String get selectADatabase => 'Sélectionner une base de données';

  @override
  String get selectEventType => 'Sélectionner le type d\'événement';

  @override
  String get selectImageSource => 'Sélectionner la source de l\'image';

  @override
  String get selectOpponent => 'Sélectionner un adversaire';

  @override
  String get selectPeriod => 'Sélectionner la période';

  @override
  String get selectPlayer => 'Sélectionner un joueur';

  @override
  String get sendTweet => 'Envoyer un tweet';

  @override
  String get setGameTime => 'Définir l\'heure du match';

  @override
  String get setLiveLink => 'Définir le lien en direct';

  @override
  String get setLiveStreamLink => 'Définir le lien de diffusion en direct';

  @override
  String get setTeamColors => 'Définir les couleurs de l\'équipe';

  @override
  String get setTime => 'Définir l\'heure';

  @override
  String get settings => 'Paramètres';

  @override
  String get shareDatabase => 'Partager la base de données';

  @override
  String get shareImage => 'Partager l\'image';

  @override
  String get shareToSocialMedia => 'Partager sur les réseaux sociaux';

  @override
  String get sharedSuccessfully => 'Partagé avec succès !';

  @override
  String get shots => 'Tirs';

  @override
  String get shotsOnGoal => 'Tirs cadrés';

  @override
  String get showHighlights => 'Afficher les moments forts';

  @override
  String get signIn => 'Se connecter';

  @override
  String signInFailed(Object error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get signInRequired => 'Connexion requise';

  @override
  String get signInToAccessCloudDatabases =>
      'Connectez-vous pour accéder aux bases de données cloud';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String signedInWith(Object provider) {
    return 'Connecté avec $provider';
  }

  @override
  String get skip => 'Passer';

  @override
  String get soccerAnalytics => 'Analyses de Football';

  @override
  String get startImport => 'Démarrer l\'importation';

  @override
  String get systemDefaultLanguage => 'Par défaut du système';

  @override
  String get systemDefaultTheme => 'Par défaut du système';

  @override
  String get team => 'Équipe';

  @override
  String get teamAccomplishments => 'Réalisations de l\'équipe';

  @override
  String get teamId => 'ID d\'équipe';

  @override
  String get teamName => 'Nom de l\'équipe';

  @override
  String get teamShortName => 'Nom court de l\'équipe';

  @override
  String get teamStandings => 'Classement de l\'équipe';

  @override
  String get teamSummary => 'À propos de l\'équipe';

  @override
  String get editTeamSummary => 'Modifier le résumé de l\'équipe';

  @override
  String get teamSummaryHint =>
      'Entrez une brève description de votre équipe...';

  @override
  String get teamSummarySaved => 'Résumé de l\'équipe enregistré avec succès';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer =>
      'Visualiseur de base de données TeamSync';

  @override
  String get teamSyncViewer => 'Visionneur TeamSync';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get themeClassic => 'Classique';

  @override
  String get themeDarkMode => 'Mode sombre';

  @override
  String get themeElegant => 'Élégant';

  @override
  String get themeMinimal => 'Minimal';

  @override
  String get themeNeon => 'Néon';

  @override
  String get themeRetro => 'Rétro';

  @override
  String get thisWillMergeFollowingPlayers =>
      'Ceci fusionnera les joueurs suivants :';

  @override
  String get tieAbbreviation => 'N';

  @override
  String get time => 'Heure';

  @override
  String get titleUrlRequired => 'Le titre et l\'URL sont requis';

  @override
  String get tweetGameDay => 'Tweeter le jour du match';

  @override
  String get tweetSentSuccessfully => 'Tweet envoyé avec succès !';

  @override
  String get tweetedSuccessfully => 'Tweeté avec succès !';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Paramètres Twitter';

  @override
  String get twitterSettingsSavedSuccessfully =>
      'Paramètres Twitter enregistrés avec succès !';

  @override
  String get unableToOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get unableToOpenLiveLink => 'Impossible d\'ouvrir le lien en direct';

  @override
  String get unexpectedDatabaseFormat => 'Format de base de données inattendu';

  @override
  String get unlockButton => 'Déverrouiller';

  @override
  String get update => 'Mettre à jour';

  @override
  String get updateButton => 'Mettre à jour';

  @override
  String get upgradeToPro => 'Passer à Pro';

  @override
  String get uploadImage => 'Télécharger une image';

  @override
  String get uploadingImage => 'Téléchargement de l\'image...';

  @override
  String get addLogo => 'Ajouter un logo';

  @override
  String get changeLogo => 'Changer le logo';

  @override
  String get removeLogo => 'Supprimer le logo';

  @override
  String get confirmRemoveLogo =>
      'Êtes-vous sûr de vouloir supprimer ce logo ?';

  @override
  String get logoUpdated => 'Logo mis à jour avec succès';

  @override
  String get logoRemoved => 'Logo supprimé avec succès';

  @override
  String get useDeviceLanguage => 'Utiliser la langue de l\'appareil';

  @override
  String get userEmail => 'E-mail de l\'utilisateur';

  @override
  String get validateOnly => 'Valider uniquement';

  @override
  String get videoLabel => 'Vidéo';

  @override
  String get viewMore => 'Voir plus';

  @override
  String get watchLabel => 'Regarder';

  @override
  String get welcomeToTeamSync => 'Bienvenue sur TeamSync !';

  @override
  String get winAbbreviation => 'V';

  @override
  String get year => 'Année';

  @override
  String get yellowCards => 'Cartons Jaunes';

  @override
  String get noGamesYet => 'Pas encore de matchs';

  @override
  String get live => 'EN DIRECT';

  @override
  String get win => 'VICTOIRE';

  @override
  String get loss => 'DÉFAITE';

  @override
  String get tie => 'NUL';

  @override
  String get teamPerformance => 'Performance de l\'équipe';

  @override
  String teamPerformanceSince(Object year) {
    return 'Performance de l\'équipe (Depuis $year)';
  }

  @override
  String get addAccomplishment => 'Ajouter une réalisation';

  @override
  String get editAccomplishment => 'Modifier la réalisation';

  @override
  String get titleRequired => 'Titre *';

  @override
  String get titleIsRequired => 'Le titre est obligatoire';

  @override
  String get exampleStateChampions => 'par ex., Champions d\'État';

  @override
  String get exampleYear => 'par ex., 2023';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get since => 'Depuis';

  @override
  String get images => 'Images';

  @override
  String get tapImageToPrimary =>
      'Appuyez sur une image pour la définir comme principale';

  @override
  String get selectMultipleImages =>
      'Vous pouvez sélectionner plusieurs images à la fois';

  @override
  String get primary => 'Principale';

  @override
  String get notAuthorizedUploadImages =>
      'Non autorisé à télécharger des images. Connectez-vous sur mobile pour ajouter des images.';

  @override
  String get games => 'Matchs';

  @override
  String gameTimeSet(Object time) {
    return 'Heure du match définie à $time';
  }

  @override
  String get noTimeSetPrompt =>
      'Ce match n\'a pas d\'heure définie (actuellement 00:00). Voulez-vous définir l\'heure avant de tweeter?';

  @override
  String get sortByTeamName => 'Nom de l\'équipe';

  @override
  String get sortByMostGames => 'Plus de matchs';

  @override
  String get sortByMostWins => 'Plus de victoires';

  @override
  String get sortByWinPercentage => '% Victoire';

  @override
  String get sortByRecent => 'Récent';

  @override
  String get noMatchupHistoryYet =>
      'Pas encore d\'historique des confrontations';

  @override
  String get gamesSingular => 'match';

  @override
  String get gamesPlural => 'matchs';

  @override
  String gamesPlayed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'matchs',
      one: 'match',
    );
    return '$count $_temp0 joués';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Inconnu';

  @override
  String get editSeasonName => 'Modifier le nom de la saison';

  @override
  String get seasonNameRequired => 'Le nom de la saison est obligatoire';

  @override
  String get seasonNameUpdated => 'Nom de la saison mis à jour avec succès';

  @override
  String get analytics => 'Analytique';

  @override
  String get avgGoalsFor => 'Moy. Buts Pour';

  @override
  String get avgGoalsAgainst => 'Moy. Buts Contre';

  @override
  String get biggestWin => 'Plus Grande Victoire';

  @override
  String get biggestLoss => 'Plus Grande Défaite';

  @override
  String get currentStreak => 'Série Actuelle';

  @override
  String get longestWinStreak => 'Plus Longue Série de Victoires';

  @override
  String get recentForm => 'Forme Récente (5 Derniers)';

  @override
  String get cleanSheets => 'Cage Inviolée';

  @override
  String get goalDifferential => 'Différence de Buts';

  @override
  String get homeRecord => 'Bilan à Domicile';

  @override
  String get awayRecord => 'Bilan à l\'Extérieur';

  @override
  String get pointsPerGame => 'Points par Match';

  @override
  String get shootingAccuracy => 'Précision de Tir';

  @override
  String get comebackWins => 'Victoires Remontées';

  @override
  String get lateGoals => 'Buts Tardifs (80+)';

  @override
  String get cardsPerGame => 'Cartes par Match';

  @override
  String get statistics => 'Statistiques';

  @override
  String get scoringEvents => 'Événements de But';

  @override
  String get noScoringEventsYet => 'Pas encore d\'événements de but';

  @override
  String get gameStatistics => 'Statistiques du Match';

  @override
  String get shotsOnTarget => 'Tirs Cadrés';

  @override
  String get goalAnalytics => 'Analyse des Buts';

  @override
  String get totalGoalsScored => 'Total de Buts Marqués';

  @override
  String get totalGoalsConceded => 'Total de Buts Concédés';

  @override
  String get avgGoalsPerGame => 'Moyenne Buts Par Match';

  @override
  String get streaksRecords => 'Séries et Records';

  @override
  String get longestUnbeatenStreak => 'Plus Longue Série Invaincu';

  @override
  String get mostGoalsInGame => 'Plus de Buts en un Match';

  @override
  String get biggestVictory => 'Plus Grande Victoire';

  @override
  String get homeAwayAnalysis => 'Domicile vs Extérieur';

  @override
  String get homeWinPercentage => '% Victoires Domicile';

  @override
  String get awayWinPercentage => '% Victoires Extérieur';

  @override
  String get defensiveStats => 'Statistiques Défensives';

  @override
  String get cleanSheetPercentage => '% Cage Inviolée';

  @override
  String get avgGoalsConceded => 'Moyenne Buts Concédés';

  @override
  String get shutoutsRecorded => 'Cages Inviolées Enregistrées';

  @override
  String get allTime => 'Tous les Temps';

  @override
  String get currentSeason => 'Saison Actuelle';

  @override
  String get lastSeason => 'Dernière Saison';

  @override
  String get last3Years => '3 Dernières Saisons';

  @override
  String get last5Years => '5 Dernières Saisons';

  @override
  String get last10Years => '10 Dernières Saisons';

  @override
  String get overallStatistics => 'Statistiques Générales';

  @override
  String get recordSummary => 'Résumé des Records';

  @override
  String get totalGames => 'Total des Matchs';

  @override
  String get wins => 'Victoires';

  @override
  String get losses => 'Défaites';

  @override
  String get ties => 'Nuls';

  @override
  String get winPercentage => '% Victoires';

  @override
  String get playerProfileQRCode => 'Code QR du Profil du Joueur';

  @override
  String get scanQRCodeToViewProfile =>
      'Scannez le code QR pour voir le profil de ce joueur';

  @override
  String get tapToEnlarge => 'Appuyez pour agrandir';

  @override
  String playerProfileLink(Object playerName) {
    return 'Profil du Joueur: $playerName';
  }

  @override
  String get errorSharingLink => 'Erreur lors du partage du lien';

  @override
  String get share => 'Partager';

  @override
  String get sending => 'Sending...';

  @override
  String get twitterNotConfigured =>
      'Twitter is not configured. Please configure Twitter in Settings.';

  @override
  String get opponents => 'Adversaires';

  @override
  String get addGame => 'Add Game';

  @override
  String get opponent => 'Opponent';

  @override
  String get date => 'Date';

  @override
  String get timeOptional => 'Time (optional)';
}
