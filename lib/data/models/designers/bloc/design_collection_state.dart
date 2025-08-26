import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';

class DesignCollectionState extends Equatable {
  const DesignCollectionState();
  @override
  List<Object?> get props => [];
}

class DesignCollectionInitial extends DesignCollectionState {
  const DesignCollectionInitial();
}

class DesignCollectionLoading extends DesignCollectionState {
  const DesignCollectionLoading();
}

class DesignCollectionLoaded extends DesignCollectionState {
  final DesignCollectionModel designCollection;
  const DesignCollectionLoaded(this.designCollection);

  @override
  List<Object?> get props => [designCollection];
}

class DesignCollectionsLoaded extends DesignCollectionState {
  final List<DesignCollectionModel> designCollections;
  const DesignCollectionsLoaded(this.designCollections);

  @override
  List<Object?> get props => [designCollections];
}

class DesignCollectionError extends DesignCollectionState {
  final String message;
  const DesignCollectionError(this.message);

  @override
  List<Object?> get props => [message];
}
