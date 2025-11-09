import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';

class WorkOrderBlocState extends Equatable {
  final int workOrdersCount;
  const WorkOrderBlocState({this.workOrdersCount = 0});
  @override
  List<Object?> get props => [workOrdersCount];
}

class WorkOrderInitial extends WorkOrderBlocState {
  const WorkOrderInitial({super.workOrdersCount = 0});
}

class WorkOrderLoading extends WorkOrderBlocState {
  const WorkOrderLoading({super.workOrdersCount = 0});
}

class WorkOrderLoaded extends WorkOrderBlocState {
  final WorkOrderModel workorder;
  const WorkOrderLoaded(this.workorder);

  @override
  List<Object?> get props => [workorder];
}

class WorkOrderUpdated extends WorkOrderBlocState {
  final WorkOrderModel workorder;
  const WorkOrderUpdated(this.workorder);
  
  @override
  List<Object?> get props => [workorder];
}

class WorkOrderPatched extends WorkOrderBlocState {
  final WorkOrderModel workorder;
  const WorkOrderPatched(this.workorder);
  @override
  List<Object?> get props => [workorder];
}

class WorkOrderAdded extends WorkOrderBlocState {
  final WorkOrderModel workorder;
  const WorkOrderAdded(this.workorder);
  @override
  List<Object?> get props => [workorder];
}

class WorkOrdersLoaded extends WorkOrderBlocState {
  final List<WorkOrderModel> workOrders;
  final bool fromCache;
  const WorkOrdersLoaded(this.workOrders, {this.fromCache = false})
    : super(workOrdersCount: workOrders.length);

  @override
  List<Object?> get props => [workOrders, fromCache, workOrdersCount];
}

class WorkOrdersCounted extends WorkOrderBlocState {
  const WorkOrdersCounted(int count) : super(workOrdersCount: count);
  @override
  List<Object?> get props => [workOrdersCount];
}

class WorkOrdersEmpty extends WorkOrderBlocState {
  const WorkOrdersEmpty();
}

class WorkOrderError extends WorkOrderBlocState {
  final String message;
  const WorkOrderError(this.message, {super.workOrdersCount = 0});

  @override
  List<Object?> get props => [message, workOrdersCount];
}

class WorkOrdersNewData extends WorkOrderBlocState {
  final List<WorkOrderModel> workOrders;
  const WorkOrdersNewData(this.workOrders);

  @override
  List<Object?> get props => [workOrders];
}

class WorkOrderDeleted extends WorkOrderBlocState {
  final String message;
  const WorkOrderDeleted(this.message, {super.workOrdersCount = 0});
  @override
  List<Object?> get props => [message, workOrdersCount];
}
