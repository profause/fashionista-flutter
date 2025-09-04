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
                backgroundColor: Colors.grey.shade300,
                backgroundImage: user.profileImage.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImage)
                    : null,
                child: user.profileImage.isEmpty
                    ? Icon(
                        Icons.person_outline,
                        size: radius * 1.5,
                        color: Colors.grey.shade600,
                      )
                    : null,
              )
            : DefaultProfileAvatar(
                name: user.fullName,
                size: radius,
                uid: user.uid!,
              );

        return GestureDetector(onTap: onTap, child: avatar);
      },
    );
  }
}
