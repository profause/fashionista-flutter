import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MyDesignersScreen extends StatefulWidget {
  const MyDesignersScreen({super.key});

  @override
  State<MyDesignersScreen> createState() => _MyDesignersScreenState();
}

class _MyDesignersScreenState extends State<MyDesignersScreen> {
  final ValueNotifier<List<Designer>> myDesignersNotifier =
      ValueNotifier<List<Designer>>([]);
  Timer? _debounce;
  bool loadingFashionDesigners = true;
  late UserBloc _userBloc;

  @override
  void initState() {
    // TODO: implement initState
    _userBloc = context.read<UserBloc>();
    _loadFashionDesigners();
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
          'My Designers',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Designer>>(
        key: ValueKey(_userBloc.state.uid),
        valueListenable: myDesignersNotifier,
        builder: (context, designers, _) {
          if (designers.isEmpty && loadingFashionDesigners) {
            return const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (designers.isEmpty && !loadingFashionDesigners) {
            return Center(
              child: PageEmptyWidget(
                title: "No designers found",
                subtitle: "",
                icon: Icons.people_outline,
                iconSize: 48,
              ),
            );
          }
          return ListView.separated(
            itemCount: designers.length,
            separatorBuilder: (context, index) =>
                const Divider(height: .1, thickness: .1, indent: 82),
            itemBuilder: (context, index) {
              final designer = designers[index];

              return ListTile(
                leading: Container(
                  //margin: const EdgeInsets.all(2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  height: 32 * 1.8,
                  width: 32 * 1.8,
                  child: CachedNetworkImage(
                    imageUrl: designer.profileImage!,
                    errorListener: (error) {},
                    placeholder: (context, url) => DefaultProfileAvatar(
                      key: ValueKey(designer.uid),
                      name: null,
                      size: 32 * 1.8,
                      uid: designer.uid,
                    ),
                    errorWidget: (context, url, error) => DefaultProfileAvatar(
                      key: ValueKey(designer.uid),
                      name: null,
                      size: 32 * 1.8,
                      uid: designer.uid,
                    ),
                  ),
                ),
                title: Text(designer.name),
                subtitle: Text(designer.businessName),
                onTap: () => context.push('/designers/${designer.uid}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadFashionDesigners() async {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      final result = await sl<FirebaseDesignersService>()
          .findDesignersWithFilter(6, 'created_date');

      final clientsResult = await sl<FirebaseClientsService>()
          .findClientByMobileNumber(_userBloc.state.mobileNumber);

      await result.fold((failure) async {}, (designers) {
        myDesignersNotifier.value = designers;
        loadingFashionDesigners = false;
      });

      await clientsResult.fold((failure) async {}, (clients) {
        final createdBy = clients.map((d) => d.createdBy).toList();
      });
    });
  }

  @override
  void dispose() {
    myDesignersNotifier.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
