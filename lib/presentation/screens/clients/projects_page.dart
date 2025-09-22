import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {

  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
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
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search projects...",
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
                          horizontal: 12,
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
                      //_showFilterBottomSheet(context);
                    },
                    iconData: Icons.filter_list_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bookmarked",
                  style: textTheme.headlineSmall,
                ),
                //horizontal list of bookmarked projects
              ],
            ),
          ),
        ),
      ],
     );
  }

    @override
  void dispose() {
    super.dispose();
  }
}