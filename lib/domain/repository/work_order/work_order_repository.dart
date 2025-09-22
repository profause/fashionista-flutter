import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';

abstract class WorkOrderRepository {
  Future<Either> fetchWorkOrdersFromFirestore(String uid);
  Future<Either<String, List<WorkOrderModel>>> findWorkOrdersFromFirestore(
    String uid,
  );
  Future<Either> addWorkOrderToFirestore(WorkOrderModel workOrder);
  Future<Either> updateWorkOrderToFirestore(WorkOrderModel workOrder);
  Future<Either> deleteWorkOrderById(String workOrderId);
  Future<Either> findWorkOrderById(String workOrderId);

  Future<bool> isPinnedWorkOrder(String workOrderId);
  Future<Either> pinOrUnpinWorkOrder(String workOrderId);
  Future<Either> fetchPinnedWorkOrders();
}
