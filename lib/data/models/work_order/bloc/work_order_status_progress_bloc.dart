import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_event.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_status_progress_bloc_state.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_status_progress_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkOrderStatusProgressBloc
    extends
        Bloc<
          WorkOrderStatusProgressBlocEvent,
          WorkOrderStatusProgressBlocState
        > {
  WorkOrderStatusProgressModel? _current; // 🔑 hold latest work order draft

  WorkOrderStatusProgressBloc() : super(const WorkOrderProgressInitial()) {
    on<LoadWorkOrderProgress>(_onLoadWorkOrderProgress);
    on<LoadStatusProgress>(_onLoadStatusProgress);
    on<UpdateStatusProgress>(_updateStatusProgress);
    on<DeleteWorkOrderProgress>(_deleteWorkOrderStatusProgress);
    on<LoadWorkOrderProgressCacheFirstThenNetwork>(
      _onLoadWorkOrderProgressCacheFirstThenNetwork,
    );
    on<WorkOrderProgressCounter>(_onCountWorkOrderProgress);
  }

  Future<void> _onLoadWorkOrderProgress(
    LoadWorkOrderProgress event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    emit(const WorkOrderProgressLoading());

    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrderStatusProgressById(event.uid);

    result.fold((failure) => emit(WorkOrderProgressError(failure.toString())), (
      workOrderProgress,
    ) {
      _current = workOrderProgress;
      emit(WorkOrderStatusProgressLoaded(workOrderProgress));
    });
  }

  Future<void> _deleteWorkOrderStatusProgress(
    DeleteWorkOrderProgress event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    final result = await sl<FirebaseWorkOrderService>()
        .deleteWorkOrderStatusProgress(event.uid);
    result.fold((l) => null, (r) => emit(WorkOrderProgressDeleted(r)));
  }

  Future<void> _onLoadStatusProgress(
    LoadStatusProgress event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    emit(const WorkOrderProgressLoading());

    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrderProgressFromFirestore(event.uid);

    result.fold((failure) => emit(WorkOrderProgressError(failure.toString())), (
      statusProgress,
    ) {
      if (statusProgress.isEmpty) {
        emit(const WorkOrderProgressEmpty());
      } else {
        emit(WorkOrderProgressLoaded(statusProgress));
      }
    });
  }

  Future<void> _updateStatusProgress(
    UpdateStatusProgress event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    // 🔑 merge with existing draft
    if (_current == null) {
      _current = event.workOrderStatusProgressModel;
    } else {
      _current = _current!.copyWith();
    }

    emit(WorkOrderProgressUpdated(_current!));
  }

  Future<void> _onCountWorkOrderProgress(
    WorkOrderProgressCounter event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    String uid = event.uid;
   final cachedItems = await sl<HiveWorkOrderStatusProgressService>().getItems(uid);
    emit(WorkOrderProgressCounted(cachedItems.length));
  }

  Future<void> _onLoadWorkOrderProgressCacheFirstThenNetwork(
    LoadWorkOrderProgressCacheFirstThenNetwork event,
    Emitter<WorkOrderStatusProgressBlocState> emit,
  ) async {
    String uid = event.uid;
    emit(const WorkOrderProgressLoading());

    final cachedItems = await sl<HiveWorkOrderStatusProgressService>().getItems(uid);

    if (cachedItems.isNotEmpty) {
      emit(WorkOrderProgressLoaded(cachedItems, fromCache: true));
    }

    final result = await sl<FirebaseWorkOrderService>()
        .findWorkOrderProgressFromFirestore(uid);

    result.fold(
      (failure) async {
        if (cachedItems.isEmpty) {
          emit(WorkOrderProgressError(failure.toString()));
        }
      },
      (statusProgress) async {
        if (statusProgress.isEmpty) {
          if (cachedItems.isEmpty) {
            emit(const WorkOrderProgressEmpty());
          }
          return;
        }

        if (cachedItems.toString() != statusProgress.toString()) {
          emit(WorkOrderProgressLoaded(statusProgress, fromCache: false));
          await sl<HiveWorkOrderStatusProgressService>().insertItems(uid, items: statusProgress);
        } else {
          emit(WorkOrderProgressLoaded(cachedItems, fromCache: true));
        }
      },
    );
  }
}
