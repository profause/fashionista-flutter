import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';

abstract class DesignCollectionBlocEvent extends Equatable {
  const DesignCollectionBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadDesignCollection extends DesignCollectionBlocEvent {
  final String uid;
  const LoadDesignCollection(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadDesignCollections extends DesignCollectionBlocEvent {
  final String uid;
  const LoadDesignCollections(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadDesignCollectionsCacheFirstThenNetwork
    extends DesignCollectionBlocEvent {
  final String uid;
  const LoadDesignCollectionsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateDesignCollection extends DesignCollectionBlocEvent {
  final DesignCollectionModel designCollection;
  const UpdateDesignCollection(this.designCollection);

  @override
  List<Object?> get props => [designCollection];
}

class DeleteDesignCollection extends DesignCollectionBlocEvent {
  final DesignCollectionModel designCollection;
  const DeleteDesignCollection(this.designCollection);

  @override
  List<Object?> get props => [designCollection];
}

class ClearDesignCollection extends DesignCollectionBlocEvent {
  const ClearDesignCollection();
}
