import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_card_widget.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_pinned_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String selectedFilter = 'All';
  String? showAs = "list";

  @override
  void initState() {
    context.read<ClientBloc>().add(const LoadClientsCacheFirstThenNetwork(''));
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: colorScheme.surface,
          pinned: true, // keeps the searchbar visible when collapsed
          floating: true, // allows it to appear/disappear as you scroll
          snap: true, // snaps into view when scrolling up
          stretch: true,
          expandedHeight: 18,
          toolbarHeight: 5,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search clients...",
                        hintStyle: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchText = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomIconButtonRounded(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    onPressed: () {
                      _showFilterBottomsheet(
                        context,
                        showAs!,
                        selectedFilter,
                        (filter) => setState(() => selectedFilter = filter),
                      );
                    },
                    iconData: Icons.filter_list_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),

        ValueListenableBuilder<Box<Client>>(
          valueListenable: sl<HiveClientService>().itemListener(),
          builder: (context, box, _) {
            final clients = box.values.toList().cast<Client>();
            final sortedClients = [...clients]
              ..sort((a, b) => b.createdDate!.compareTo(a.createdDate!));

            final filteredClients = _searchText.isEmpty
                ? sortedClients
                : sortedClients.where((client) {
                    final name = client.fullName.toLowerCase();
                    final mobileNumber = client.mobileNumber.toLowerCase();
                    return name.contains(_searchText.toLowerCase()) ||
                        mobileNumber.contains(_searchText.toLowerCase());
                  }).toList();

            if (filteredClients.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: PageEmptyWidget(
                    title: "No Clients Found",
                    subtitle: "Add new clients to see them here.",
                    icon: Icons.people_outline,
                    iconSize: 48,
                  ),
                ),
              );
            }
            final pinnedClients = filteredClients
                .where((c) => c.isPinned ?? false)
                .toList()
                .reversed
                .toList();
            final unpinnedClients = filteredClients
                .where((c) => c.isPinned == false)
                .toList();
            return MultiSliver(
              children: [
                if (pinnedClients.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        "Pinned Clients",
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true, // ✅ don’t expand infinitely
                        primary: false, // ✅ don’t hijack the parent scroll
                        physics:
                            const ClampingScrollPhysics(), // ✅ smoother nested scroll
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ), // ✅ add spacing at edges
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index.isEven) {
                                  final client = pinnedClients[index ~/ 2];
                                  return ClientInfoPinnedWidget(
                                    key: ValueKey(client.uid),
                                    clientInfo: client,
                                  );
                                } else {
                                  return const SizedBox(
                                    width: 8,
                                  ); // separator between items
                                }
                              }, childCount: pinnedClients.length * 2 - 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Divider(
                      height: .1,
                      thickness: .1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ),
                ],

                if (unpinnedClients.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 8,
                        top: 8,
                      ),
                      child: Text("All Clients", style: textTheme.labelLarge),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index.isEven) {
                        final client = unpinnedClients[index ~/ 2];
                        return ClientInfoCardWidget(
                          key: ValueKey(client.uid),
                          clientInfo: client,
                          onTap: () {
                            context.push('/clients/${client.uid}');
                          },
                        );
                      } else {
                        return const Divider(
                          height: .1,
                          thickness: .1,
                          indent: 80,
                        );
                      }
                    }, childCount: unpinnedClients.length * 2 - 1),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _showFilterBottomsheet(
    BuildContext context,
    String showAs,
    String selectedFilter,
    Function(String) onFilterSelected,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String tempShowAs = showAs; // copy parent value
        String tempFilter = selectedFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.5,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Handle bar
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "Show as",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "List",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "list",
                                    groupValue: tempShowAs,
                                    onChanged: (val) {
                                      setModalState(() => tempShowAs = val!);
                                      setState(() => showAs = val!);
                                      // update parent too
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: .1, thickness: .1),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "Grid",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "grid",
                                    groupValue: tempShowAs,
                                    onChanged: (val) {
                                      setModalState(() => tempShowAs = val!);
                                      setState(() => showAs = val!);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Filter by",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "All",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "All",
                                    groupValue: tempFilter,
                                    onChanged: (val) {
                                      setModalState(() => tempFilter = val!);
                                      setState(() => selectedFilter = val!);
                                      onFilterSelected(val!);
                                      // update parent too
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: .1, thickness: .1),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "Newest",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "Newest",
                                    groupValue: tempFilter,
                                    onChanged: (val) {
                                      setModalState(() => tempFilter = val!);
                                      setState(() => selectedFilter = val!);
                                      onFilterSelected(val!);
                                      // update parent too
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: .1, thickness: .1),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "Pinned",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "Pinned",
                                    groupValue: tempFilter,
                                    onChanged: (val) {
                                      setModalState(() => tempFilter = val!);
                                      setState(() => selectedFilter = val!);
                                      onFilterSelected(val!);
                                      // update parent too
                                    },
                                  ),
                                ],
                              ),
                              //const Divider(height: .1, thickness: .1),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
