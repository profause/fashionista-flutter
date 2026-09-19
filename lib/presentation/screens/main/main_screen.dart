import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/app_config.dart';
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
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  BannerAd? _bannerAd;

  String bannerAdUnitId = Platform.isIOS
      ? appConfig.get('ad_unit_id_ios')
      : appConfig.get('ad_unit_id_android');
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
    super.initState();
    _userBloc = context.read<UserBloc>();
    BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    ).load();

    //_bannerAd!.load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
    _bannerAd?.dispose();
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //extendBody: true,
      backgroundColor: context.canvasBackground,
      body: Column(
        children: [
          // EXPANDED PAGE CONTENT
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _selectedIndex,
              builder: (_, currentIndex, _) {
                return _userBloc.state.accountType == 'Designer'
                    ? _designerPageList[currentIndex]
                    : _regularUserPageList[currentIndex];
              },
            ),
          ),

          // BANNER AD ABOVE BOTTOM NAV
          if (_bannerAd != null) ...[
            const SizedBox(height: 8),
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              color: Colors.transparent,
              child: AdWidget(ad: _bannerAd!),
            ),
          ],
        ],
      ),

      bottomNavigationBar: NavigationBar(
        elevation: 0,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: const Icon(Icons.people_alt),
            label: _userBloc.state.accountType == 'Designer'
                ? 'Clients'
                : 'Designers',
          ),
          NavigationDestination(
            icon: const Icon(Icons.checkroom_outlined),
            selectedIcon: const Icon(Icons.checkroom),
            label: 'Closet',
          ),
          NavigationDestination(
            icon: _buildProfileIcon(selected: false),
            selectedIcon: _buildProfileIcon(selected: true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon({required bool selected}) {
    return BlocBuilder<UserBloc, User>(
      builder: (context, user) {
        final avatar = CircleAvatar(
          radius: 16,
          backgroundColor: context.iconSubstrate,
          child: Container(
            margin: const EdgeInsets.all(2),
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: CachedNetworkImage(
              imageUrl: user.profileImage,
              errorListener: (error) {},
              placeholder: (context, url) => DefaultProfileAvatar(
                key: ValueKey(user.uid),
                name: null,
                size: 18 * 1.8,
                uid: user.uid!,
              ),
              errorWidget: (context, url, error) => DefaultProfileAvatar(
                key: ValueKey(user.uid),
                name: null,
                size: 18 * 1.8,
                uid: user.uid!,
              ),
            ),
          ),
        );
        if (!selected) return avatar;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.accent, width: 1),
          ),
          child: avatar,
        );
      },
    );
  }
}
