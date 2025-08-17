import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/clients/add_client_screen.dart';
import 'package:fashionista/presentation/screens/clients/widgets/client_info_card_widget.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late CollectionReference<Client> collection;
  late AuthProviderCubit _authProviderCubit;
  bool _isLoading = false;
  final collectionRef = FirebaseFirestore.instance.collection('clients');

  @override
  void initState() {
    _isLoading = false;
    //if (mounted) {
      _authProviderCubit = context.read<AuthProviderCubit>();
      collection = collectionRef
          //.where('createdBy', isEqualTo: _authProviderCubit.state.uid).get()
          .withConverter<Client>(
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Clients',
          style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: FirestoreListView<Client>(
        query: collection,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, snapshot) {
          final clientInfo = snapshot.data();
          return Column(
            children: [
              ClientInfoCardWidget(clientInfo: clientInfo),
            ],
          );
        },
      ),
      floatingActionButton: Hero(
        tag: 'add-client-button',
        child: Material(
          color: Theme.of(context).colorScheme.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddClientScreen(),
                ),
              );
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
}
