import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkOrderBloc extends Bloc<WorkOrderBlocEvent, WorkOrderBlocState> {
  WorkOrderModel? _current; // 🔑 hold latest work order draft

  WorkOrderBloc() : super(const WorkOrderInitial()) {
    on<LoadWorkOrder>(_onLoadWorkOrder);
    on<LoadWorkOrders>(_onLoadWorkOrders);
    on<UpdateWorkOrder>(_updateWorkOrder);
    on<DeleteWorkOrder>(_deleteWorkOrder);
    on<LoadWorkOrdersCacheFirstThenNetwork>(
      _onLoadWorkOrdersCacheFirstThenNetwork,
    );
    on<LoadWorkOrdersByClientId>(_onLoadWorkOrdersByClientId);
    on<ClearWorkOrder>(_onClearWorkOrder);
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

    result.fold((failure) => emit(WorkOrderError(failure.toString())), (
      workorder,
    ) {
      _current = workorder;
      emit(WorkOrderLoaded(workorder));
    });
  }

  Future<void> _deleteWorkOrder(
    DeleteWorkOrder event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    final result = await sl<FirebaseWorkOrderService>().deleteWorkOrder(
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
    // 🔑 merge with existing draft
    if (_current == null) {
      _current = event.workorder;
    } else {
      _current = _current!.copyWith(
        title: event.workorder.title,
        description: event.workorder.description,
        dueDate: event.workorder.dueDate,
        client: event.workorder.client,
        tags: event.workorder.tags,
        status: event.workorder.status,
        featuredMedia: event.workorder.featuredMedia,
        isBookmarked: event.workorder.isBookmarked,
        startDate: event.workorder.startDate,
        updatedAt: event.workorder.updatedAt,
        createdBy: event.workorder.createdBy,
        createdAt: event.workorder.createdAt,
        uid: event.workorder.uid,
      );
    }

    emit(WorkOrderUpdated(_current!));
  }

  Future<void> _onCountWorkOrders(
    WorkOrdersCounter event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    String uid = event.uid;
    final cachedItems = await sl<HiveWorkOrderService>().getItems(uid);

    emit(WorkOrdersCounted(cachedItems.length));
  }

  Future<void> _onLoadWorkOrdersCacheFirstThenNetwork(
    LoadWorkOrdersCacheFirstThenNetwork event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = us.uid;
    }
    emit(const WorkOrderLoading());

    final cachedItems = await sl<HiveWorkOrderService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(WorkOrdersLoaded(cachedItems, fromCache: true));
    }

    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrdersFromFirestore(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(WorkOrderError(failure.toString()));
        }
      },
      (workorders) async {
        if (workorders.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const WorkOrdersEmpty());
          }
          return;
        }

        if (cachedItems.toString() != workorders.toString()) {
          emit(WorkOrdersLoaded(workorders, fromCache: false));
          await sl<HiveWorkOrderService>().insertItems(uid, items: workorders);
        } else {
          emit(WorkOrdersLoaded(cachedItems, fromCache: true));
        }
      },
    );
  }

  Future<void> _onLoadWorkOrdersByClientId(
    LoadWorkOrdersByClientId event,
    Emitter<WorkOrderBlocState> emit,
  ) async {
    String uid = event.uid;
    final us = FirebaseAuth.instance.currentUser;
    if (us != null) {
      uid = us.uid;
    }
    emit(const WorkOrderLoading());

    final cachedItems = await sl<HiveWorkOrderService>().getItems(uid);

    if (cachedItems.isEmpty) {
      emit(const WorkOrdersEmpty());
      return;
    }

    final workOrderItems = cachedItems.where(
      (WorkOrderModel item) => item.client!.uid == event.uid,
    ).toList();

    if (workOrderItems.isEmpty) {
      emit(const WorkOrdersEmpty());
      return;
    }
    if (workOrderItems.isNotEmpty) {
      emit(WorkOrdersLoaded(workOrderItems, fromCache: true));
    }
  }

  void _onClearWorkOrder(
    ClearWorkOrder event,
    Emitter<WorkOrderBlocState> emit,
  ) {
    _current = null; // reset draft
    emit(const WorkOrderInitial());
  }
}
