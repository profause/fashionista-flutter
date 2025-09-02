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
      backgroundColor: colorScheme.surface,
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
