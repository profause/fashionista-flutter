import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/screens/clients/clients_and_projects_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/designers/designers_screen.dart';
import 'package:fashionista/presentation/screens/home/home_screen.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  late UserBloc _userBloc;
  //int _selectedIndex = 0;

  final List<Widget> _designerPageList = [
    HomeScreen(),
    ClientsAndProjectsScreen(),
    ClosetScreen(),
    ProfileScreen(),
  ];

  final List<Widget> _regularUserPageList = [
    HomeScreen(),
    DesignersScreen(),
    ClosetScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    _pageController.addListener(() {});
    super.initState();
    _userBloc = context.read<UserBloc>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      //extendBody: true,
      backgroundColor: colorScheme.surface,
      body: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (_, currentIndex, _) {
          return _userBloc.state.accountType == 'Designer'
              ? _designerPageList[currentIndex]
              : _regularUserPageList[currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: colorScheme.primary,
        ),
        unselectedLabelStyle: textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.appIconColor,
        backgroundColor: colorScheme.onPrimary,
        //unselectedItemColor: colorScheme.primary.withValues(alpha: 0.5),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: _userBloc.state.accountType == 'Designer'
                ? 'Clients'
                : 'Designers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: 'Closet',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<UserBloc, User>(
              builder: (context, user) {
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: CachedNetworkImage(
                      imageUrl: user.profileImage,
                      errorListener: (error) {},
                      placeholder: (context, url) => DefaultProfileAvatar(
                        key: ValueKey(user.uid),
                        name: null,
                        size: 18 * 1.8,
                        uid: user.uid!,
                      ),
                      errorWidget: (context, url, error) =>
                          DefaultProfileAvatar(
                            key: ValueKey(user.uid),
                            name: null,
                            size: 18 * 1.8,
                            uid: user.uid!,
                          ),
                    ),
                  ),
                );
              },
            ),
            activeIcon: BlocBuilder<UserBloc, User>(
              builder: (context, user) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.appIconColor, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: CachedNetworkImage(
                        imageUrl: user.profileImage,
                        errorListener: (error) {},
                        placeholder: (context, url) => DefaultProfileAvatar(
                          key: ValueKey(user.uid),
                          name: null,
                          size: 18 * 1.8,
                          uid: user.uid!,
                        ),
                        errorWidget: (context, url, error) =>
                            DefaultProfileAvatar(
                              key: ValueKey(user.uid),
                              name: null,
                              size: 18 * 1.8,
                              uid: user.uid!,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onItemTapped,
        elevation: 0,
      ),
    );
  }
}
