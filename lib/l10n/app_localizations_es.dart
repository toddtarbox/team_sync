// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String accessGrantedTo(Object email) {
    return 'Acceso otorgado a $email';
  }

  @override
  String get accomplishmentDeleted => 'Logro eliminado';

  @override
  String get accomplishmentsReordered => 'Logros reordenados';

  @override
  String get account => 'Cuenta';

  @override
  String get actionPhoto => 'Foto de acción';

  @override
  String get actionPhotoCards => 'Tarjetas de fotos de acción';

  @override
  String get add => 'Agregar';

  @override
  String get addAssistQuestion => '¿Agregar asistencia?';

  @override
  String get addAward => 'Agregar premio';

  @override
  String get addAwardDialogTitle => 'Agregar premio';

  @override
  String get addButton => 'Agregar';

  @override
  String get addHighlight => 'Agregar destacado';

  @override
  String get addHighlightDialogTitle => 'Agregar destacado';

  @override
  String get addLink => 'Agregar enlace';

  @override
  String get adminAddedSuccessfully => 'Administrador agregado exitosamente';

  @override
  String get adminRemovedSuccessfully => 'Administrador eliminado exitosamente';

  @override
  String get advanceGame => 'Avanzar juego';

  @override
  String get allowPlayerEditProfile =>
      'Permitir al jugador editar su perfil en la web';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Apariencia';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Estas seguro que quieres borrar este evento? Esto no se puede deshacer.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Estas seguro que quieres borrar este partido? Todos los datos asociados a este partido serán eliminados. Esto no se puede deshacer.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Estas seguro que quieres borrar este jugador? Todos los datos asociados a este jugador serán eliminados. Esto no se puede deshacer.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Estas seguro que quieres borrar esta temporada? Todos los datos asociados a esta temporada serán eliminados. Esto no se puede deshacer.';

  @override
  String get assistedBy => 'Asistido por';

  @override
  String get assists => 'Asistencias';

  @override
  String get automaticTheme => 'Tema automático';

  @override
  String get automaticThemeSwitchDescription =>
      'Cambiar automáticamente el tema según la hora del día';

  @override
  String get awardDeleted => 'Premio eliminado';

  @override
  String get awardSaved => 'Premio guardado correctamente';

  @override
  String get awards => 'Premios';

  @override
  String get away => 'VISITANTE';

  @override
  String get backupDatabase =>
      'Hacer copia de seguridad de la base de datos actual en el dispositivo';

  @override
  String get bestGame => 'Mejor partido';

  @override
  String get bestSeason => 'Mejor temporada';

  @override
  String get calculating => 'Calculando...';

  @override
  String get camera => 'Cámara';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get career => 'Carrera';

  @override
  String get careerLeaders => 'Líderes de carrera';

  @override
  String get careerStatsTitle => 'Estadísticas de carrera';

  @override
  String get changeImage => 'Cambiar imagen';

  @override
  String get changeTeamColors => 'Cambiar colores del equipo';

  @override
  String get clearLogs => 'Limpiar registros';

  @override
  String get close => 'Cerrar';

  @override
  String get closeSidebar => 'Cerrar barra lateral';

  @override
  String get clubDescription => 'Descripción (Opcional)';

  @override
  String get clubDescriptionHint => 'Breve descripción de tu club';

  @override
  String get clubName => 'Nombre del club';

  @override
  String get clubSyncAvailable => 'ClubSync disponible';

  @override
  String get composeTweet => 'Redactar tweet';

  @override
  String get confirmDelete => 'Confirmar eliminación';

  @override
  String get connectToTwitter => 'Conectar a Twitter';

  @override
  String get continueButton => 'Continuar';

  @override
  String get continueText => 'Continuar';

  @override
  String get continueWithoutSigningIn => 'Continuar sin iniciar sesión';

  @override
  String get convertToCloud => 'Convertir a una base de datos en la nube';

  @override
  String get corners => 'Córners';

  @override
  String couldNotOpenUrl(Object url) {
    return 'No se pudo abrir la URL: $url';
  }

  @override
  String get create => 'Crear';

  @override
  String get createAnyway => 'Crear de todos modos';

  @override
  String get createClub => 'Crear club';

  @override
  String get createNewCloudDatabase => 'Crear nueva base de datos en la nube';

  @override
  String get createNewClub => 'Crear nuevo club';

  @override
  String get createNewDatabase => 'Crear nueva base de datos';

  @override
  String get createNewGameToStart => 'Crea un nuevo partido para empezar';

  @override
  String get createNewOpponent => 'Crear nuevo oponente';

  @override
  String get createNewSeason => 'Crear nueva temporada';

  @override
  String get createNewSeasonToStart => 'Crea una nueva temporada para empezar';

  @override
  String get createNewTeam => 'Crear nuevo equipo';

  @override
  String get createNewTeamToStart => 'Crea un nuevo equipo para empezar';

  @override
  String get createTeam => 'Crear equipo';

  @override
  String get creator => 'Creador';

  @override
  String get currently => 'Actualmente';

  @override
  String get dataImport => 'Importar datos';

  @override
  String get databaseAlreadyExists =>
      'Ya existe una base de datos en la nube con este nombre.';

  @override
  String get databaseImportInProgress =>
      'La importación de la base de datos aún está en curso...';

  @override
  String get databaseImported => '¡Base de datos importada con éxito!';

  @override
  String get databaseName => 'Nombre de la base de datos';

  @override
  String get databaseNotFound => 'Base de datos no encontrada';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Depuración: Migración de Firestore → Realtime';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAccomplishment => 'Eliminar logro';

  @override
  String get deleteAccomplishmentConfirmation =>
      '¿Estás seguro de que quieres eliminar este logro?';

  @override
  String deleteAwardConfirm(Object title) {
    return '¿Está seguro de que desea eliminar \"$title\"?';
  }

  @override
  String get deleteAwardTitle => 'Eliminar premio';

  @override
  String deleteHighlightConfirm(Object title) {
    return '¿Estás seguro de que deseas eliminar \"$title\"?';
  }

  @override
  String get deleteHighlightTitle => 'Eliminar destacado';

  @override
  String get description => 'Descripción';

  @override
  String get displayOrder => 'Orden de visualización';

  @override
  String get downloadErrorReport => 'Descargar informe de errores';

  @override
  String get downloadTemplate => 'Descargar plantilla';

  @override
  String get duplicatePlayerName => 'Nombre de jugador duplicado';

  @override
  String durationSeconds(Object seconds) {
    return 'Duración: $seconds segundos';
  }

  @override
  String get edit => 'Editar';

  @override
  String get editAward => 'Editar premio';

  @override
  String get editGame => 'Editar partido';

  @override
  String get editHighlight => 'Editar destacado';

  @override
  String get editPlayer => 'Editar jugador';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get email => 'Correo electrónico';

  @override
  String get endGame => 'Finalizar juego';

  @override
  String get endOfGame => 'Fin del juego';

  @override
  String get endOfRegulation => 'Fin del tiempo regular';

  @override
  String get enterEmailToAddAdmin =>
      'Ingresa el correo para agregar como administrador';

  @override
  String get enterFourDigitPin => 'Ingrese PIN de 4 dígitos';

  @override
  String get enterPinToEdit => 'Ingrese PIN para editar perfil';

  @override
  String get enterTeamIdPrompt =>
      'Ingresa un ID de equipo de 6 dígitos para ver estadísticas:';

  @override
  String get entityType => 'Tipo de entidad';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Error al eliminar logro: $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Error al eliminar el premio: $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Error al eliminar el destacado: $error';
  }

  @override
  String get errorDuringShare =>
      'Error al compartir, por favor intenta de nuevo';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Error al generar la alineación: $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Error al cargar la lista de acceso: $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Error al cargar los premios: $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Error al cargar las credenciales: $error';
  }

  @override
  String get errorLoadingDatabase => 'Error al cargar la base de datos.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Error al cargar duplicados: $error';
  }

  @override
  String get errorLoadingEvents => 'Error al cargar eventos';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Error al cargar los destacados: $error';
  }

  @override
  String get errorLoadingHistory => 'Error al cargar el historial';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Error al cargar las estadísticas del jugador: $error\n\nStack trace: $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Error al cargar bases de datos compartidas: $error';
  }

  @override
  String get errorLoadingStats => 'Error al cargar las estadísticas';

  @override
  String errorLoggingOut(Object error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Error al abrir el enlace: $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Error al reordenar: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Error al guardar el premio: $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Error al guardar el destacado: $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Error al enviar tweet: $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Error al compartir la imagen: $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Error al compartir en Twitter: $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Error al actualizar la hora del partido: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Error al actualizar el perfil: $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Error al subir imágenes: $error';
  }

  @override
  String get exitEditMode => 'Salir del modo de edición';

  @override
  String get failedToGrantAccess =>
      'Error al otorgar acceso. El usuario puede no existir.';

  @override
  String get failedToOpenDatabase => 'Error al abrir la base de datos';

  @override
  String get failedToSendTweet =>
      'Error al enviar el tweet. Por favor, inténtalo de nuevo.';

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
  String get firestoreDocumentPath => 'Ruta del documento de Firestore';

  @override
  String get formation => 'Formación';

  @override
  String get fouls => 'Faltas';

  @override
  String get gallery => 'Galería';

  @override
  String get game => 'Partido';

  @override
  String get gameDayTweetSentSuccessfully =>
      '¡Tweet del día del partido enviado con éxito! 🎉';

  @override
  String get gameStats => 'Estadísticas del juego';

  @override
  String get generate => 'Generar';

  @override
  String get generateImage => 'Generar imagen';

  @override
  String get generateLineup => 'Generar alineación';

  @override
  String get generateLineupImage => 'Generar imagen de alineación';

  @override
  String get generateNewMessage => 'Generar nuevo mensaje';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get goBack => 'Volver';

  @override
  String get goPro => 'Hazte Pro';

  @override
  String get goToGame => 'Ir al partido';

  @override
  String get goalCelebrationPosts => 'Publicaciones de celebración de gol';

  @override
  String get goals => 'Goles';

  @override
  String get gotIt => 'Entendido';

  @override
  String get hideHighlights => 'Ocultar destacados';

  @override
  String get highlightDeleted => 'Destacado eliminado';

  @override
  String get highlightSaved => 'Destacado guardado con éxito';

  @override
  String get highlights => 'Destacados';

  @override
  String get hintAwardTitle => 'ej., MVP, All-Star, Mximo goleador';

  @override
  String get hintDescriptionOptional => 'Descripción opcional';

  @override
  String get hintTitleExample => 'p. ej., Gol ganador';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Historial';

  @override
  String get historyVersus => 'Historial contra';

  @override
  String get home => 'LOCAL';

  @override
  String get importSeason => 'Importar temporada';

  @override
  String get importTeamsPlayersGamesStats =>
      'Importar equipos, jugadores, partidos y estadísticas';

  @override
  String get importingDatabase => 'Importando base de datos...';

  @override
  String get invalidPin => 'El PIN debe tener 4 dígitos';

  @override
  String get labelAwardImage => 'Imagen del premio (opcional)';

  @override
  String get labelAwardTitle => 'Ttulo del premio *';

  @override
  String get labelDate => 'Fecha';

  @override
  String get labelDescription => 'Descripción';

  @override
  String get labelTitleRequired => 'Título *';

  @override
  String get labelVideoUrlRequired => 'URL del video *';

  @override
  String get language => 'Idioma';

  @override
  String get leaders => 'Líderes';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get lineupGeneratorMobileOnly =>
      'El generador de alineaciones solo está disponible en dispositivos móviles';

  @override
  String get lineupSharedSuccessfully => '¡Alineación compartida exitosamente!';

  @override
  String get lineupTweetedSuccessfully =>
      '¡Alineación tuiteada exitosamente! 🎉';

  @override
  String get linkURL => 'URL del enlace';

  @override
  String get liveBannerTapToWatch => 'EN VIVO — Toca para ver la transmisión';

  @override
  String get liveUrlLabel => 'URL en vivo';

  @override
  String get loadTeam => 'Cargar equipo';

  @override
  String get loading => 'Cargando...';

  @override
  String get loadingAllSeasons => 'Cargando todas las temporadas...';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get logOutConfirmation =>
      '¿Estás seguro de que quieres cerrar sesión? Necesitarás iniciar sesión nuevamente para acceder a las bases de datos en la nube.';

  @override
  String get loggedOutSuccessfully => 'Sesión cerrada exitosamente';

  @override
  String get logs => 'Registros';

  @override
  String get lossAbbreviation => 'P';

  @override
  String get matchDate => 'Fecha del partido';

  @override
  String get maybeLater => 'Quizás más tarde';

  @override
  String get mergeAllIntoFirst => 'Fusionar todo en el primero';

  @override
  String get mergeComplete => 'Fusión completa';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthDec => 'Dic';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthJan => 'Ene';

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
  String get multipleCardStyles => 'Múltiples estilos de tarjetas';

  @override
  String get multipleFiles => 'Múltiples archivos:';

  @override
  String get newDatabase => 'Nueva base de datos';

  @override
  String get newEvent => 'Nuevo evento';

  @override
  String get newPlayer => 'Nuevo jugador';

  @override
  String get newSeason => 'Nueva temporada';

  @override
  String get newTeam => 'Nuevo equipo';

  @override
  String get nextGamePrefix => 'Próximo partido:';

  @override
  String get nextGameStayTuned =>
      'Mantente atento al enlace en vivo cuando comience';

  @override
  String get noAdminsYet => 'Aún no hay administradores';

  @override
  String get noAwardsAvailable => 'No hay premios disponibles';

  @override
  String get noCloudDatabasesFound =>
      'No se encontraron bases de datos en la nube';

  @override
  String get noClubDatabasesFound =>
      'No se encontraron bases de datos en la nube';

  @override
  String get noData => 'Sin datos';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get noDatabaseFoundMessage =>
      'Para comenzar, necesitarás crear una nueva base de datos o abrir una existente. ¿Te gustaría configurar tu base de datos ahora?';

  @override
  String get noDuplicatesToMerge => 'No hay duplicados para fusionar';

  @override
  String get noEmail => 'Sin correo electrónico';

  @override
  String get noGameAvailableToSetLiveLink =>
      'No hay partido disponible para establecer enlace en vivo';

  @override
  String get noGameAvailableToTweetAbout =>
      'No hay partido disponible para tuitear';

  @override
  String get noGamesFound => 'No se encontraron partidos';

  @override
  String get noHighlightsAvailable => 'No hay destacados disponibles';

  @override
  String get noLogsYet => 'Aún no hay registros.';

  @override
  String get noPlayersFound => 'No se encontraron jugadores';

  @override
  String get noSeasonsFound => 'No se encontraron temporadas';

  @override
  String get noStatsAvailable => 'No hay estadísticas disponibles';

  @override
  String get noTeamDataAvailable => 'No hay datos de equipo disponibles';

  @override
  String get noTeamFound => 'No se encontró ningún equipo';

  @override
  String get noTeamSelected => 'No se seleccionó ningún equipo';

  @override
  String get notAnAdministrator => 'No es administrador';

  @override
  String get notSignedIn => 'No has iniciado sesión';

  @override
  String get offside => 'Fuera de juego';

  @override
  String get openDatabase => 'Abrir base de datos';

  @override
  String get openExistingCloudDatabase =>
      'Abrir base de datos en la nube existente';

  @override
  String get openFromBackup => 'Abrir desde copia de seguridad';

  @override
  String openedDatabase(Object name) {
    return 'Base de datos abierta: $name';
  }

  @override
  String get optionalDetails => 'Detalles opcionales';

  @override
  String get optionalExternalLink => 'Enlace externo opcional';

  @override
  String get other => 'Otro';

  @override
  String get overall => 'General';

  @override
  String get overview => 'Resumen';

  @override
  String get password => 'Contraseña';

  @override
  String get pickAColor => 'Elige un color';

  @override
  String get pickTeamColors => 'Elegir colores del equipo';

  @override
  String get pinLabel => 'PIN';

  @override
  String get playerName => 'Nombre del jugador';

  @override
  String get playerNotFound => 'Jugador no encontrado';

  @override
  String get playerNumber => 'Número del jugador';

  @override
  String get playerProfilesProFeature =>
      'Los perfiles de jugadores son parte de la versión Pro. Actualiza para acceder a estadísticas detalladas e historial de carrera.';

  @override
  String get players => 'Jugadores';

  @override
  String get pleaseAddPlayersFirst =>
      'Por favor agrega jugadores a la temporada primero';

  @override
  String get pleaseCorrectFormErrors =>
      'Por favor corrige los errores en el formulario.';

  @override
  String get pleaseCreateOrOpenADatabase =>
      'Por favor, crea o abre una base de datos';

  @override
  String get pleaseCreateSeasonFirst =>
      'Por favor crea una temporada primero para generar una alineación';

  @override
  String get pleaseEnterEmailAddress =>
      'Por favor ingresa una dirección de correo electrónico';

  @override
  String get pleaseSelectAll11Players =>
      'Por favor selecciona los 11 jugadores';

  @override
  String get postGameResults => 'Publicar resultados del partido';

  @override
  String get postGameStats => 'Publicar estadísticas del partido';

  @override
  String get postSeasonStats => 'Publicar estadísticas de la temporada';

  @override
  String get preparingShare => 'Preparando...';

  @override
  String get preview => 'Vista previa';

  @override
  String get previousLineupRestored => 'Alineación anterior restaurada';

  @override
  String get primaryColor => 'Color primario';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Función Pro';

  @override
  String get proSubscriptionFeatures => 'CARACTERÍSTICAS DE LA SUSCRIPCIÓN PRO';

  @override
  String get profilePhoto => 'Foto de perfil';

  @override
  String get profilePicture => 'Foto de perfil';

  @override
  String get profileUpdated => 'Perfil actualizado correctamente';

  @override
  String get recentGames => 'Partidos recientes';

  @override
  String get recentHighlights => 'Destacados recientes';

  @override
  String get recordHolders => 'Poseedores de récords';

  @override
  String get records => 'Récords';

  @override
  String get redCards => 'Tarjetas rojas';

  @override
  String get remindMeLater => 'Recordar más tarde';

  @override
  String get remove => 'Eliminar';

  @override
  String get removeButton => 'Eliminar';

  @override
  String get removeFromClub => 'Eliminar del club';

  @override
  String get removeImage => 'Eliminar imagen';

  @override
  String get retry => 'Reintentar';

  @override
  String get revokeAccess => 'Revocar acceso';

  @override
  String rowNumber(Object number) {
    return 'Fila $number';
  }

  @override
  String get save => 'Guardar';

  @override
  String get saves => 'Paradas';

  @override
  String get scoringSummary => 'Resumen de goles';

  @override
  String get season => 'Temporada';

  @override
  String get seasonName => 'Nombre de la temporada';

  @override
  String get seasonNotFound => 'Temporada no encontrada';

  @override
  String get seasonStats => 'Estadísticas de la temporada';

  @override
  String get seasons => 'Temporadas';

  @override
  String get secondaryColor => 'Color secundario';

  @override
  String get selectACloudDatabase => 'Seleccionar una base de datos en la nube';

  @override
  String get selectAClub => 'Seleccionar un club';

  @override
  String get selectADatabase => 'Seleccionar una base de datos';

  @override
  String get selectEventType => 'Seleccionar tipo de evento';

  @override
  String get selectImageSource => 'Seleccionar fuente de imagen';

  @override
  String get selectOpponent => 'Seleccionar oponente';

  @override
  String get selectPeriod => 'Seleccionar período';

  @override
  String get selectPlayer => 'Seleccionar jugador';

  @override
  String get sendTweet => 'Enviar tweet';

  @override
  String get setGameTime => 'Establecer hora del partido';

  @override
  String get setLiveLink => 'Establecer enlace en vivo';

  @override
  String get setLiveStreamLink => 'Establecer enlace de transmisión en vivo';

  @override
  String get setTeamColors => 'Establecer colores del equipo';

  @override
  String get setTime => 'Establecer hora';

  @override
  String get settings => 'Configuración';

  @override
  String get shareDatabase => 'Compartir base de datos';

  @override
  String get shareImage => 'Compartir imagen';

  @override
  String get shareToSocialMedia => 'Compartir en redes sociales';

  @override
  String get sharedSuccessfully => '¡Compartido exitosamente!';

  @override
  String get shots => 'Tiros';

  @override
  String get shotsOnGoal => 'Tiros a puerta';

  @override
  String get showHighlights => 'Mostrar destacados';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String signInFailed(Object error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get signInRequired => 'Inicio de sesión requerido';

  @override
  String get signInToAccessCloudDatabases =>
      'Inicia sesión para acceder a bases de datos en la nube';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String signedInWith(Object provider) {
    return 'Sesión iniciada con $provider';
  }

  @override
  String get skip => 'Omitir';

  @override
  String get soccerAnalytics => 'Análisis de Fútbol';

  @override
  String get startImport => 'Iniciar importación';

  @override
  String get systemDefaultLanguage => 'Predeterminado del sistema';

  @override
  String get systemDefaultTheme => 'Predeterminado del sistema';

  @override
  String get team => 'Equipo';

  @override
  String get teamAccomplishments => 'Logros del equipo';

  @override
  String get teamId => 'ID de equipo';

  @override
  String get teamName => 'Nombre del equipo';

  @override
  String get teamShortName => 'Nombre corto del equipo';

  @override
  String get teamStandings => 'Clasificación de equipos';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer => 'Visor de base de datos TeamSync';

  @override
  String get teamSyncViewer => 'Visor de TeamSync';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get themeClassic => 'Clásico';

  @override
  String get themeDarkMode => 'Modo oscuro';

  @override
  String get themeElegant => 'Elegante';

  @override
  String get themeMinimal => 'Minimalista';

  @override
  String get themeNeon => 'Neón';

  @override
  String get themeRetro => 'Retro';

  @override
  String get thisWillMergeFollowingPlayers =>
      'Esto fusionará los siguientes jugadores:';

  @override
  String get tieAbbreviation => 'E';

  @override
  String get time => 'Hora';

  @override
  String get titleUrlRequired => 'El título y la URL son obligatorios';

  @override
  String get tweetGameDay => 'Tuitear día de partido';

  @override
  String get tweetSentSuccessfully => '¡Tweet enviado exitosamente!';

  @override
  String get tweetedSuccessfully => '¡Tuiteado exitosamente!';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Configuración de Twitter';

  @override
  String get twitterSettingsSavedSuccessfully =>
      '¡Configuración de Twitter guardada exitosamente!';

  @override
  String get unableToOpenLink => 'No se puede abrir el enlace';

  @override
  String get unableToOpenLiveLink => 'No se puede abrir el enlace en vivo';

  @override
  String get unexpectedDatabaseFormat => 'Formato de base de datos inesperado';

  @override
  String get unlockButton => 'Desbloquear';

  @override
  String get update => 'Actualizar';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get upgradeToPro => 'Actualizar a Pro';

  @override
  String get uploadImage => 'Subir imagen';

  @override
  String get useDeviceLanguage => 'Usar idioma del dispositivo';

  @override
  String get userEmail => 'Correo electrónico del usuario';

  @override
  String get validateOnly => 'Solo validar';

  @override
  String get videoLabel => 'Video';

  @override
  String get viewMore => 'Ver más';

  @override
  String get watchLabel => 'Ver';

  @override
  String get welcomeToTeamSync => '¡Bienvenido a TeamSync!';

  @override
  String get winAbbreviation => 'G';

  @override
  String get year => 'Año';

  @override
  String get yellowCards => 'Tarjetas amarillas';

  @override
  String get noGamesYet => 'Aún no hay partidos';

  @override
  String get live => 'EN VIVO';

  @override
  String get win => 'VICTORIA';

  @override
  String get loss => 'DERROTA';

  @override
  String get tie => 'EMPATE';

  @override
  String get teamPerformance => 'Rendimiento del equipo';

  @override
  String teamPerformanceSince(Object year) {
    return 'Rendimiento del equipo (Desde $year)';
  }

  @override
  String get addAccomplishment => 'Agregar logro';

  @override
  String get editAccomplishment => 'Editar logro';

  @override
  String get titleRequired => 'Título *';

  @override
  String get titleIsRequired => 'El título es obligatorio';

  @override
  String get exampleStateChampions => 'ej., Campeones estatales';

  @override
  String get exampleYear => 'ej., 2023';

  @override
  String get saving => 'Guardando...';

  @override
  String get since => 'Desde';

  @override
  String get images => 'Imágenes';

  @override
  String get tapImageToPrimary => 'Toca una imagen para hacerla principal';

  @override
  String get selectMultipleImages =>
      'Puedes seleccionar varias imágenes a la vez';

  @override
  String get primary => 'Principal';

  @override
  String get notAuthorizedUploadImages =>
      'No autorizado para subir imágenes. Inicia sesión en el móvil para agregar imágenes.';

  @override
  String get games => 'Partidos';

  @override
  String gameTimeSet(Object time) {
    return 'Hora del partido establecida en $time';
  }

  @override
  String get noTimeSetPrompt =>
      'Este partido no tiene horario establecido (actualmente 00:00). ¿Quieres establecer la hora antes de tuitear?';

  @override
  String get sortByTeamName => 'Nombre del equipo';

  @override
  String get sortByMostGames => 'Más partidos';

  @override
  String get sortByMostWins => 'Más victorias';

  @override
  String get sortByWinPercentage => '% Victoria';

  @override
  String get sortByRecent => 'Reciente';

  @override
  String get noMatchupHistoryYet => 'Aún no hay historial de enfrentamientos';

  @override
  String get gamesSingular => 'partido';

  @override
  String get gamesPlural => 'partidos';

  @override
  String gamesPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'partidos',
      one: 'partido',
    );
    return '$count $_temp0 jugados';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Desconocido';

  @override
  String get editSeasonName => 'Editar nombre de temporada';

  @override
  String get seasonNameRequired => 'El nombre de temporada es obligatorio';

  @override
  String get seasonNameUpdated =>
      'Nombre de temporada actualizado correctamente';
}
