import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';

abstract class WorkOrderBlocEvent extends Equatable {
  const WorkOrderBlocEvent();
  @override
  List<Object?> get props => [];
}

class LoadWorkOrder extends WorkOrderBlocEvent {
  final String uid;
  const LoadWorkOrder(this.uid);
  @override
  List<Object?> get props => [uid];
}

class UpdateWorkOrder extends WorkOrderBlocEvent {
  final WorkOrderModel workorder;
  const UpdateWorkOrder(this.workorder);

  @override
  List<Object?> get props => [workorder];
}

class LoadWorkOrders extends WorkOrderBlocEvent {
  final String uid;
  const LoadWorkOrders(this.uid);

  @override
  List<Object?> get props => [uid];
}

class LoadWorkOrdersCacheFirstThenNetwork extends WorkOrderBlocEvent {
  final String uid;
  const LoadWorkOrdersCacheFirstThenNetwork(this.uid);

  @override
  List<Object?> get props => [uid];
}

class WorkOrdersCounter extends WorkOrderBlocEvent {
  final String uid;
  const WorkOrdersCounter(this.uid);

  @override
  List<Object?> get props => [uid];
}

class DeleteWorkOrder extends WorkOrderBlocEvent {
  final String uid;
  const DeleteWorkOrder(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ClearWorkOrder extends WorkOrderBlocEvent {
  const ClearWorkOrder();
}
