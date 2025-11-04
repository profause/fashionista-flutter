import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';

class ClosetItemBlocState extends Equatable {
  final int itemCount;
  const ClosetItemBlocState({this.itemCount = 0});
  @override
  List<Object?> get props => [itemCount];
}

class ClosetItemInitial extends ClosetItemBlocState {
  const ClosetItemInitial({super.itemCount = 0});
}

class ClosetItemLoading extends ClosetItemBlocState {
  const ClosetItemLoading({super.itemCount = 0});
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

class ClosetItemAdded extends ClosetItemBlocState {
  final ClosetItemModel closetitem;
  const ClosetItemAdded(this.closetitem);
  @override
  List<Object?> get props => [closetitem];
}

class ClosetItemsLoaded extends ClosetItemBlocState {
  final List<ClosetItemModel> closetItems;
  final bool fromCache;
  const ClosetItemsLoaded(this.closetItems, {this.fromCache = false})
    : super(itemCount: closetItems.length);

  @override
  List<Object?> get props => [closetItems, fromCache, itemCount];
}

class ClosetItemsEmpty extends ClosetItemBlocState {
  const ClosetItemsEmpty({super.itemCount = 0});
}

class ClosetItemError extends ClosetItemBlocState {
  final String message;
  const ClosetItemError(this.message, {super.itemCount = 0});

  @override
  List<Object?> get props => [message, itemCount];
}

class ClosetItemsNewData extends ClosetItemBlocState {
  final List<ClosetItemModel> closetitems;
  const ClosetItemsNewData(this.closetitems);

  @override
  List<Object?> get props => [closetitems];
}

class ClosetItemDeleted extends ClosetItemBlocState {
  final String message;
  const ClosetItemDeleted(this.message, {super.itemCount = 0});
  @override
  List<Object?> get props => [message, itemCount];
}
