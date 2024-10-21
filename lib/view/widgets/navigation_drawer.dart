import 'package:badgemagic/providers/badgeview_provider.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/save_badge_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BMDrawer extends StatelessWidget {
  const BMDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    DrawBadgeProvider badgeProvider = Provider.of(context);
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
            leading: const Icon(Icons.edit),
            title: const Text(
              'Create Badges',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            onTap: () {
              badgeProvider.stopAllAnimations();
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const HomeScreen();
              }));
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/signature.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Draw Clipart',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14),
            ),
            onTap: () {
              badgeProvider.stopAllAnimations();
              Navigator.pushNamed(context, '/drawBadge');
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_save.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Saved Badges',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              badgeProvider.stopAllAnimations();
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const SaveBadgeScreen();
              }));
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_save.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Saved Cliparts',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            onTap: () {
              badgeProvider.stopAllAnimations();
              Navigator.pushNamed(context, '/savedClipart');
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/setting.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            dense: true,
            leading: Image.asset(
              "assets/icons/r_team.png",
              height: 18,
              color: Colors.black,
            ),
            title: const Text(
              'About Us',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
            },
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
                      fontSize: 14),
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
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
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
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
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
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
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
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
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
                  fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
