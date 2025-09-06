import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';

class ClosetItemBlocState extends Equatable {
  const ClosetItemBlocState();
  @override
  List<Object?> get props => [];
}

class ClosetItemInitial extends ClosetItemBlocState {
  const ClosetItemInitial();
}

class ClosetItemLoading extends ClosetItemBlocState {
  const ClosetItemLoading();
}

class ClosetItemLoaded extends ClosetItemBlocState {
  final ClosetItemModel closetitem;
  const ClosetItemLoaded(this.closetitem);

  @override
  List<Object?> get props => [closetitem];
}

class ClosetItemUpdated extends ClosetItemBlocState {
  final ClosetItemModel closetitem;
  const ClosetItemUpdated(this.closetitem);
  @override
  List<Object?> get props => [closetitem];
}

class ClosetItemsLoaded extends ClosetItemBlocState {
  final List<ClosetItemModel> closetItems;
  final bool fromCache;
  const ClosetItemsLoaded(this.closetItems, {this.fromCache = false});

  @override
  List<Object?> get props => [closetItems];
}

class ClosetItemsEmpty extends ClosetItemBlocState {
  const ClosetItemsEmpty();
}

class ClosetItemError extends ClosetItemBlocState {
  final String message;
  const ClosetItemError(this.message);

  @override
  List<Object?> get props => [message];
}

class ClosetItemsNewData extends ClosetItemBlocState {
  final List<ClosetItemModel> closetitems;
  const ClosetItemsNewData(this.closetitems);

  @override
  List<Object?> get props => [closetitems];
}

class ClosetItemDeleted extends ClosetItemBlocState {
  final String message;
  const ClosetItemDeleted(this.message);
  @override
  List<Object?> get props => [message];
}
