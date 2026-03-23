enum JobStage {
  waiting,
  going,
  arrived,
  loading,
  finished,
}

extension JobStageX on JobStage {
  String get label {
    switch (this) {
      case JobStage.waiting:
        return 'Aguardando';
      case JobStage.going:
        return 'A caminho';
      case JobStage.arrived:
        return 'Cheguei';
      case JobStage.loading:
        return 'Carregando';
      case JobStage.finished:
        return 'Finalizado';
    }
  }

  String? get actionLabel {
    switch (this) {
      case JobStage.waiting:
        return 'Sair';
      case JobStage.going:
        return 'Cheguei';
      case JobStage.arrived:
        return 'Carregar';
      case JobStage.loading:
        return 'Finalizar';
      case JobStage.finished:
        return null;
    }
  }

  JobStage? get next {
    switch (this) {
      case JobStage.waiting:
        return JobStage.going;
      case JobStage.going:
        return JobStage.arrived;
      case JobStage.arrived:
        return JobStage.loading;
      case JobStage.loading:
        return JobStage.finished;
      case JobStage.finished:
        return null;
    }
  }
}