// import 'package:flutter/material.dart';
// import 'package:niit/ui/screens/settings.dart';
// import 'package:niit/utils/colors.dart';
// import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

// import 'package:niit/ui/screens/homepage.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late PersistentTabController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = PersistentTabController(initialIndex: 0);
//   }

//   List<Widget> _buildScreens() {
//     // Les écrans à afficher dans les onglets.
//     return [const HomePage(), const SettingsPage()];
//   }

//   List<PersistentBottomNavBarItem> _navBarsItems() {
//     return [
//       PersistentBottomNavBarItem(
//         icon: const Icon(Icons.home_outlined),
//         // title: ("Accueil"),
//         activeColorPrimary: AppColors.k_card_green,
//         inactiveColorPrimary: Colors.grey,
//       ),
//       PersistentBottomNavBarItem(
//         icon: const Icon(Icons.settings),
//         // title: ("Paramètres"),
//         activeColorPrimary: AppColors.k_card_green,
//         inactiveColorPrimary: Colors.grey,
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PersistentTabView(
//       context,
//       controller: _controller,
//       screens: _buildScreens(),
//       items: _navBarsItems(),
//       navBarStyle: NavBarStyle.style6,
//       backgroundColor: Colors.white,
//       decoration: NavBarDecoration(
//         borderRadius: BorderRadius.circular(10.0),
//         colorBehindNavBar: Colors.white,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niit/ui/screens/interventions.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
// import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';

import 'package:niit/ui/screens/homepage.dart';
import 'package:niit/ui/screens/scan/scanhome.dart';
import 'package:niit/ui/screens/settings.dart';
import 'package:niit/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final PersistentTabController _controller;
  late final AnimationController _scanGlowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _scanGlowCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() => const [
    HomePage(),
    // PlateRecognitionScreen(),
    SettingsPage(),
  ];

  List<PersistentBottomNavBarItem> _items() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        title: "Accueil",
        activeColorPrimary: AppColors.k_card_green,
        inactiveColorPrimary: Colors.grey,
      ),
      // Onglet central : Scan (verre + néon + glow animé)
      // PersistentBottomNavBarItem(
      //   icon: AnimatedBuilder(
      //     animation: _scanGlowCtrl,
      //     builder: (_, __) {
      //       final t = _scanGlowCtrl.value; // 0..1
      //       return Container(
      //         padding: const EdgeInsets.all(10),
      //         decoration: BoxDecoration(
      //           shape: BoxShape.circle,
      //           color: Colors.white.withOpacity(.92),
      //           border: Border.all(
      //             color: Colors.cyanAccent.withOpacity(.4 + .3 * t),
      //             width: 1.4,
      //           ),
      //           boxShadow: [
      //             BoxShadow(
      //               blurRadius: 24,
      //               spreadRadius: -8,
      //               color: Colors.cyanAccent.withOpacity(.22 + .22 * t),
      //             ),
      //           ],
      //         ),
      //         child: const Icon(Icons.document_scanner, color: Colors.black87),
      //       );
      //     },
      //   ),
      //   title: "Scan",
      //   activeColorPrimary: Colors.cyanAccent,
      //   inactiveColorPrimary: Colors.cyanAccent,
      // ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings_outlined),
        title: "Réglages",
        activeColorPrimary: AppColors.k_card_green,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _items(),

      navBarStyle: NavBarStyle.style6,
      backgroundColor: Colors.white.withOpacity(.92),
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
        colorBehindNavBar: Colors.white,
      ),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      navBarHeight: 68,

      // Ces deux lignes doivent être retirées si tu es en v1 :
      // itemAnimationProperties: ...
      // screenTransitionAnimation: ...
      // hideNavigationBarWhenKeyboardShows: true,
      confineToSafeArea: true,
      stateManagement: true,
      handleAndroidBackButtonPress: true,
      // popAllScreensOnTapOfSelectedTab: true,
      onItemSelected: (_) => HapticFeedback.selectionClick(),
    );
  }
}
