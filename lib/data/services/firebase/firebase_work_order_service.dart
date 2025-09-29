import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseWorkOrderService {
  Future<Either> createWorkOrder(WorkOrderModel workOrder);
  Future<Either> updateWorkOrder(WorkOrderModel workOrder);
  Future<Either> deleteWorkOrder(String workOrderId);
  Future<Either> pinOrUnpinWorkOrder(String workOrderId);
  Future<Either> fetchPinnedWorkOrders();
  Future<Either<String, WorkOrderModel>> findWorkOrderById(String workOrderId);
  Future<Either> fetchWorkOrdersFromFirestore(String uid);
  Future<Either<String, List<WorkOrderModel>>> findWorkOrdersFromFirestore(
    String uid,
  );
  Future<Either<String, int>> getCount(String uid);
  Future<Either<String, WorkOrderStatusProgressModel>>
  findWorkOrderStatusProgressById(String workOrderId);
  Future<Either> createWorkOrderStatusProgress(
    WorkOrderStatusProgressModel workOrderStatusProgress,
  );
  Future<Either> updateWorkOrderStatusProgress(
    WorkOrderStatusProgressModel workOrderStatusProgress,
  );

  Future<Either<String, List<WorkOrderStatusProgressModel>>>
  findWorkOrderProgressFromFirestore(String uid);

  Future<Either> deleteWorkOrderStatusProgress(
    String workOrderStatusProgressId,
  );
}

class FirebaseWorkOrderServiceImpl implements FirebaseWorkOrderService {
  @override
  Future<Either> createWorkOrder(WorkOrderModel workOrder) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('work_orders')
          .doc(workOrder.uid)
          .set(workOrder.toJson(), SetOptions(merge: true));
      return Right(workOrder);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteWorkOrder(String workOrderId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore.collection('work_orders').doc(workOrderId).delete();
      return const Right(
        'successfully deleted work order',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> fetchPinnedWorkOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left('No user logged in');
      }
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('work_orders')
          .where('created_by', isEqualTo: userId)
          .where('is_bookmarked', isEqualTo: true)
          .orderBy('created_date', descending: true)
          .get();

      final workOrders = querySnapshot.docs.map((doc) {
        final d = WorkOrderModel.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a WorkOrderModel
      return Right(workOrders);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<WorkOrderModel>>> findWorkOrdersFromFirestore(
    String uid,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('work_orders')
          .where('created_by', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final workOrders = querySnapshot.docs.map((doc) {
        final d = WorkOrderModel.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a WorkOrderModel
      return Right(workOrders);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> fetchWorkOrdersFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('work_orders')
          .where('created_by', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final workOrders = querySnapshot.docs.map((doc) {
        final d = WorkOrderModel.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a WorkOrderModel
      return Right(workOrders);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, WorkOrderModel>> findWorkOrderById(
    String workOrderId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('work_orders')
          .doc(workOrderId);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('work order not found');
      }
      WorkOrderModel workOrderModel = WorkOrderModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return Right(workOrderModel);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either<String, int>> getCount(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('work_orders')
          .where('created_by', isEqualTo: uid)
          .count()
          .get();

      final clientsCount = querySnapshot.count;

      //await importTrends(sampleTrendsData);
      return Right(clientsCount ?? 0);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either> pinOrUnpinWorkOrder(String workOrderId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('work_orders')
          .doc(workOrderId);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('work order not found');
      }
      WorkOrderModel workOrderModel = WorkOrderModel.fromJson(
        doc.data() as Map<String, dynamic>,
      );
      bool isBookmarked = workOrderModel.isBookmarked ?? false;
      workOrderModel = workOrderModel.copyWith(isBookmarked: !isBookmarked);
      updateWorkOrder(workOrderModel);

      return Right(workOrderModel.isBookmarked);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either> updateWorkOrder(WorkOrderModel workOrder) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('work_orders')
          .doc(workOrder.uid)
          .set(workOrder.toJson(), SetOptions(merge: true));
      return Right(workOrder);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> createWorkOrderStatusProgress(
    WorkOrderStatusProgressModel workOrderStatusProgress,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('work_order_status_progress')
          .doc(workOrderStatusProgress.uid)
          .set(workOrderStatusProgress.toJson(), SetOptions(merge: true));
      return Right(workOrderStatusProgress);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }

  @override
  Future<Either> deleteWorkOrderStatusProgress(
    String workOrderStatusProgressId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete the document with the given uid
      await firestore
          .collection('work_order_status_progress')
          .doc(workOrderStatusProgressId)
          .delete();
      return const Right(
        'successfully deleted work order status progress',
      ); // success without data
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Unknown Firestore error');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<WorkOrderStatusProgressModel>>>
  findWorkOrderProgressFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('work_order_status_progress')
          .where('work_order_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final workOrderStatus = querySnapshot.docs.map((doc) {
        final d = WorkOrderStatusProgressModel.fromJson(doc.data());
        return d;
      }).toList();

      // Map each document to a WorkOrderStatusProgressModel
      return Right(workOrderStatus);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'An unknown Firebase error occurred');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, WorkOrderStatusProgressModel>>
  findWorkOrderStatusProgressById(String workOrderStatusProgressId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef = firestore
          .collection('work_order_status_progress')
          .doc(workOrderStatusProgressId);
      DocumentSnapshot doc = await docRef.get();
      if (!doc.exists) {
        return Left('work order status not found');
      }
      WorkOrderStatusProgressModel workOrderStatusProgressModel =
          WorkOrderStatusProgressModel.fromJson(
            doc.data() as Map<String, dynamic>,
          );

      return Right(workOrderStatusProgressModel);
    } on FirebaseException catch (e) {
      return Left(e.message!);
    }
  }

  @override
  Future<Either> updateWorkOrderStatusProgress(
    WorkOrderStatusProgressModel workOrderStatusProgress,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      firestore
          .collection('work_order_status_progress')
          .doc(workOrderStatusProgress.uid)
          .set(workOrderStatusProgress.toJson(), SetOptions(merge: true));
      return Right(workOrderStatusProgress);
    } on FirebaseException catch (e) {
      return Left(e.message);
    }
  }
}
