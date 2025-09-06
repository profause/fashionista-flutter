import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/presentation/screens/trends/add_trend_screen.dart';
import 'package:fashionista/presentation/screens/trends/widgets/trends_staggered_view.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with RouteAware {
  late Query<Client> query;
  late AuthProviderCubit _authProviderCubit;
  //bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('clients');
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    _authProviderCubit = context.read<AuthProviderCubit>();

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocListener<TrendBloc, TrendBlocState>(
        listener: (context, state) {
          if (state is TrendLoading) {
            _refreshKey.currentState?.show();
          }
        },
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: refreshDesigners,
          child: BlocBuilder<TrendBloc, TrendBlocState>(
            builder: (context, state) {
              switch (state) {
                case TrendLoading():
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 400)],
                  );

                case TrendsLoaded(:final trends, :final fromCache):
                  return TrendsStaggeredView(items: trends);
                case TrendError(:final message):
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 400,
                        child: Center(child: Text("Error: $message")),
                      ),
                    ],
                  );
                default:
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 400,
                        child: Center(
                          child: PageEmptyWidget(
                            title: "No Trends Found",
                            subtitle: "Add new trend to see them here.",
                            icon: Icons.newspaper_outlined,
                          ),
                        ),
                      ),
                    ],
                  );
              }
            },
          ),
        ),
      ),
      floatingActionButton: Hero(
        tag: 'add-trend-button',
        child: Material(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 1),
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTrendScreen()),
              );

              // if AddClientScreen popped with "true", reload
              if (result == true && mounted) {
                context.read<TrendBloc>().add(
                  const LoadTrendsCacheFirstThenNetwork(''),
                );
              }
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            ),
          ),
        ),
      ),
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
