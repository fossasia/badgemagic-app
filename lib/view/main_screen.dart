import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/about_us_screen.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:badgemagic/view/saved_clipart.dart';
import 'package:badgemagic/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final List<String> appBarTitles = [
    'Badge Magic',
    'Draw Clipart',
    'Saved Badges',
    'Saved Cliparts',
    'Settings',
    'About Us',
  ];

  @override
  void initState() {
    super.initState();
    updateOrientation();
  }

  void onDrawerItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
    updateOrientation();
    Navigator.of(context).pop();
  }

  void updateOrientation() {
    if (currentIndex == 1) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          );
        }),
        backgroundColor: Colors.red,
        title: Text(
          appBarTitles[currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
      ),
      drawer: CommonDrawer(
        onTap: onDrawerItemTapped,
        selectedIndex: currentIndex,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeScreen(),
          DrawBadge(),
          SaveBadgeScreen(),
          SavedClipart(),
          SettingsScreen(),
          AboutUsScreen(),
        ],
      ),
    );
  }
}

class CommonDrawer extends StatelessWidget {
  final Function(int) onTap;
  final int selectedIndex;
  const CommonDrawer(
      {required this.onTap, super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red,
            ),
            child: Center(
              child: Text(
                'Badge Magic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: Icon(
              Icons.edit,
              color: selectedIndex == 0 ? Colors.red : Colors.black,
            ),
            title: Text(
              'Create Badges',
              style: TextStyle(
                color: selectedIndex == 0 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            selected: selectedIndex == 0,
            selectedTileColor: Colors.grey.shade100,
            onTap: () => onTap(0),
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/signature.png",
              height: 18,
              color: selectedIndex == 1 ? Colors.red : Colors.black,
            ),
            selected: selectedIndex == 1,
            selectedTileColor: Colors.grey.shade100,
            title: Text(
              'Draw Clipart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedIndex == 1 ? Colors.red : Colors.black,
                fontSize: 14,
              ),
            ),
            onTap: () => onTap(1),
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_save.png",
              height: 18,
              color: selectedIndex == 2 ? Colors.red : Colors.black,
            ),
            selected: selectedIndex == 2,
            selectedTileColor: Colors.grey.shade100,
            title: Text(
              'Saved Badges',
              style: TextStyle(
                color: selectedIndex == 2 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () => onTap(2),
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_save.png",
              height: 18,
              color: selectedIndex == 3 ? Colors.red : Colors.black,
            ),
            selected: selectedIndex == 3,
            selectedTileColor: Colors.grey.shade100,
            title: Text(
              'Saved Cliparts',
              style: TextStyle(
                color: selectedIndex == 3 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () => onTap(3),
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/setting.png",
              height: 18,
              color: selectedIndex == 4 ? Colors.red : Colors.black,
            ),
            selected: selectedIndex == 4,
            selectedTileColor: Colors.grey.shade100,
            title: Text(
              'Settings',
              style: TextStyle(
                color: selectedIndex == 4 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () => onTap(4),
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_team.png",
              height: 18,
              color: selectedIndex == 5 ? Colors.red : Colors.black,
            ),
            selected: selectedIndex == 5,
            selectedTileColor: Colors.grey.shade100,
            title: Text(
              'About Us',
              style: TextStyle(
                color: selectedIndex == 5 ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () => onTap(5),
          ),
          const Divider(),
          const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
                child: Text(
                  'Other',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_price.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Buy Badge',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              openUrl('https://badgemagic.fossasia.org/shop/');
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.share,
              color: Colors.black,
            ),
            title: const Text(
              'Share',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                  'Badge Magic is an Android app to control LED name badges. This app provides features to portray names, graphics and simple animations on LED badges.You can also download it from below link https://play.google.com/store/apps/details?id=org.fossasia.badgemagic ');
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.star,
              color: Colors.black,
            ),
            title: const Text(
              'Rate Us',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              openUrl(
                  'https://play.google.com/store/apps/details?id=org.fossasia.badgemagic');
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_virus.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Feedback/Bug Reports',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              openUrl('https://github.com/fossasia/badgemagic-android/issues');
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_insurance.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              openUrl('https://badgemagic.fossasia.org/privacy/');
            },
          ),
        ],
      ),
    );
  }
}
