import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';

abstract class DesignerBlocEvent extends Equatable {
  const DesignerBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadDesigner extends DesignerBlocEvent {
  final String uid;
  const LoadDesigner(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadDesigners extends DesignerBlocEvent {
  const LoadDesigners();

  @override
  List<Object?> get props => [];
}

class LoadDesignersCacheFirstThenNetwork extends DesignerBlocEvent {
  const LoadDesignersCacheFirstThenNetwork();

  @override
  List<Object?> get props => [];
}

class UpdateDesigner extends DesignerBlocEvent {
  final Designer designer;
  const UpdateDesigner(this.designer);

  @override
  List<Object?> get props => [designer];
}

class UpdateDesigners extends DesignerBlocEvent {
  final List<Designer> designers;
  const UpdateDesigners(this.designers);

  @override
  List<Object?> get props => [designers];
}

class ClearDesigner extends DesignerBlocEvent {
  const ClearDesigner();
}
