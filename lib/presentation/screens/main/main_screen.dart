import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/presentation/screens/clients/clients_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/designers/designers_screen.dart';
import 'package:fashionista/presentation/screens/home/home_screen.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  late UserBloc _userBloc;
  //int _selectedIndex = 0;

  final List<Widget> _designerPageList = [
    HomeScreen(),
    ClientsScreen(),
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
    final user = _userBloc.state;
    final isFullNameEmpty = user.fullName.isEmpty;
    final isUserNameEmpty = user.userName == 'Guest user';
    final isAccountTypeEmpty = user.accountType.isEmpty;
    final isGenderEmpty = user.gender.isEmpty;

    if (isFullNameEmpty ||
        isUserNameEmpty ||
        isAccountTypeEmpty ||
        isGenderEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          //_onNavItemTapped(5);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    setState(() {
      _currentIndex = index;
    });
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
        builder: (_, currentIndex, __) {
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
        selectedItemColor: colorScheme.primary,
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
                  backgroundImage: user.profileImage.isNotEmpty
                      ? CachedNetworkImageProvider(user.profileImage)
                      : null,
                  child: user.profileImage.isEmpty
                      ? Icon(
                          Icons.person_outline,
                          size: 24,
                          color: Colors.grey.shade600,
                        )
                      : null,
                );
              },
            ),
            activeIcon: BlocBuilder<UserBloc, User>(
              builder: (context, user) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: user.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(user.profileImage)
                        : null,
                    child: user.profileImage.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                );
              },
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        elevation: 0,
      ),
    );
  }
}
