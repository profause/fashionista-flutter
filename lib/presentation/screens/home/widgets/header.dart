import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProviderCubit = context.read<AuthProviderCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello,",
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 15,
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.start,
            ),
            Text(
              authProviderCubit.authState.username,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent, // keep background transparent
          child: InkWell(
            borderRadius: BorderRadius.circular(60), // match avatar shape
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 15, // 120x120 size
              backgroundColor: AppTheme.lightGrey,
              backgroundImage: const AssetImage(AppImages.avatar),
            ),
          ),
        ),
      ],
    );
  }
}
