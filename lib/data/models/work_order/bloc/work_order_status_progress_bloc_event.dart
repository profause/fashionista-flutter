import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';

abstract class WorkOrderStatusProgressBlocEvent extends Equatable {
  const WorkOrderStatusProgressBlocEvent();
  @override
  List<Object?> get props => [];
}

class LoadStatusProgress extends WorkOrderStatusProgressBlocEvent {
  final String uid;
  const LoadStatusProgress(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateStatusProgress extends WorkOrderStatusProgressBlocEvent {
  final WorkOrderStatusProgressModel workOrderStatusProgressModel;
  const UpdateStatusProgress(this.workOrderStatusProgressModel);

  @override
  List<Object?> get props => [workOrderStatusProgressModel];
}

class LoadWorkOrderProgress extends WorkOrderStatusProgressBlocEvent {
  final String uid;
  const LoadWorkOrderProgress(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadWorkOrderProgressCacheFirstThenNetwork
    extends WorkOrderStatusProgressBlocEvent {
  final String uid;
  const LoadWorkOrderProgressCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class WorkOrderProgressCounter extends WorkOrderStatusProgressBlocEvent {
  final String uid;
  const WorkOrderProgressCounter(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteWorkOrderProgress extends WorkOrderStatusProgressBlocEvent {
  final String uid;
  const DeleteWorkOrderProgress(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearWorkOrderProgress extends WorkOrderStatusProgressBlocEvent {
  const ClearWorkOrderProgress();
}
