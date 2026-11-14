import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/local_notification_service.dart';
import 'package:fashionista/core/service_locator/push_notification_service.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/hive/fashion_interest_cache.dart';
import 'package:fashionista/data/services/hive/hive_booking_service.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/data/services/hive/hive_closet_item_service.dart';
import 'package:fashionista/data/services/hive/hive_design_collection_service.dart';
import 'package:fashionista/data/services/hive/hive_designer_reviews_service.dart';
import 'package:fashionista/data/services/hive/hive_designers_service.dart';
import 'package:fashionista/data/services/hive/hive_notification_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_comment_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/data/services/hive/hive_upload_task_service.dart';
import 'package:fashionista/data/services/hive/hive_video_delete_token_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_status_progress_service.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Clears every trace of the signed-in account from this device.
///
/// Shared by the normal sign-out flow and account deletion so the two paths
/// cannot drift. Device notification cleanup is best-effort; caches clear after
/// Firebase sign-out succeeds, and its errors still surface on the normal
/// sign-out path.
class SessionCleanupService {
  Future<void> clearLocalSession({
    required UserBloc userBloc,
    required AuthProviderCubit authProviderCubit,
    bool signOut = true,
  }) async {
    userBloc.clear();
    authProviderCubit.setAuthState('', '', '', false);

    await _bestEffort(PushNotificationService.onSignOut);
    await _bestEffort(LocalNotificationService.cancelAll);

    if (signOut) {
      // Preserve the previous sign-out contract: a failed Firebase sign-out
      // must surface instead of navigating to sign-in with a live credential.
      await sl<SignOutUsecase>().call('');
    }

    final caches = <Future<void> Function()>[
      () => sl<HiveDesignersService>().clearCache(),
      () => sl<HiveTrendService>().clearCache(),
      () => sl<HiveBookingService>().clearCache(),
      () => sl<HiveTrendCommentService>().clearCache(),
      () => sl<HiveDesignCollectionService>().clearCache(),
      () => sl<HiveClosetItemService>().clearCache(),
      () => sl<HiveClientService>().clearCache(),
      () => sl<HiveOutfitService>().clearCache(),
      () => sl<HiveWorkOrderService>().clearCache(),
      () => sl<HiveWorkOrderStatusProgressService>().clearCache(),
      () => sl<HiveNotificationService>().clearCache(),
      () => sl<HiveDesignerReviewsService>().clearCache(),
      () => sl<HiveUploadTaskService>().clearCache(),
      () => sl<HiveVideoDeleteTokenService>().clearCache(),
      () => sl<FashionInterestCache>().clear(),
    ];

    for (final clear in caches) {
      await _bestEffort(clear);
    }

    await _bestEffort(DefaultCacheManager().emptyCache);

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // A deleted Auth user or a missing device document must not leave local
      // account data behind.
    }
  }
}
