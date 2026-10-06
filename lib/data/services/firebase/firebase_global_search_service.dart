import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fashionista/core/service_locator/hive_service.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';

enum GlobalSearchCategory {
  all,
  interests,
  trends,
  users,
  designers,
  outfits,
  workOrders,
  clients,
}

class GlobalSearchResult {
  final String id;
  final GlobalSearchCategory category;
  final String title;
  final String subtitle;
  final String? route;
  final Designer? designer;

  const GlobalSearchResult({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.route,
    this.designer,
  });

  String get searchableText => '$title $subtitle'.toLowerCase();

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'subtitle': subtitle,
    'route': route,
    if (designer != null) 'designer': designer!.toJson(),
  };

  factory GlobalSearchResult.fromCacheJson(Map<String, dynamic> json) {
    final designerData = json['designer'];
    return GlobalSearchResult(
      id: json['id']?.toString() ?? '',
      category: GlobalSearchCategory.values.byName(
        json['category']?.toString() ?? GlobalSearchCategory.all.name,
      ),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      route: json['route']?.toString(),
      designer: designerData is Map
          ? Designer.fromJson(Map<String, dynamic>.from(designerData))
          : null,
    );
  }
}

class FirebaseGlobalSearchService {
  static const int cachedResultLimit = 12;

  Future<List<GlobalSearchResult>> loadCachedResults(String userId) async {
    final cachedJson = HiveService().globalSearchBox.get(userId);
    if (cachedJson == null || cachedJson.isEmpty) return [];

    try {
      final decoded = jsonDecode(cachedJson) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => GlobalSearchResult.fromCacheJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      await HiveService().globalSearchBox.delete(userId);
      return [];
    }
  }

  Future<void> cacheResults(
    String userId,
    List<GlobalSearchResult> results,
  ) async {
    if (results.isEmpty) return;
    final cachedResults = results.take(cachedResultLimit).toList();
    await HiveService().globalSearchBox.put(
      userId,
      jsonEncode(cachedResults.map((result) => result.toCacheJson()).toList()),
    );
  }

  List<GlobalSearchResult> pickRandomSuggestions(
    List<GlobalSearchResult> index, {
    int count = 10,
  }) {
    final random = Random();
    final byCategory = <GlobalSearchCategory, List<GlobalSearchResult>>{};
    for (final category in GlobalSearchCategory.values.where(
      (category) => category != GlobalSearchCategory.all,
    )) {
      final candidates = index
          .where((result) => result.category == category)
          .toList()
        ..shuffle(random);
      if (candidates.isNotEmpty) byCategory[category] = candidates;
    }

    final categories = byCategory.keys.toList()..shuffle(random);
    final suggestions = <GlobalSearchResult>[];
    while (suggestions.length < count && categories.isNotEmpty) {
      for (final category in List<GlobalSearchCategory>.from(categories)) {
        if (suggestions.length >= count) break;
        final candidates = byCategory[category]!;
        suggestions.add(candidates.removeLast());
        if (candidates.isEmpty) categories.remove(category);
      }
    }
    return suggestions;
  }

  Future<Either<String, List<GlobalSearchResult>>> loadIndex(
    String userId,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        firestore.collection('fashion_interests').get(),
        firestore
            .collection('trends')
            .orderBy('created_at', descending: true)
            .limit(100)
            .get(),
        firestore.collection('users').limit(100).get(),
        firestore
            .collection('designers')
            .orderBy('created_date', descending: true)
            .limit(100)
            .get(),
        firestore
            .collection('closets')
            .doc(userId)
            .collection('outfits')
            .orderBy('created_at', descending: true)
            .limit(100)
            .get(),
        firestore
            .collection('work_orders')
            .where('created_by', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .limit(100)
            .get(),
        firestore
            .collection('clients')
            .where('created_by', isEqualTo: userId)
            .limit(100)
            .get(),
      ]);

      final results = <GlobalSearchResult>[];
      final interests = snapshots[0];
      for (final doc in interests.docs) {
        final data = doc.data();
        final name = _value(data['name']);
        if (name.isEmpty) continue;
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.interests,
            title: name,
            subtitle: _value(data['category']),
          ),
        );
      }

      for (final doc in snapshots[1].docs) {
        final data = doc.data();
        final title = _value(data['description']);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.trends,
            title: title.isEmpty ? 'Trend' : title,
            subtitle: _value(data['tags']),
            route: '/trends/${doc.id}',
          ),
        );
      }

      for (final doc in snapshots[2].docs) {
        final data = doc.data();
        final title = _value(data['full_name']).isNotEmpty
            ? _value(data['full_name'])
            : _value(data['user_name']);
        if (title.isEmpty || doc.id == userId) continue;
        final accountType = _value(data['account_type']);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.users,
            title: title,
            subtitle: accountType,
            route: accountType.toLowerCase() == 'designer'
                ? '/designers/${doc.id}'
                : null,
          ),
        );
      }

      for (final doc in snapshots[3].docs) {
        final data = doc.data();
        final businessName = _value(data['business_name']);
        final name = _value(data['name']);
        final designer = Designer.fromJson(data).copyWith(uid: doc.id);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.designers,
            title: businessName.isNotEmpty ? businessName : name,
            subtitle: businessName.isNotEmpty ? name : _value(data['location']),
            route: '/designers/${doc.id}',
            designer: designer,
          ),
        );
      }

      for (final doc in snapshots[4].docs) {
        final data = doc.data();
        final title = _value(data['style']);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.outfits,
            title: title.isEmpty ? 'Outfit' : title,
            subtitle: [
              _value(data['occassion']),
              _value(data['tags']),
            ].where((value) => value.isNotEmpty).join(' · '),
            route: '/closet',
          ),
        );
      }

      for (final doc in snapshots[5].docs) {
        final data = doc.data();
        final title = _value(data['title']);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.workOrders,
            title: title.isEmpty ? 'Work order' : title,
            subtitle: [
              _value(data['work_order_type']),
              _value(data['status']),
            ].where((value) => value.isNotEmpty).join(' · '),
            route: _value(data['work_order_type']).toUpperCase() == 'REQUEST'
                ? '/workorders/request/${doc.id}'
                : '/workorders/details/${doc.id}',
          ),
        );
      }

      for (final doc in snapshots[6].docs) {
        final data = doc.data();
        final title = _value(data['full_name']);
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.clients,
            title: title.isEmpty ? 'Client' : title,
            subtitle: _value(data['mobile_number']),
            route: '/clients/view/${doc.id}',
          ),
        );
      }

      return Right(results);
    } on FirebaseException catch (error) {
      return Left(error.message ?? 'Unable to load search results');
    } catch (error) {
      return Left(error.toString());
    }
  }

  String _value(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).join(' ');
    return value?.toString() ?? '';
  }
}