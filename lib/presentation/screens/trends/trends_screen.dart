import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/presentation/screens/trends/trends_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TrendBloc>().add(const LoadTrendsCacheFirst());
      },
      child: CustomScrollView(
        key: const PageStorageKey("trends"),
        slivers: const [
          TrendsSliver(),   // <-- REAL slivers inside
        ],
      ),
    );
  }
}
