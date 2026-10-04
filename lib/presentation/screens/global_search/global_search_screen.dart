import 'package:fashionista/core/theme/app.theme.dart';
import 'package:flutter/material.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  @override
  void initState() {
    super.initState();
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
                decoration: InputDecoration(
                  hintText: "Search outfits, designers, styles...",
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
      body: const Center(child: Text('Global Search Content')),
    );
  }
}
