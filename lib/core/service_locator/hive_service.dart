import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/closet/closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_closet_item_model.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/models/work_order/work_order_status_progress_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  // 👇 private constructor
  HiveService._internal();

  // 👇 single instance
  static final HiveService _instance = HiveService._internal();

  // 👇 getter to access instance
  factory HiveService() => _instance;

  late final Box designersBox;
  late final Box designCollectionsBox;
  late final Box clientsBox;
  late final Box trendsBox;
  late final Box trendCommentsBox;
  late final Box closetBox;
  late final Box userInterestsBox;
  late final Box workOrderBox;
  late final Box workOrderStatusProgressBox;
  late final Box designerReviewsBox;
  late final Box<NotificationModel> notificationsBox;

  /// Initialize Hive + boxes (call once at startup)
  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path); // safe for mobile/web/desktop
      Hive.registerAdapter(DesignCollectionModelAdapter());
      Hive.registerAdapter(DesignerAdapter());
      Hive.registerAdapter(SocialHandleAdapter());
      Hive.registerAdapter(ClientAdapter());
      Hive.registerAdapter(ClientMeasurementAdapter());
      Hive.registerAdapter(AuthorModelAdapter());
      Hive.registerAdapter(TrendFeedModelAdapter());
      Hive.registerAdapter(FeaturedMediaModelAdapter());
      Hive.registerAdapter(SocialInteractionModelAdapter());
      Hive.registerAdapter(CommentModelAdapter());
      Hive.registerAdapter(ClosetItemModelAdapter());
      Hive.registerAdapter(OutfitModelAdapter());
      Hive.registerAdapter(OutfitClosetItemAdapter());
      Hive.registerAdapter(WorkOrderModelAdapter());
      Hive.registerAdapter(WorkOrderStatusProgressModelAdapter());
      Hive.registerAdapter(DesignerReviewModelAdapter());
      Hive.registerAdapter(NotificationModelAdapter());

      designersBox = await Hive.openBox('designers_cache');
      designCollectionsBox = await Hive.openBox('design_collections_cache');
      clientsBox = await Hive.openBox('clients_cache');
      trendsBox = await Hive.openBox('trends_feed_cache');
      trendCommentsBox = await Hive.openBox('trend_comments_cache');
      closetBox = await Hive.openBox('closet_cache');
      userInterestsBox = await Hive.openBox('user_interests_cache');
      workOrderBox = await Hive.openBox('work_orders_cache');
      workOrderStatusProgressBox = await Hive.openBox(
        'work_orders_status_progress_cache',
      );
      designerReviewsBox = await Hive.openBox('designer_reviews_cache');
      notificationsBox = await Hive.openBox('notifications_cache');

      debugPrint('✅ Hive initialized');
    } catch (e) {
      debugPrint('❌ Hive init failed: $e');
    }
  }
}
