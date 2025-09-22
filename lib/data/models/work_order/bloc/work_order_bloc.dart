import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkOrderBloc extends Bloc<WorkOrderBlocEvent, WorkOrderBlocState> {
  WorkOrderBloc() : super(const WorkOrderInitial()) {
    on<LoadWorkOrder>(_onLoadWorkOrder);
    on<LoadWorkOrders>(_onLoadWorkOrders);
    on<UpdateWorkOrder>(_updateWorkOrder);
    on<DeleteWorkOrder>(_deleteWorkOrder);
    on<LoadWorkOrdersCacheFirstThenNetwork>(
      _onLoadWorkOrdersCacheFirstThenNetwork,
    );
    on<ClearWorkOrder>((event, emit) => emit(const WorkOrderInitial()));
    on<WorkOrdersCounter>(_onCountWorkOrders);
  }

  Future<void> _onLoadWorkOrder(
    LoadWorkOrder event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    emit(const WorkOrderLoading());

    final result = await sl<FirebaseWorkOrderService>().findWorkOrderById(
      event.uid,
    );

    result.fold(
      (failure) => emit(WorkOrderError(failure.toString())),
      (workorder) => emit(WorkOrderLoaded(workorder)),
    );
  }

  Future<void> _deleteWorkOrder(
    DeleteWorkOrder event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    var result = await sl<FirebaseWorkOrderService>().deleteWorkOrder(
      event.uid,
    );
    result.fold((l) => null, (r) => emit(WorkOrderDeleted(r)));
  }

  Future<void> _onLoadWorkOrders(
    LoadWorkOrders event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    emit(const WorkOrderLoading());

    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrdersFromFirestore(event.uid);

    result.fold((failure) => emit(WorkOrderError(failure.toString())), (
      workorders,
    ) {
      if (workorders.isEmpty) {
        emit(const WorkOrdersEmpty());
      } else {
        emit(WorkOrdersLoaded(workorders));
      }
    });
  }

  Future<void> _updateWorkOrder(
    UpdateWorkOrder event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    emit(WorkOrderLoading());
    emit(WorkOrderUpdated(event.workorder));
    //emit(WorkOrderLoaded(event.workorder));
  }

  Future<void> _onCountWorkOrders(
    WorkOrdersCounter event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    // 1️⃣ Try cache first
    String uid = event.uid;
    final cachedItems = await sl<HiveWorkOrderService>().getItems(uid);

    if (cachedItems.isEmpty) {
      emit(WorkOrdersCounted(0));
      return;
    }
    emit(WorkOrdersCounted(cachedItems.length));
  }

  Future<void> _onLoadWorkOrdersCacheFirstThenNetwork(
    LoadWorkOrdersCacheFirstThenNetwork event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
    }
    emit(const WorkOrderLoading());
    // 1️⃣ Try cache first
    final cachedItems = await sl<HiveWorkOrderService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(WorkOrdersLoaded(cachedItems, fromCache: true));
    }

    // 2️⃣ Fetch from network
    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrdersFromFirestore(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(WorkOrderError(failure.toString()));
        }
        // else → keep showing cached quietly
      },
      (workorders) async {
        try {
          if (workorders.isEmpty) {
            if (cachedItems.isEmpty) {
              emit(const WorkOrdersEmpty());
            }
            return;
          }
          if (cachedItems.toString() != workorders.toString()) {
            emit(WorkOrdersLoaded(workorders, fromCache: false));
            // 4️⃣ Update cache and emit fresh data
            await sl<HiveWorkOrderService>().insertItems(
              uid,
              items: workorders,
            );
          } else {
            // no change
            emit(WorkOrdersLoaded(cachedItems, fromCache: true));
          }
        } catch (e) {
          if (emit.isDone) return; // <- safeguard
          emit(WorkOrderError(e.toString()));
        }
      },
    );
  }
}
