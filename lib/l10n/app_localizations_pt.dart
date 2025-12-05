// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get email => 'E-mail';

  @override
  String get description => 'Descrição';

  @override
  String accessGrantedTo(Object email) {
    return 'Acesso concedido a $email';
  }

  @override
  String get accomplishmentDeleted => 'Realização excluída';

  @override
  String get accomplishmentsReordered => 'Realizações reordenadas';

  @override
  String get account => 'Conta';

  @override
  String get actionPhoto => 'Foto de ação';

  @override
  String get actionPhotoCards => 'Cartões de foto de ação';

  @override
  String get add => 'Adicionar';

  @override
  String get addAssistQuestion => 'Adicionar assistência?';

  @override
  String get addAward => 'Adicionar prêmio';

  @override
  String get addAwardDialogTitle => 'Adicionar prêmio';

  @override
  String get addButton => 'Adicionar';

  @override
  String get addHighlight => 'Adicionar destaque';

  @override
  String get addHighlightDialogTitle => 'Adicionar destaque';

  @override
  String get addLink => 'Adicionar link';

  @override
  String get adminAddedSuccessfully => 'Administrador adicionado com sucesso';

  @override
  String get adminRemovedSuccessfully => 'Administrador removido com sucesso';

  @override
  String get advanceGame => 'Avançar jogo';

  @override
  String get allowPlayerEditProfile =>
      'Permitir que o jogador edite seu perfil na web';

  @override
  String get appTitle => 'TeamSync';

  @override
  String get appearance => 'Aparência';

  @override
  String get areYouSureYouWantToDeleteThisEvent =>
      'Tem certeza de que deseja excluir este evento? Isso não pode ser desfeito.';

  @override
  String get areYouSureYouWantToDeleteThisGame =>
      'Tem certeza de que deseja excluir este jogo? Todos os dados associados a este jogo serão excluídos. Isso não pode ser desfeito.';

  @override
  String get areYouSureYouWantToDeleteThisPlayer =>
      'Tem certeza de que deseja excluir este jogador? Todos os dados associados a este jogador serão excluídos. Isso não pode ser desfeito.';

  @override
  String get areYouSureYouWantToDeleteThisSeason =>
      'Tem certeza de que deseja excluir esta temporada? Todos os dados associados a esta temporada serão excluídos. Isso não pode ser desfeito.';

  @override
  String get assistedBy => 'Assistência de';

  @override
  String get assists => 'Assistências';

  @override
  String get automaticTheme => 'Tema automático';

  @override
  String get automaticThemeSwitchDescription =>
      'Mudar automaticamente o tema com base na hora do dia';

  @override
  String get awardDeleted => 'Prêmio excluído';

  @override
  String get awardSaved => 'Prêmio salvo com sucesso';

  @override
  String get awards => 'Prêmios';

  @override
  String get away => 'FORA';

  @override
  String get backupDatabase => 'Backup do banco de dados atual no dispositivo';

  @override
  String get bestGame => 'Melhor jogo';

  @override
  String get bestSeason => 'Melhor temporada';

  @override
  String get calculating => 'Calculando...';

  @override
  String get camera => 'Câmera';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get career => 'Carreira';

  @override
  String get careerLeaders => 'Líderes da carreira';

  @override
  String get careerStatsTitle => 'Estatísticas da carreira';

  @override
  String get changeImage => 'Alterar imagem';

  @override
  String get changeTeamColors => 'Alterar cores da equipe';

  @override
  String get clearLogs => 'Limpar logs';

  @override
  String get close => 'Fechar';

  @override
  String get closeSidebar => 'Fechar barra lateral';

  @override
  String get clubDescription => 'Descrição (opcional)';

  @override
  String get clubDescriptionHint => 'Breve descrição do seu clube';

  @override
  String get clubName => 'Nome do clube';

  @override
  String get clubSyncAvailable => 'ClubSync disponível';

  @override
  String get composeTweet => 'Compor tuíte';

  @override
  String get confirmDelete => 'Confirmar exclusão';

  @override
  String get connectToTwitter => 'Conectar ao Twitter';

  @override
  String get continueButton => 'Continuar';

  @override
  String get continueText => 'Continuar';

  @override
  String get continueWithoutSigningIn => 'Continuar sem entrar';

  @override
  String get convertToCloud => 'Converter para banco de dados na nuvem';

  @override
  String get corners => 'Escanteios';

  @override
  String couldNotOpenUrl(Object url) {
    return 'Não foi possível abrir a URL: $url';
  }

  @override
  String get create => 'Criar';

  @override
  String get createAnyway => 'Criar mesmo assim';

  @override
  String get createClub => 'Criar clube';

  @override
  String get createNewCloudDatabase => 'Criar novo banco de dados na nuvem';

  @override
  String get createNewClub => 'Criar novo clube';

  @override
  String get createNewDatabase => 'Criar novo banco de dados';

  @override
  String get createNewGameToStart => 'Crie um novo jogo para começar';

  @override
  String get createNewOpponent => 'Criar novo adversário';

  @override
  String get createNewSeason => 'Criar nova temporada';

  @override
  String get createNewSeasonToStart => 'Crie uma nova temporada para começar';

  @override
  String get createNewTeam => 'Criar nova equipe';

  @override
  String get createNewTeamToStart => 'Crie uma nova equipe para começar';

  @override
  String get createTeam => 'Criar equipe';

  @override
  String get creator => 'Criador';

  @override
  String get currently => 'Atualmente';

  @override
  String get dataImport => 'Importação de dados';

  @override
  String get databaseAlreadyExists =>
      'Já existe um banco de dados na nuvem com este nome.';

  @override
  String get databaseImportInProgress =>
      'Importação do banco de dados ainda em andamento...';

  @override
  String get databaseImported => 'Banco de dados importado com sucesso!';

  @override
  String get databaseName => 'Nome do banco de dados';

  @override
  String get databaseNotFound => 'Banco de dados não encontrado';

  @override
  String get debugFirestoreRealtimeMigration =>
      'Debug: Migração Firestore → Realtime';

  @override
  String get delete => 'Excluir';

  @override
  String get deleteAccomplishment => 'Excluir realização';

  @override
  String get deleteAccomplishmentConfirmation =>
      'Tem certeza de que deseja excluir esta realização?';

  @override
  String deleteAwardConfirm(Object title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get deleteAwardTitle => 'Excluir prêmio';

  @override
  String deleteHighlightConfirm(Object title) {
    return 'Tem certeza de que deseja excluir \"$title\"?';
  }

  @override
  String get deleteHighlightTitle => 'Excluir destaque';

  @override
  String get displayOrder => 'Ordem de exibição';

  @override
  String get downloadErrorReport => 'Baixar relatório de erros';

  @override
  String get downloadTemplate => 'Baixar modelo';

  @override
  String get duplicatePlayerName => 'Nome de jogador duplicado';

  @override
  String durationSeconds(Object seconds) {
    return 'Duração: $seconds segundos';
  }

  @override
  String get edit => 'Editar';

  @override
  String get editAward => 'Editar prêmio';

  @override
  String get editGame => 'Editar jogo';

  @override
  String get editHighlight => 'Editar destaque';

  @override
  String get editPlayer => 'Editar jogador';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get endGame => 'Encerrar jogo';

  @override
  String get endOfGame => 'Fim de jogo';

  @override
  String get endOfRegulation => 'Fim do tempo regulamentar';

  @override
  String get enterEmailToAddAdmin =>
      'Digite o e-mail para adicionar como administrador';

  @override
  String get enterFourDigitPin => 'Digite um PIN de 4 dígitos';

  @override
  String get enterPinToEdit => 'Digite o PIN para editar o perfil';

  @override
  String get enterTeamIdPrompt =>
      'Digite um ID de equipe de 6 dígitos para ver estatísticas:';

  @override
  String get entityType => 'Tipo de entidade';

  @override
  String errorDeletingAccomplishment(Object error) {
    return 'Erro ao excluir realização: $error';
  }

  @override
  String errorDeletingAward(Object error) {
    return 'Erro ao excluir prêmio: $error';
  }

  @override
  String errorDeletingHighlight(Object error) {
    return 'Erro ao excluir destaque: $error';
  }

  @override
  String get errorDuringShare => 'Erro ao compartilhar, tente novamente';

  @override
  String errorGeneratingLineup(Object error) {
    return 'Erro ao gerar escalação: $error';
  }

  @override
  String errorLoadingAccessList(Object error) {
    return 'Erro ao carregar lista de acesso: $error';
  }

  @override
  String errorLoadingAwards(Object error) {
    return 'Erro ao carregar prêmios: $error';
  }

  @override
  String errorLoadingCredentials(Object error) {
    return 'Erro ao carregar credenciais: $error';
  }

  @override
  String get errorLoadingDatabase => 'Erro ao carregar banco de dados.';

  @override
  String errorLoadingDuplicates(Object error) {
    return 'Erro ao carregar duplicados: $error';
  }

  @override
  String get errorLoadingEvents => 'Erro ao carregar eventos';

  @override
  String errorLoadingHighlights(Object error) {
    return 'Erro ao carregar destaques: $error';
  }

  @override
  String get errorLoadingHistory => 'Erro ao carregar histórico';

  @override
  String errorLoadingPlayerStats(Object error, Object stack) {
    return 'Erro ao carregar estatísticas do jogador: $error\n\nRastreamento de pilha: $stack';
  }

  @override
  String errorLoadingSharedDatabases(Object error) {
    return 'Erro ao carregar bancos de dados compartilhados: $error';
  }

  @override
  String get errorLoadingStats => 'Erro ao carregar estatísticas';

  @override
  String errorLoggingOut(Object error) {
    return 'Erro ao sair: $error';
  }

  @override
  String errorMessage(Object error) {
    return 'Erro: $error';
  }

  @override
  String errorOpeningLink(Object error) {
    return 'Erro ao abrir link: $error';
  }

  @override
  String errorReordering(Object error) {
    return 'Erro ao reordenar: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String errorSavingAward(Object error) {
    return 'Erro ao salvar prêmio: $error';
  }

  @override
  String errorSavingHighlight(Object error) {
    return 'Erro ao salvar destaque: $error';
  }

  @override
  String errorSavingSettings(Object error) {
    return 'Erro ao salvar configurações: $error';
  }

  @override
  String errorSendingTweet(Object error) {
    return 'Erro ao enviar tweet: $error';
  }

  @override
  String errorSharingImage(Object error) {
    return 'Erro ao compartilhar imagem: $error';
  }

  @override
  String errorSharingToTwitter(Object error) {
    return 'Erro ao compartilhar no Twitter: $error';
  }

  @override
  String errorUpdatingGameTime(Object error) {
    return 'Erro ao atualizar horário do jogo: $error';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Erro ao atualizar perfil: $error';
  }

  @override
  String errorUploadingImages(Object error) {
    return 'Erro ao carregar imagens: $error';
  }

  @override
  String get exitEditMode => 'Sair do modo de edição';

  @override
  String get failedToGrantAccess =>
      'Falha ao conceder acesso. O usuário pode não existir.';

  @override
  String get failedToOpenDatabase => 'Falha ao abrir banco de dados';

  @override
  String get failedToSendTweet => 'Falha ao enviar tuíte. Tente novamente.';

  @override
  String get finalOT => 'Final Prorrogação';

  @override
  String get finalOTText => 'Final Prorrogação';

  @override
  String get finalPKs => 'Final Pênaltis';

  @override
  String get finalPKsText => 'Final Pênaltis';

  @override
  String get finalText => 'Final';

  @override
  String get firestoreDocumentPath => 'Caminho do documento Firestore';

  @override
  String get formation => 'Formação';

  @override
  String get fouls => 'Faltas';

  @override
  String get gallery => 'Galeria';

  @override
  String get game => 'Jogo';

  @override
  String get gameDayTweetSentSuccessfully =>
      'Tweet do dia do jogo enviado com sucesso! 🎉';

  @override
  String get gameStats => 'Estatísticas do jogo';

  @override
  String get generate => 'Gerar';

  @override
  String get generateImage => 'Gerar imagem';

  @override
  String get generateLineup => 'Gerar escalação';

  @override
  String get generateLineupImage => 'Gerar imagem de escalação';

  @override
  String get generateNewMessage => 'Gerar nova mensagem';

  @override
  String get getStarted => 'Começar';

  @override
  String get goBack => 'Voltar';

  @override
  String get goPro => 'Ir para Pro';

  @override
  String get goToGame => 'Ir para o jogo';

  @override
  String get goalCelebrationPosts => 'Postagens de comemoração de gol';

  @override
  String get goals => 'Gols';

  @override
  String get gotIt => 'Entendi';

  @override
  String get hideHighlights => 'Ocultar destaques';

  @override
  String get highlightDeleted => 'Destaque excluído';

  @override
  String get highlightSaved => 'Destaque salvo com sucesso';

  @override
  String get highlights => 'Destaques';

  @override
  String get hintAwardTitle => 'ex. MVP, All-Star, Artilheiro';

  @override
  String get hintDescriptionOptional => 'Descrição opcional';

  @override
  String get hintTitleExample => 'ex. Gol da vitória';

  @override
  String get hintVideoUrl => 'https://...';

  @override
  String get history => 'Análise';

  @override
  String get historyVersus => 'Análise';

  @override
  String get home => 'CASA';

  @override
  String get importSeason => 'Importar temporada';

  @override
  String get importTeamsPlayersGamesStats =>
      'Importar equipes, jogadores, jogos e estatísticas';

  @override
  String get importingDatabase => 'Importando banco de dados...';

  @override
  String get invalidPin => 'O PIN deve ter 4 dígitos';

  @override
  String get labelAwardImage => 'Imagem do prêmio (opcional)';

  @override
  String get labelAwardTitle => 'Título do prêmio *';

  @override
  String get labelDate => 'Data';

  @override
  String get labelDescription => 'Descrição';

  @override
  String get labelTitleRequired => 'Título *';

  @override
  String get labelVideoUrlRequired => 'URL do vídeo *';

  @override
  String get language => 'Idioma';

  @override
  String get leaders => 'Líderes';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get lineupGeneratorMobileOnly =>
      'O gerador de escalação está disponível apenas em dispositivos móveis';

  @override
  String get lineupSharedSuccessfully => 'Escalação compartilhada com sucesso!';

  @override
  String get lineupTweetedSuccessfully => 'Escalação tuitada com sucesso! 🎉';

  @override
  String get linkURL => 'URL do link';

  @override
  String get liveBannerTapToWatch =>
      'AO VIVO — Toque para assistir à transmissão';

  @override
  String get liveUrlLabel => 'URL ao vivo';

  @override
  String get loadTeam => 'Carregar equipe';

  @override
  String get loading => 'Carregando...';

  @override
  String get loadingAllSeasons => 'Carregando todas as temporadas...';

  @override
  String get logOut => 'Sair';

  @override
  String get logOutConfirmation =>
      'Tem certeza de que deseja sair? Você precisará entrar novamente para acessar bancos de dados na nuvem.';

  @override
  String get loggedOutSuccessfully => 'Saída realizada com sucesso';

  @override
  String get logs => 'Logs';

  @override
  String get lossAbbreviation => 'D';

  @override
  String get matchDate => 'Data da partida';

  @override
  String get maybeLater => 'Talvez mais tarde';

  @override
  String get mergeAllIntoFirst => 'Mesclar tudo no primeiro';

  @override
  String get mergeComplete => 'Mesclagem concluída';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthDec => 'Dez';

  @override
  String get monthFeb => 'Fev';

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
  String get monthOct => 'Out';

  @override
  String get monthSep => 'Set';

  @override
  String get multipleCardStyles => 'Múltiplos estilos de cartões';

  @override
  String get multipleFiles => 'Vários arquivos:';

  @override
  String get newDatabase => 'Novo banco de dados';

  @override
  String get newEvent => 'Novo evento';

  @override
  String get newPlayer => 'Novo jogador';

  @override
  String get newSeason => 'Nova temporada';

  @override
  String get newTeam => 'Nova equipe';

  @override
  String get nextGamePrefix => 'Próximo jogo:';

  @override
  String get nextGameStayTuned => 'Fique atento ao link ao vivo quando começar';

  @override
  String get noAdminsYet => 'Ainda não há administradores';

  @override
  String get noAwardsAvailable => 'Nenhum prêmio disponível';

  @override
  String get noCloudDatabasesFound =>
      'Nenhum banco de dados na nuvem encontrado';

  @override
  String get noClubDatabasesFound =>
      'Nenhum banco de dados na nuvem encontrado';

  @override
  String get noData => 'Sem dados';

  @override
  String get noDataAvailable => 'Nenhum dado disponível';

  @override
  String get noDatabaseFoundMessage =>
      'Para começar, você precisará criar um novo banco de dados ou abrir um existente. Gostaria de configurar seu banco de dados agora?';

  @override
  String get noDuplicatesToMerge => 'Nenhum duplicado para mesclar';

  @override
  String get noEmail => 'Sem e-mail';

  @override
  String get noGameAvailableToSetLiveLink =>
      'Nenhum jogo disponível para definir link ao vivo';

  @override
  String get noGameAvailableToTweetAbout =>
      'Nenhum jogo disponível para tweetar';

  @override
  String get noGamesFound => 'Nenhum jogo encontrado';

  @override
  String get noHighlightsAvailable => 'Nenhum destaque disponível';

  @override
  String get noLogsYet => 'Ainda não há logs.';

  @override
  String get noPlayersFound => 'Nenhum jogador encontrado';

  @override
  String get noSeasonsFound => 'Nenhuma temporada encontrada';

  @override
  String get noStatsAvailable => 'Nenhuma estatística disponível';

  @override
  String get noTeamDataAvailable => 'Nenhum dado de equipe disponível';

  @override
  String get noTeamFound => 'Nenhuma equipe encontrada';

  @override
  String get noTeamSelected => 'Nenhuma equipe selecionada';

  @override
  String get notAnAdministrator => 'Não é um administrador';

  @override
  String get notSignedIn => 'Não conectado';

  @override
  String get offside => 'Impedimento';

  @override
  String get openDatabase => 'Abrir banco de dados';

  @override
  String get openExistingCloudDatabase =>
      'Abrir banco de dados na nuvem existente';

  @override
  String get openFromBackup => 'Abrir do backup';

  @override
  String openedDatabase(Object name) {
    return 'Banco de dados aberto: $name';
  }

  @override
  String get optionalDetails => 'Detalhes opcionais';

  @override
  String get optionalExternalLink => 'Link externo opcional';

  @override
  String get other => 'Outro';

  @override
  String get overall => 'Geral';

  @override
  String get overview => 'Visão geral';

  @override
  String get password => 'Senha';

  @override
  String get pickAColor => 'Escolher uma cor';

  @override
  String get pickTeamColors => 'Escolher cores da equipe';

  @override
  String get pinLabel => 'PIN';

  @override
  String get playerName => 'Nome do jogador';

  @override
  String get playerNotFound => 'Jogador não encontrado';

  @override
  String get playerNumber => 'Número do jogador';

  @override
  String get playerProfilesProFeature =>
      'Os perfis de jogadores fazem parte da versão Pro. Faça upgrade para acessar estatísticas detalhadas e histórico de carreira.';

  @override
  String get players => 'Jogadores';

  @override
  String get pleaseAddPlayersFirst => 'Adicione jogadores à temporada primeiro';

  @override
  String get pleaseCorrectFormErrors => 'Corrija os erros no formulário.';

  @override
  String get pleaseCreateOrOpenADatabase =>
      'Por favor, crie ou abra um banco de dados';

  @override
  String get pleaseCreateSeasonFirst =>
      'Crie uma temporada primeiro para gerar uma escalação';

  @override
  String get pleaseEnterEmailAddress =>
      'Por favor, insira um endereço de e-mail';

  @override
  String get pleaseSelectAll11Players =>
      'Por favor, selecione todos os 11 jogadores';

  @override
  String get postGameResults => 'Postar resultados do jogo';

  @override
  String get postGameStats => 'Postar estatísticas do jogo';

  @override
  String get postSeasonStats => 'Postar estatísticas da temporada';

  @override
  String get preparingShare => 'Preparando...';

  @override
  String get preview => 'Visualizar';

  @override
  String get previousLineupRestored => 'Escalação anterior restaurada';

  @override
  String get primaryColor => 'Cor primária';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get pro => 'Pro';

  @override
  String get proFeature => 'Recurso Pro';

  @override
  String get proSubscriptionFeatures => 'RECURSOS DE ASSINATURA PRO';

  @override
  String get profilePhoto => 'Foto de perfil';

  @override
  String get profilePicture => 'Foto de perfil';

  @override
  String get profileUpdated => 'Perfil atualizado com sucesso';

  @override
  String get recentGames => 'Jogos recentes';

  @override
  String get recentHighlights => 'Destaques recentes';

  @override
  String get recordHolders => 'Detentores de recordes';

  @override
  String get records => 'Recordes';

  @override
  String get redCards => 'Cartões Vermelhos';

  @override
  String get remindMeLater => 'Lembrar mais tarde';

  @override
  String get remove => 'Remover';

  @override
  String get removeButton => 'Remover';

  @override
  String get removeFromClub => 'Remover do clube';

  @override
  String get removeImage => 'Remover imagem';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get revokeAccess => 'Revogar acesso';

  @override
  String rowNumber(Object number) {
    return 'Linha $number';
  }

  @override
  String get save => 'Salvar';

  @override
  String get saves => 'Defesas';

  @override
  String get scoringSummary => 'Resumo de pontuação';

  @override
  String get season => 'Temporada';

  @override
  String get seasonName => 'Nome da temporada';

  @override
  String get seasonNotFound => 'Temporada não encontrada';

  @override
  String get seasonStats => 'Estatísticas da temporada';

  @override
  String get seasons => 'Temporadas';

  @override
  String get secondaryColor => 'Cor secundária';

  @override
  String get selectACloudDatabase => 'Selecionar um banco de dados na nuvem';

  @override
  String get selectAClub => 'Selecionar um clube';

  @override
  String get selectADatabase => 'Selecionar um banco de dados';

  @override
  String get selectEventType => 'Selecionar tipo de evento';

  @override
  String get selectImageSource => 'Selecionar origem da imagem';

  @override
  String get selectOpponent => 'Selecionar adversário';

  @override
  String get selectPeriod => 'Selecionar período';

  @override
  String get selectPlayer => 'Selecionar jogador';

  @override
  String get sendTweet => 'Enviar tweet';

  @override
  String get setGameTime => 'Definir horário do jogo';

  @override
  String get setLiveLink => 'Definir link ao vivo';

  @override
  String get setLiveStreamLink => 'Definir link de transmissão ao vivo';

  @override
  String get setTeamColors => 'Definir cores da equipe';

  @override
  String get setTime => 'Definir horário';

  @override
  String get settings => 'Configurações';

  @override
  String get shareDatabase => 'Compartilhar banco de dados';

  @override
  String get shareImage => 'Compartilhar imagem';

  @override
  String get shareToSocialMedia => 'Compartilhar nas redes sociais';

  @override
  String get sharedSuccessfully => 'Compartilhado com sucesso!';

  @override
  String get shots => 'Chutes';

  @override
  String get shotsOnGoal => 'Chutes ao gol';

  @override
  String get showHighlights => 'Mostrar destaques';

  @override
  String get signIn => 'Entrar';

  @override
  String signInFailed(Object error) {
    return 'Falha no login: $error';
  }

  @override
  String get signInRequired => 'Login necessário';

  @override
  String get signInToAccessCloudDatabases =>
      'Entre para acessar bancos de dados na nuvem';

  @override
  String get signInWithApple => 'Entrar com Apple';

  @override
  String get signInWithGoogle => 'Entrar com Google';

  @override
  String get signOut => 'Sair';

  @override
  String signedInWith(Object provider) {
    return 'Conectado com $provider';
  }

  @override
  String get skip => 'Pular';

  @override
  String get soccerAnalytics => 'Análise de Futebol';

  @override
  String get startImport => 'Iniciar importação';

  @override
  String get systemDefaultLanguage => 'Padrão do sistema';

  @override
  String get systemDefaultTheme => 'Padrão do sistema';

  @override
  String get team => 'Equipe';

  @override
  String get teamAccomplishments => 'Realizações da equipe';

  @override
  String get teamId => 'ID da equipe';

  @override
  String get teamName => 'Nome da equipe';

  @override
  String get teamShortName => 'Nome curto da equipe';

  @override
  String get teamStandings => 'Classificação da equipe';

  @override
  String get teamSummary => 'Sobre a equipe';

  @override
  String get editTeamSummary => 'Editar resumo da equipe';

  @override
  String get teamSummaryHint => 'Digite uma breve descrição da sua equipe...';

  @override
  String get teamSummarySaved => 'Resumo da equipe salvo com sucesso';

  @override
  String get teamSync => 'TeamSync';

  @override
  String get teamSyncDatabaseViewer =>
      'Visualizador de banco de dados TeamSync';

  @override
  String get teamSyncViewer => 'Visualizador TeamSync';

  @override
  String get termsOfUse => 'Termos de uso';

  @override
  String get themeClassic => 'Clássico';

  @override
  String get themeDarkMode => 'Modo escuro';

  @override
  String get themeElegant => 'Elegante';

  @override
  String get themeMinimal => 'Minimalista';

  @override
  String get themeNeon => 'Neon';

  @override
  String get themeRetro => 'Retrô';

  @override
  String get thisWillMergeFollowingPlayers =>
      'Isso mesclará os seguintes jogadores:';

  @override
  String get tieAbbreviation => 'E';

  @override
  String get time => 'Hora';

  @override
  String get titleUrlRequired => 'Título e URL são obrigatórios';

  @override
  String get tweetGameDay => 'Tweetar dia do jogo';

  @override
  String get tweetSentSuccessfully => 'Tuíte enviado com sucesso!';

  @override
  String get tweetedSuccessfully => 'Tuitado com sucesso!';

  @override
  String get twitter => 'Twitter';

  @override
  String get twitterSettings => 'Configurações do Twitter';

  @override
  String get twitterSettingsSavedSuccessfully =>
      'Configurações do Twitter salvas com sucesso!';

  @override
  String get unableToOpenLink => 'Não foi possível abrir o link';

  @override
  String get unableToOpenLiveLink => 'Não foi possível abrir o link ao vivo';

  @override
  String get unexpectedDatabaseFormat => 'Formato de banco de dados inesperado';

  @override
  String get unlockButton => 'Desbloquear';

  @override
  String get update => 'Atualizar';

  @override
  String get updateButton => 'Atualizar';

  @override
  String get upgradeToPro => 'Atualizar para Pro';

  @override
  String get uploadImage => 'Carregar imagem';

  @override
  String get uploadingImage => 'Carregando imagem...';

  @override
  String get addLogo => 'Adicionar logo';

  @override
  String get changeLogo => 'Alterar logo';

  @override
  String get removeLogo => 'Remover logo';

  @override
  String get confirmRemoveLogo =>
      'Tem certeza de que deseja remover este logo?';

  @override
  String get logoUpdated => 'Logo atualizado com sucesso';

  @override
  String get logoRemoved => 'Logo removido com sucesso';

  @override
  String get useDeviceLanguage => 'Usar idioma do dispositivo';

  @override
  String get userEmail => 'E-mail do usuário';

  @override
  String get validateOnly => 'Apenas validar';

  @override
  String get videoLabel => 'Vídeo';

  @override
  String get viewMore => 'Ver mais';

  @override
  String get watchLabel => 'Assistir';

  @override
  String get welcomeToTeamSync => 'Bem-vindo ao TeamSync!';

  @override
  String get winAbbreviation => 'V';

  @override
  String get year => 'Ano';

  @override
  String get yellowCards => 'Cartões Amarelos';

  @override
  String get noGamesYet => 'Ainda não há jogos';

  @override
  String get live => 'AO VIVO';

  @override
  String get win => 'VITÓRIA';

  @override
  String get loss => 'DERROTA';

  @override
  String get tie => 'EMPATE';

  @override
  String get teamPerformance => 'Desempenho da equipe';

  @override
  String teamPerformanceSince(Object year) {
    return 'Desempenho da equipe (Desde $year)';
  }

  @override
  String get addAccomplishment => 'Adicionar realização';

  @override
  String get editAccomplishment => 'Editar realização';

  @override
  String get titleRequired => 'Título *';

  @override
  String get titleIsRequired => 'O título é obrigatório';

  @override
  String get exampleStateChampions => 'ex. Campeões estaduais';

  @override
  String get exampleYear => 'ex. 2023';

  @override
  String get saving => 'Salvando...';

  @override
  String get since => 'Desde';

  @override
  String get images => 'Imagens';

  @override
  String get tapImageToPrimary => 'Toque em uma imagem para torná-la principal';

  @override
  String get selectMultipleImages =>
      'Você pode selecionar várias imagens de uma vez';

  @override
  String get primary => 'Principal';

  @override
  String get notAuthorizedUploadImages =>
      'Não autorizado a carregar imagens. Faça login no celular para adicionar imagens.';

  @override
  String get games => 'Jogos';

  @override
  String gameTimeSet(Object time) {
    return 'Horário do jogo definido para $time';
  }

  @override
  String get noTimeSetPrompt =>
      'Este jogo não tem horário definido (atualmente 00:00). Gostaria de definir o horário antes de tweetar?';

  @override
  String get sortByTeamName => 'Nome da equipe';

  @override
  String get sortByMostGames => 'Mais jogos';

  @override
  String get sortByMostWins => 'Mais vitórias';

  @override
  String get sortByWinPercentage => '% Vitória';

  @override
  String get sortByRecent => 'Recente';

  @override
  String get noMatchupHistoryYet => 'Ainda não há histórico de confrontos';

  @override
  String get gamesSingular => 'jogo';

  @override
  String get gamesPlural => 'jogos';

  @override
  String gamesPlayed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jogos',
      one: 'jogo',
    );
    return '$count $_temp0 jogados';
  }

  @override
  String get versus => 'vs.';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get editSeasonName => 'Editar nome da temporada';

  @override
  String get seasonNameRequired => 'O nome da temporada é obrigatório';

  @override
  String get seasonNameUpdated => 'Nome da temporada atualizado com sucesso';

  @override
  String get analytics => 'Análise';

  @override
  String get avgGoalsFor => 'Média de Gols Pró';

  @override
  String get avgGoalsAgainst => 'Média de Gols Contra';

  @override
  String get biggestWin => 'Maior Vitória';

  @override
  String get biggestLoss => 'Maior Derrota';

  @override
  String get currentStreak => 'Sequência Atual';

  @override
  String get longestWinStreak => 'Maior Sequência de Vitórias';

  @override
  String get recentForm => 'Forma Recente (Últimos 5)';

  @override
  String get cleanSheets => 'Saldo Invicto';

  @override
  String get goalDifferential => 'Saldo de Gols';

  @override
  String get homeRecord => 'Recorde em Casa';

  @override
  String get awayRecord => 'Recorde Fora';

  @override
  String get pointsPerGame => 'Pontos por Jogo';

  @override
  String get shootingAccuracy => 'Precisão de Chute';

  @override
  String get comebackWins => 'Vitórias de Virada';

  @override
  String get lateGoals => 'Gols Tardios (80+)';

  @override
  String get cardsPerGame => 'Cartões por Jogo';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get scoringEvents => 'Eventos de Gol';

  @override
  String get noScoringEventsYet => 'Ainda não há eventos de gol';

  @override
  String get gameStatistics => 'Estatísticas do Jogo';

  @override
  String get shotsOnTarget => 'Chutes no Alvo';

  @override
  String get goalAnalytics => 'Análise de Gols';

  @override
  String get totalGoalsScored => 'Total de Gols Marcados';

  @override
  String get totalGoalsConceded => 'Total de Gols Sofridos';

  @override
  String get avgGoalsPerGame => 'Média Gols Por Jogo';

  @override
  String get streaksRecords => 'Sequências e Recordes';

  @override
  String get longestUnbeatenStreak => 'Maior Sequência Invicta';

  @override
  String get mostGoalsInGame => 'Mais Gols em um Jogo';

  @override
  String get biggestVictory => 'Maior Vitória';

  @override
  String get homeAwayAnalysis => 'Casa vs Fora';

  @override
  String get homeWinPercentage => '% Vitórias Casa';

  @override
  String get awayWinPercentage => '% Vitórias Fora';

  @override
  String get defensiveStats => 'Estatísticas Defensivas';

  @override
  String get cleanSheetPercentage => '% Gol Invicto';

  @override
  String get avgGoalsConceded => 'Média Gols Sofridos';

  @override
  String get shutoutsRecorded => 'Gols Invictos Registrados';

  @override
  String get allTime => 'Todos os Tempos';

  @override
  String get currentSeason => 'Temporada Atual';

  @override
  String get lastSeason => 'Última Temporada';

  @override
  String get last3Years => 'Últimas 3 Temporadas';

  @override
  String get last5Years => 'Últimas 5 Temporadas';

  @override
  String get last10Years => 'Últimas 10 Temporadas';

  @override
  String get overallStatistics => 'Estatísticas Gerais';

  @override
  String get recordSummary => 'Resumo de Recordes';

  @override
  String get totalGames => 'Total de Jogos';

  @override
  String get wins => 'Vitórias';

  @override
  String get losses => 'Derrotas';

  @override
  String get ties => 'Empates';

  @override
  String get winPercentage => '% Vitórias';
}
