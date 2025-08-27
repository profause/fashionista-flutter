import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/clients/add_client_screen.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  late Query<Client> query;
  late AuthProviderCubit _authProviderCubit;
  //bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('clients');
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    //_isLoading = false;
    //if (mounted) {
    _authProviderCubit = context.read<AuthProviderCubit>();

    query = collectionRef
        .where('created_by', isEqualTo: _authProviderCubit.state.uid)
        .orderBy('created_date', descending: true)
        .withConverter(
          fromFirestore: (snapshot, _) => Client.fromJson(snapshot.data()!),
          toFirestore: (client, _) => client.toJson(),
        );

    //}
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> refreshClients() async {
      // Force rebuild StreamBuilder by calling setState
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500)); // optional
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            // Incoming: slide in from right
            final inAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0), // from right
              end: Offset.zero,
            ).animate(animation);

            // Outgoing: shrink/slide away from center
            final outAnimation = Tween<Offset>(
              begin: Offset.zero, // start at center
              end: const Offset(0.0, 0.0), // move slightly up
            ).animate(animation);

            if (child.key == const ValueKey("searchField")) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: inAnimation, child: child),
              );
            } else {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: outAnimation, child: child),
              );
            }
          },
          child: _isSearching
              ? TextField(
                  key: const ValueKey("searchField"),
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search trends...',
                    border: InputBorder.none,
                    hintStyle: textTheme.titleMedium,
                  ),
                  style: textTheme.bodyMedium,
                  onChanged: (value) {
                    setState(() => _searchText = value);
                  },
                )
              : const AppBarTitle(title: "Trends"),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                size: 30,
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
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
