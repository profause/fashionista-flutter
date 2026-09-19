import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_card_widget.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_pinned_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:fashionista/presentation/widgets/radio_option_row_widget.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      // 👈 helper from 'sliver_tools' package, or just return a Column of slivers
      children: [
        SliverAppBar(
          backgroundColor: context.canvasBackground,
          pinned: true, // keeps the searchbar visible when collapsed
          floating: true, // allows it to appear/disappear as you scroll
          snap: true, // snaps into view when scrolling up
          stretch: true,
          expandedHeight: 72,
          toolbarHeight: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? context.accent
                              : context.hairline,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 18,
                            color: context.mutedText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              cursorColor: context.accent,
                              style: TextStyle(
                                fontSize: 15,
                                color: context.onCanvasText,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search clients...",
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: context.mutedText,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                setState(() => _searchText = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      //border: Border.all(color: context.hairline),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        _showFilterBottomsheet(
                          context,
                          showAs!,
                          selectedFilter,
                          (filter) => setState(() => selectedFilter = filter),
                        );
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: context.onCanvasText,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 12,
                        bottom: 10,
                      ),
                      child: _SectionHeader(text: "Pinned Clients"),
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
                              horizontal: 16,
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

                  const SizedBox(height: 12),
                ],

                if (unpinnedClients.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 12,
                        bottom: 10,
                      ),
                      child: _SectionHeader(text: "All Clients"),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index.isEven) {
                          final client = unpinnedClients[index ~/ 2];
                          return ClientInfoCardWidget(
                            key: ValueKey(client.uid),
                            clientInfo: client,
                            onTap: () {
                              context.push('/clients/view/${client.uid}');
                            },
                          );
                        } else {
                          return const SizedBox(height: 12);
                        }
                      }, childCount: unpinnedClients.length * 2 - 1),
                    ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        String tempShowAs = showAs; // copy parent value
        String tempFilter = selectedFilter;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3938)
                              : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const _FilterSheetLabel("Show as"),
                    const SizedBox(height: 10),
                    _FilterOptionCard(
                      children: [
                        RadioOptionRow(
                          label: "List",
                          value: "list",
                          groupValue: tempShowAs,
                          onChanged: (val) {
                            setModalState(() => tempShowAs = val);
                            setState(() => showAs = val);
                          },
                        ),
                        RadioOptionRow(
                          label: "Grid",
                          value: "grid",
                          groupValue: tempShowAs,
                          onChanged: (val) {
                            setModalState(() => tempShowAs = val);
                            setState(() => showAs = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FilterSheetLabel("Filter by"),
                    const SizedBox(height: 10),
                    _FilterOptionCard(
                      children: [
                        RadioOptionRow(
                          label: "All",
                          value: "All",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                        RadioOptionRow(
                          label: "Newest",
                          value: "Newest",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                        RadioOptionRow(
                          label: "Pinned",
                          value: "Pinned",
                          groupValue: tempFilter,
                          onChanged: (val) {
                            setModalState(() => tempFilter = val);
                            setState(() => selectedFilter = val);
                            onFilterSelected(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: context.mutedText,
      ),
    );
  }
}

class _FilterSheetLabel extends StatelessWidget {
  final String text;
  const _FilterSheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.mutedText,
      ),
    );
  }
}

class _FilterOptionCard extends StatelessWidget {
  final List<Widget> children;
  const _FilterOptionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final divider = Divider(color: context.hairline, height: 1, thickness: 1);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(divider);
      rows.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.canvasBackground,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: rows),
      ),
    );
  }
}
