import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliver_tools/sliver_tools.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with RouteAware {
  late Query<Client> query;
  //late AuthProviderCubit _authProviderCubit;
  //bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('clients');
  //bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  //String _searchText = "";

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    //_authProviderCubit = context.read<AuthProviderCubit>();

    context.read<TrendBloc>().add(const LoadTrendsCacheFirstThenNetwork(''));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;
    return MultiSliver(
      children: [
        BlocBuilder<TrendBloc, TrendBlocState>(
          builder: (context, state) {
            switch (state) {
              case const TrendLoading():
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 400,
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                );
              case TrendsLoaded(:final trends):
                return TrendsStaggeredView(items: trends);
              case TrendError(:final message):
                return SliverToBoxAdapter(
                  child: Center(child: Text("Error: $message")),
                );
              default:
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: PageEmptyWidget(
                      title: "No Trends Found",
                      subtitle: "Add new trend to see them here.",
                      icon: Icons.newspaper_outlined,
                    ),
                  ),
                );
            }
          },
        ),
      ],
    );
  }

  @override
  void didPopNext() {
    //context.read<TrendBloc>().add(const LoadTrendsCacheFirstThenNetwork(''));
  }

  Future<void> refreshDesigners() async {
    //context.read<TrendBloc>().add(const LoadTrendsCacheFirstThenNetwork(''));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }
}
