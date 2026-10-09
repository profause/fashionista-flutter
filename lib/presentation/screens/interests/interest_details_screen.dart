import 'dart:async';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/screens/global_search/global_search_screen.dart';
import 'package:flutter/material.dart';

class InterestDetailsScreen extends StatefulWidget {
  const InterestDetailsScreen({super.key});

  @override
  State<InterestDetailsScreen> createState() => _InterestDetailsScreenState();
}

class _InterestDetailsScreenState extends State<InterestDetailsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchDebounce = Debouncer(const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: context.canvasBackground,
        elevation: 0,
        title: Hero(
          tag: 'search',
          child: Material(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const Key("searchTextField"),
                keyboardType: TextInputType.text,
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search Interests...",
                  hintStyle: textTheme.bodyMedium!.copyWith(
                    color: context.mutedText,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconColor: context.secondaryLabel,
                  filled: true,
                  fillColor: context.cardSurface,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: context.accent.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(child: Text('Interest details go here')),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce.cancel();
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer(this.delay);

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
