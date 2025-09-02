import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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
