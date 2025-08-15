import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/screens/main/widgets/bottom_nav_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomNavBar extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final ValueChanged<int> onNavItemTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<UserBloc, User>(
      builder: (context, user) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          boxShadow: [
            BoxShadow(
              color: colorScheme.surfaceContainerHigh,
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: "Home",
              selectedIndex: selectedIndex,
              onTap: onNavItemTap,
            ),
            BottomNavItem(
              index: 1,
              icon: Icons.newspaper_outlined,
              activeIcon: Icons.newspaper,
              label: "Trends",
              selectedIndex: selectedIndex,
              onTap: onNavItemTap,
            ),

            user.accountType == 'Designer'
                ? BottomNavItem(
                    index: 2,
                    icon: Icons.man_3_outlined,
                    activeIcon: Icons.man_3,
                    label: "Clients",
                    selectedIndex: selectedIndex,
                    onTap: onNavItemTap,
                  )
                : BottomNavItem(
                    index: 3,
                    icon: Icons.man_3_outlined,
                    activeIcon: Icons.man_3,
                    label: "Designers",
                    selectedIndex: selectedIndex,
                    onTap: onNavItemTap,
                  ),

            BottomNavItem(
              index: 4,
              icon: Icons.checkroom_outlined,
              activeIcon: Icons.checkroom,
              label: "Closet",
              selectedIndex: selectedIndex,
              onTap: onNavItemTap,
            ),

            BottomNavItem(
              index: 5,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: "Profile",
              selectedIndex: selectedIndex,
              onTap: onNavItemTap,
            ),
          ],
        ),
      ),
    );
  }
}
