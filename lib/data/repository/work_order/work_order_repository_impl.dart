import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/domain/repository/work_order/work_order_repository.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  @override
  Future<Either> addWorkOrderToFirestore(WorkOrderModel workOrder) {
    return sl<FirebaseWorkOrderService>().createWorkOrder(workOrder);
  }

  @override
  Future<Either> deleteWorkOrderById(String workOrderId) {
    return sl<FirebaseWorkOrderService>().deleteWorkOrder(workOrderId);
  }

  @override
  Future<Either> fetchPinnedWorkOrders() {
    return sl<FirebaseWorkOrderService>().fetchPinnedWorkOrders();
  }

  @override
  Future<Either> fetchWorkOrdersFromFirestore(String uid) {
    return sl<FirebaseWorkOrderService>().fetchWorkOrdersFromFirestore(uid);
  }

  @override
  Future<Either> findWorkOrderById(String workOrderId) {
    return sl<FirebaseWorkOrderService>().findWorkOrderById(workOrderId);
  }

  @override
  Future<Either<String, List<WorkOrderModel>>> findWorkOrdersFromFirestore(
    String uid,
  ) {
    return sl<FirebaseWorkOrderService>().findWorkOrdersFromFirestore(uid);
  }

  @override
  Future<bool> isPinnedWorkOrder(String workOrderId) {
    // TODO: implement isPinnedWorkOrder
    throw UnimplementedError();
  }

  @override
  Future<Either> pinOrUnpinWorkOrder(String workOrderId) {
    return sl<FirebaseWorkOrderService>().pinOrUnpinWorkOrder(workOrderId);
  }

  @override
  Future<Either> updateWorkOrderToFirestore(WorkOrderModel workOrder) {
    return sl<FirebaseWorkOrderService>().updateWorkOrder(workOrder);
  }
}
