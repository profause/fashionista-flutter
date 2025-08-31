import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/bloc/client_state.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/clients/add_client_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_details_screen.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_card_widget.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_pinned_widget.dart';
import 'package:fashionista/presentation/screens/clients/widgets/silver_filter_header_widget.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/custom_filter_button.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with RouteAware {
  late CollectionReference<Client> collection;
  late Query<Client> query;
  late AuthProviderCubit _authProviderCubit;
  final collectionRef = FirebaseFirestore.instance.collection('clients');
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String selectedFilter = 'All';
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    _authProviderCubit = context.read<AuthProviderCubit>();

    collection = collectionRef.withConverter<Client>(
      fromFirestore: (snapshot, _) => Client.fromJson(snapshot.data()!),
      toFirestore: (client, _) => client.toJson(),
    );

    query = collectionRef
        .where('created_by', isEqualTo: _authProviderCubit.state.uid)
        .orderBy('created_date', descending: true)
        .withConverter(
          fromFirestore: (snapshot, _) => Client.fromJson(snapshot.data()!),
          toFirestore: (client, _) => client.toJson(),
        );

    context.read<ClientBloc>().add(const LoadClientsCacheFirstThenNetwork(''));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  /// Called when coming back to this screen
  @override
  void didPopNext() {
    //debugPrint("ClientsScreen: didPopNext → refreshing clients");
    context.read<ClientBloc>().add(const LoadClientsCacheFirstThenNetwork(''));
  }

  Future<void> refreshDesigners() async {
    context.read<ClientBloc>().add(const LoadClientsCacheFirstThenNetwork(''));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filters = ['All', 'Newest', 'Favourites', 'Archived'];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 56 + MediaQuery.of(context).padding.top,
            flexibleSpace: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching
                        ? TextField(
                            key: const ValueKey("searchField"),
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search clients...',
                              border: InputBorder.none,
                              hintStyle: textTheme.titleMedium,
                            ),
                            style: textTheme.bodyMedium,
                            onChanged: (value) {
                              setState(() => _searchText = value);
                            },
                          )
                        : const AppBarTitle(title: "Clients"),
                  ),
                ],
              ),
            ),
            backgroundColor: colorScheme.onPrimary,
            foregroundColor: colorScheme.primary,
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  size: 28,
                  color: colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchText = "";
                      _searchController.clear();
                    }
                    _isSearching = !_isSearching;
                  });
                },
              ),
            ],
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: SilverFilterHeaderWidget(
              minHeight: 52,
              maxHeight: 52,
              child: Container(
                color: colorScheme.surface,
                child: Center(
                  child: CustomFilterButton(
                    items: filters,
                    initialValue: 'All',
                    onSelect: (filter) {
                      setState(() {
                        selectedFilter = filter;
                        query = queryBuilder(filter);
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
        body: BlocListener<ClientBloc, ClientBlocState>(
          listener: (context, state) {
            if (state is ClientLoading) {
              _refreshKey.currentState?.show();
            }
          },
          child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: refreshDesigners,
            child: BlocBuilder<ClientBloc, ClientBlocState>(
              builder: (context, state) {
                switch (state) {
                  case ClientLoading():
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 400)],
                    );
                  case ClientsLoaded(:final clients, :final fromCache):
                    final filteredClients = _searchText.isEmpty
                        ? clients
                        : clients.where((client) {
                            final name = client.fullName.toLowerCase();
                            final mobileNumber = client.mobileNumber
                                .toLowerCase();
                            return name.contains(_searchText.toLowerCase()) ||
                                mobileNumber.contains(
                                  _searchText.toLowerCase(),
                                );
                          }).toList();

                    if (filteredClients.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 400,
                            child: Center(
                              child: PageEmptyWidget(
                                title: "No Clients Found",
                                subtitle: "Add new clients to see them here.",
                                icon: Icons.people_outline,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final pinnedClients = filteredClients
                        .where((c) => c.isPinned ?? false)
                        .toList()
                        .reversed
                        .toList();
                    final unPinnedClients = filteredClients
                        .where((c) => c.isPinned == false)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(0.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (pinnedClients.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Text(
                              "Pinned Clients",
                              style: textTheme.labelLarge,
                            ),
                          ),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemCount: pinnedClients.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 4),
                              itemBuilder: (context, index) {
                                final client = pinnedClients[index];
                                return ClientInfoPinnedWidget(
                                  clientInfo: client,
                                );
                              },
                            ),
                          ),
                          const Divider(
                            height: .1,
                            thickness: .1,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                        if (pinnedClients.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              bottom: 8,
                              top: 8,
                            ),
                            child: Text(
                              "All Clients",
                              style: textTheme.labelLarge,
                            ),
                          ),
                        ],
                        ...unPinnedClients.map(
                          (client) => Column(
                            children: [
                              ClientInfoCardWidget(
                                clientInfo: client,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ClientDetailsScreen(client: client),
                                    ),
                                  );
                                },
                              ),
                              const Divider(
                                height: .1,
                                thickness: .1,
                                indent: 80,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                  // return ListView.separated(
                  //   padding: const EdgeInsets.all(0.0),
                  //   physics: const AlwaysScrollableScrollPhysics(),
                  //   itemCount: filteredClients.length,
                  //   itemBuilder: (context, index) {
                  //     final client = filteredClients[index];
                  //     return ClientInfoCardWidget(
                  //       clientInfo: client,
                  //       onTap: () async {
                  //         final result = await Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //             builder: (context) =>
                  //                 ClientDetailsScreen(client: client),
                  //           ),
                  //         );
                  //         // if (result == true) {
                  //         //   // reload when something was updated
                  //         //   context.read<ClientBloc>().add(
                  //         //     const LoadClientsCacheFirstThenNetwork(''),
                  //         //   );
                  //         // }
                  //       },
                  //     );
                  //   },
                  //   separatorBuilder: (context, index) =>
                  //       const Divider(height: .1, thickness: .1, indent: 80),
                  // );
                  case ClientError(:final message):
                    return Center(child: Text("Error: $message"));
                  default:
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 400,
                          child: Center(
                            child: PageEmptyWidget(
                              title: "No Clients Found",
                              subtitle: "Refresh to try again",
                              icon: Icons.people_outline,
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
      ),
      floatingActionButton: Hero(
        tag: 'add-client-button',
        child: Material(
          color: Theme.of(context).colorScheme.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClientScreen()),
              );

              // if AddClientScreen popped with "true", reload
              if (result == true && mounted) {
                context.read<ClientBloc>().add(
                  const LoadClientsCacheFirstThenNetwork(''),
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

  Query<Client> queryBuilder(String filter) {
    final query = collectionRef.withConverter<Client>(
      fromFirestore: (snapshot, _) => Client.fromJson(snapshot.data()!),
      toFirestore: (designer, _) => designer.toJson(),
    );

    switch (filter) {
      case 'Newest':
        query.orderBy('created_date', descending: true);
        break;
      case 'Favourites':
        query
            .where('favourites', arrayContains: _authProviderCubit.state.uid)
            .orderBy('created_date', descending: true);
        break;
      default:
        query.orderBy('created_date', descending: true);
    }
    return query;
  }
}
