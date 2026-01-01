import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserProfileMessurementCard extends StatefulWidget {
  const UserProfileMessurementCard({super.key});

  @override
  State<UserProfileMessurementCard> createState() =>
      _UserProfileMessurementCardState();
}

class _UserProfileMessurementCardState
    extends State<UserProfileMessurementCard> {
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(0),
      ),
      child: ListTile(
        title: Text('My Measurements', style: textTheme.bodyMedium),
        trailing: ValueListenableBuilder<List<Designer>>(
          key: ValueKey(_userBloc.state.uid),
          valueListenable: myDesignersNotifier,
          builder: (context, designers, _) {
            if (designers.isEmpty && !loadingFashionDesigners) {
              return Text("No designers found", style: textTheme.bodyMedium);
            }
            return SizedBox(
              height: 60,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: designers.length * 24.0 + 24, // dynamic width
                  child: Stack(
                    children: [
                      for (int i = 0; i < designers.length; i++)
                        Positioned(
                          left: i * 24.0,
                          child: buildDesignerAvatar(designers[i]),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        onTap: () => context.push('/my-designers'),
      ),
    );
  }

  @override
  void dispose() {
    myDesignersNotifier.dispose();
    _debounce?.cancel();
    super.dispose();
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

  Widget buildDesignerAvatar(Designer item) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.all(2),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: CachedNetworkImage(
          imageUrl: item.profileImage!,
          placeholder: (_, _) =>
              DefaultProfileAvatar(name: null, size: 48, uid: item.uid),
          errorWidget: (_, _, _) =>
              DefaultProfileAvatar(name: null, size: 48, uid: item.uid),
        ),
      ),
    );
  }
}
