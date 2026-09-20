import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
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
    _userBloc = context.read<UserBloc>();
    _loadFashionDesigners();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.accent,
        backgroundColor: context.cardSurface,
        title: const AppBarTitle(title: 'My Designers'),
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

          if (designers.isEmpty) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: designers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _DesignerListTileCard(designer: designers[index]);
            },
          );
        },
      ),
    );
  }

  Future<void> _loadFashionDesigners() async {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      loadingFashionDesigners = true;

      final result = await sl<FirebaseClientsService>()
          .findClientByMobileNumber(_userBloc.state.mobileNumber);

      await result.fold(
        (failure) async {
          debugPrint("Client fetch failed: $failure");
          loadingFashionDesigners = false;
        },
        (clients) async {
          if (clients.isEmpty) {
            myDesignersNotifier.value = [];
            loadingFashionDesigners = false;
            return;
          }

          // Remove duplicate designer IDs
          final designerIds = clients.map((c) => c.createdBy).toSet().toList();

          final designerResults = await Future.wait(
            designerIds.map(
              (id) => sl<FirebaseDesignersService>().findDesignerById(id),
            ),
          );

          final designers = designerResults
              .where((r) => r.isRight())
              .map((r) => r.getOrElse(() => throw UnimplementedError()))
              .toList();

          myDesignersNotifier.value = designers;
          loadingFashionDesigners = false;
        },
      );
    });
  }

  @override
  void dispose() {
    myDesignersNotifier.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

/// Theme-aware row card for a single designer in the "My Designers" list.
class _DesignerListTileCard extends StatelessWidget {
  const _DesignerListTileCard({required this.designer});

  final Designer designer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String imageUrl = designer.profileImage ?? '';

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/designers/${designer.uid}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: imageUrl.isEmpty
                      ? DefaultProfileAvatar(
                          name: designer.name,
                          size: 48,
                          uid: designer.uid,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorListener: (error) {},
                          placeholder: (_, _) => DefaultProfileAvatar(
                            name: designer.name,
                            size: 48,
                            uid: designer.uid,
                          ),
                          errorWidget: (_, _, _) => DefaultProfileAvatar(
                            name: designer.name,
                            size: 48,
                            uid: designer.uid,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      designer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      designer.businessName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                        height: 1.2,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
