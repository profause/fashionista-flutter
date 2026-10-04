import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

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

  const GlobalSearchResult({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.route,
  });

  String get searchableText => '$title $subtitle'.toLowerCase();
}

class FirebaseGlobalSearchService {
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
        results.add(
          GlobalSearchResult(
            id: doc.id,
            category: GlobalSearchCategory.designers,
            title: businessName.isNotEmpty ? businessName : name,
            subtitle: businessName.isNotEmpty ? name : _value(data['location']),
            route: '/designers/${doc.id}',
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