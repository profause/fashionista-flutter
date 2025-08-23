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

class UpdateDesigner extends DesignerBlocEvent {
  final Designer designer;
  const UpdateDesigner(this.designer);

  @override
  List<Object?> get props => [designer];
}

class ClearDesigner extends DesignerBlocEvent {
  const ClearDesigner();
}
