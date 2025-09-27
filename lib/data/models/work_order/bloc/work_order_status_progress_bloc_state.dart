import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';

class WorkOrderStatusProgressBlocState extends Equatable {
  final int progressCount;
  const WorkOrderStatusProgressBlocState({this.progressCount = 0});
  @override
  List<Object?> get props => [progressCount];
}

class WorkOrderProgressInitial extends WorkOrderStatusProgressBlocState {
  const WorkOrderProgressInitial({super.progressCount = 0});
}

class WorkOrderProgressLoading extends WorkOrderStatusProgressBlocState {
  const WorkOrderProgressLoading({super.progressCount = 0});
}

class WorkOrderStatusProgressLoaded extends WorkOrderStatusProgressBlocState {
  final WorkOrderStatusProgressModel workOrderProgress;
  const WorkOrderStatusProgressLoaded(this.workOrderProgress);

  @override
  List<Object?> get props => [workOrderProgress];
}

class WorkOrderProgressUpdated extends WorkOrderStatusProgressBlocState {
  final WorkOrderStatusProgressModel workOrderProgress;
  const WorkOrderProgressUpdated(this.workOrderProgress);
  @override
  List<Object?> get props => [workOrderProgress];
}

class WorkOrderProgressLoaded extends WorkOrderStatusProgressBlocState {
  final List<WorkOrderStatusProgressModel> workOrderProgress;
  final bool fromCache;
  const WorkOrderProgressLoaded(
    this.workOrderProgress, {
    this.fromCache = false,
  }) : super(progressCount: workOrderProgress.length);

  @override
  List<Object?> get props => [
    workOrderProgress,
    fromCache,
    WorkOrderStatusProgressBlocState,
  ];
}

class WorkOrderProgressCounted extends WorkOrderStatusProgressBlocState {
  const WorkOrderProgressCounted(int count) : super(progressCount: count);
  @override
  List<Object?> get props => [progressCount];
}

class WorkOrderProgressEmpty extends WorkOrderStatusProgressBlocState {
  const WorkOrderProgressEmpty();
}

class WorkOrderProgressError extends WorkOrderStatusProgressBlocState {
  final String message;
  const WorkOrderProgressError(this.message, {super.progressCount = 0});

  @override
  List<Object?> get props => [message, progressCount];
}

class WorkOrderProgressDeleted extends WorkOrderStatusProgressBlocState {
  final String message;
  const WorkOrderProgressDeleted(this.message, {super.progressCount = 0});
  @override
  List<Object?> get props => [message, progressCount];
}
