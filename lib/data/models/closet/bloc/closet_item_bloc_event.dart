import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';

abstract class ClosetItemBlocEvent extends Equatable {
  const ClosetItemBlocEvent();

  @override
  List<Object?> get props => [];
}

class LoadClosetItem extends ClosetItemBlocEvent {
  final String uid;
  const LoadClosetItem(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateClosetItem extends ClosetItemBlocEvent {
  final ClosetItemModel closetitem;
  const UpdateClosetItem(this.closetitem);

  @override
  List<Object?> get props => [closetitem];
}

class AddClosetItem extends ClosetItemBlocEvent {
  final ClosetItemModel closetitem;
  const AddClosetItem(this.closetitem);

  @override
  List<Object?> get props => [closetitem];
}

class LoadClosetItems extends ClosetItemBlocEvent {
  final String uid;
  const LoadClosetItems(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadClosetItemsCacheFirstThenNetwork extends ClosetItemBlocEvent {
  final String uid;
  const LoadClosetItemsCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteClosetItem extends ClosetItemBlocEvent {
  final ClosetItemModel closetItemModel;
  const DeleteClosetItem(this.closetItemModel);

  @override
  List<Object?> get props => [closetItemModel];
}

class ClearClosetItem extends ClosetItemBlocEvent {
  const ClearClosetItem();
}
