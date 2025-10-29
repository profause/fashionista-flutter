import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:fashionista/presentation/widgets/profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sliver_tools/sliver_tools.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

List<String> hints = [
  "✨ Share your next fashion moment…",
  "👗 What’s trending in your world?",
  "🧵 Stitch your trend into the feed…",
  "🚀 Kick off the next big fashion vibe…",
  "🖋 Describe your style inspiration…",
  "🔥 Drop your hottest fashion trend…",
];

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  late Query<Client> query;
  //late AuthProviderCubit _authProviderCubit;
  //bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('clients');
  //bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  //String _searchText = "";

  @override
  void initState() {
    //_authProviderCubit = context.read<AuthProviderCubit>();

    context.read<TrendBloc>().add(const LoadTrendsCacheFirstThenNetwork(''));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;

    final random = Random();
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ProfileAvatar(radius: 18),
                const SizedBox(width: 0),
                FilledButton(
                  onPressed: () {
                    context.push('/trends-new');
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: colorScheme.onSurface, // text/icon color
                  ),
                  child: Text(hints[random.nextInt(hints.length)]),
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<Box<TrendFeedModel>>(
          valueListenable: sl<HiveTrendService>().itemListener(),
          builder: (context, box, _) {
            final trends = box.values.toList().cast<TrendFeedModel>();
            final sortedTrends = [...trends]
              ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
            return TrendsStaggeredView(items: sortedTrends);
          },
        ),

        // BlocBuilder<TrendBloc, TrendBlocState>(
        //   builder: (context, state) {
        //     switch (state) {
        //       case const TrendLoading():
        //         return const SliverToBoxAdapter(
        //           child: SizedBox(
        //             height: 400,
        //             child: Center(
        //               child: SizedBox(
        //                 height: 24,
        //                 width: 24,
        //                 child: CircularProgressIndicator(),
        //               ),
        //             ),
        //           ),
        //         );
        //       case TrendsLoaded(:final trends):
        //         return TrendsStaggeredView(items: trends);
        //       case TrendError(:final message):
        //         return SliverToBoxAdapter(
        //           child: Center(child: Text("Error: $message")),
        //         );
        //       default:
        //         return SliverFillRemaining(
        //           hasScrollBody: false,
        //           child: Center(
        //             child: PageEmptyWidget(
        //               title: "No Trends Found",
        //               subtitle: "Add new trend to see them here.",
        //               icon: Icons.newspaper_outlined,
        //             ),
        //           ),
        //         );
        //     }
        //   },
        // ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
