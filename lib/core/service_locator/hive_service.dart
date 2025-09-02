import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/designers/design_collection_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
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

      designersBox = await Hive.openBox('designers_cache');
      designCollectionsBox = await Hive.openBox('design_collections_cache');
      clientsBox = await Hive.openBox('clients_cache');
      trendsBox = await Hive.openBox('trends_feed_cache');

      debugPrint('✅ Hive initialized and designersBox opened');
    } catch (e) {
      debugPrint('❌ Hive init failed: $e');
    }
  }
}
