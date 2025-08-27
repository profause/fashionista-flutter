import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/screens/clients/clients_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/designers/designers_screen.dart';
import 'package:fashionista/presentation/screens/home/home_screen.dart';
import 'package:fashionista/presentation/screens/main/widgets/bottom_nav_bar_widget.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:fashionista/presentation/screens/trends/trends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  //int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  late UserBloc _userBloc;

  final List<Widget> _designerPageList = [
    HomeScreen(),
    TrendsScreen(),
    ClientsScreen(),
    ClosetScreen(),
    ProfileScreen(),
  ];

  final List<Widget> _regularUserPageList = [
    HomeScreen(),
    TrendsScreen(),
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

  void _onNavItemTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      //_selectedIndex.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      body: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (_, currentIndex, __) {
          return 
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: _userBloc.state.accountType == 'Designer'
                ? _designerPageList
                : _regularUserPageList,
          );
          //_pages[currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onNavItemTap: _onNavItemTapped,
        ),
    );
  }
}
