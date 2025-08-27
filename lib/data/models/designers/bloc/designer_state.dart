import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';

abstract class DesignerState extends Equatable {
  const DesignerState();

  @override
  List<Object?> get props => [];
}

class DesignerInitial extends DesignerState {
  const DesignerInitial();
}

class DesignerLoading extends DesignerState {
  const DesignerLoading();
}

class DesignerLoaded extends DesignerState {
  final Designer designer;
  const DesignerLoaded(this.designer);

  @override
  List<Object?> get props => [designer];
}

class DesignerError extends DesignerState {
  final String message;
  const DesignerError(this.message);

  @override
  List<Object?> get props => [message];
}

class DesignersLoaded extends DesignerState {
  final List<Designer> designers;
  const DesignersLoaded(this.designers);

  @override
  List<Object?> get props => [designers];
}

class DesignerEmpty extends DesignerState {
  const DesignerEmpty();
}
