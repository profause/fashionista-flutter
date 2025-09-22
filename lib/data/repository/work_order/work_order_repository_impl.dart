import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/domain/repository/work_order/work_order_repository.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository{
  
  @override
  Future<Either> addWorkOrderToFirestore(WorkOrderModel workOrder) {
    // TODO: implement addWorkOrderToFirestore
    throw UnimplementedError();
  }

  @override
  Future<Either> deleteWorkOrderById(String workOrderId) {
    // TODO: implement deleteWorkOrderById
    throw UnimplementedError();
  }

  @override
  Future<Either> fetchPinnedWorkOrders(List<String> workOrderIdS) {
    // TODO: implement fetchPinnedWorkOrders
    throw UnimplementedError();
  }

  @override
  Future<Either> fetchWorkOrdersFromFirestore(String uid) {
    // TODO: implement fetchWorkOrdersFromFirestore
    throw UnimplementedError();
  }

  @override
  Future<Either> findWorkOrderById(String workOrderId) {
    // TODO: implement findWorkOrderById
    throw UnimplementedError();
  }

  @override
  Future<Either<String, List<WorkOrderModel>>> findWorkOrdersFromFirestore(String uid) {
    // TODO: implement findWorkOrdersFromFirestore
    throw UnimplementedError();
  }

  @override
  Future<bool> isPinnedWorkOrder(String workOrderId) {
    // TODO: implement isPinnedWorkOrder
    throw UnimplementedError();
  }

  @override
  Future<Either> pinOrUnpinWorkOrder(String workOrderId) {
    // TODO: implement pinOrUnpinWorkOrder
    throw UnimplementedError();
  }

  @override
  Future<Either> updateWorkOrderToFirestore(WorkOrderModel workOrder) {
    // TODO: implement updateWorkOrderToFirestore
    throw UnimplementedError();
  }

}