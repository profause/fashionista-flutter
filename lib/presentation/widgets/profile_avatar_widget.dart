import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({super.key, this.radius = 16, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, User>(
      builder: (context, user) {
        final avatar = user.profileImage.isNotEmpty
            ? CircleAvatar(
                radius: radius,
                backgroundColor: Colors.white,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: CachedNetworkImage(
                    imageUrl: user.profileImage,
                    errorListener: (error) {},
                    placeholder: (context, url) => DefaultProfileAvatar(
                      name: null,
                      size: radius * 2,
                      uid: user.uid!,
                    ),
                    errorWidget: (context, url, error) => DefaultProfileAvatar(
                      name: null,
                      size: radius * 2,
                      uid: user.uid!,
                    ),
                  ),
                ),
              )
            : DefaultProfileAvatar(
                name: null,
               size: radius * 2,
                uid: user.uid!,
              );

        return GestureDetector(onTap: onTap, child: avatar);
      },
    );
  }
}
