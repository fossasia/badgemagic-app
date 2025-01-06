import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class BMDrawer extends StatefulWidget {
  final int selectedIndex;

  const BMDrawer({super.key, required this.selectedIndex});

  @override
  State<BMDrawer> createState() => _BMDrawerState();
}

class _BMDrawerState extends State<BMDrawer> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.selectedIndex;
  }

  void updateSelectedIndex(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: drawerHeaderTitle,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/drawer_headre.PNG'),
                  fit: BoxFit.cover,
                ),
                color: Colors.red,
              ),
              child: Center(
                child: Text(
                  'Badge Magic',
                  style: TextStyle(
                      color: drawerHeaderTitle,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          _buildListTile(
            index: 0,
            icon: Icons.edit,
            title: 'Create Badges',
            routeName: '/',
          ),
          _buildListTile(
            index: 1,
            assetIcon: "assets/icons/signature.png",
            title: 'Draw Clipart',
            routeName: '/drawBadge',
          ),
          _buildListTile(
            index: 2,
            assetIcon: "assets/icons/r_save.png",
            title: 'Saved Badges',
            routeName: '/savedBadge',
          ),
          _buildListTile(
            index: 3,
            assetIcon: "assets/icons/r_save.png",
            title: 'Saved Cliparts',
            routeName: '/savedClipart',
          ),
          _buildListTile(
            index: 4,
            assetIcon: "assets/icons/setting.png",
            title: 'Settings',
            routeName: '/settings',
          ),
          _buildListTile(
            index: 5,
            assetIcon: "assets/icons/r_team.png",
            title: 'About Us',
            routeName: '/aboutUs',
          ),
          const Divider(),
          const Padding(
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
          _buildListTile(
            index: 6,
            assetIcon: "assets/icons/r_price.png",
            title: 'Buy Badge',
            routeName: '/buyBadge',
            externalLink: 'https://badgemagic.fossasia.org/shop/',
          ),
          _buildListTile(
            index: 7,
            icon: Icons.share,
            title: 'Share',
            routeName: '/share',
            shareText:
                'Badge Magic is an Android app to control LED name badges. This app provides features to portray names, graphics and simple animations on LED badges. You can also download it from below link https://play.google.com/store/apps/details?id=org.fossasia.badgemagic',
          ),
          _buildListTile(
            index: 8,
            icon: Icons.star,
            title: 'Rate Us',
            routeName: '/rateUs',
            externalLink:
                'https://play.google.com/store/apps/details?id=org.fossasia.badgemagic',
          ),
          _buildListTile(
            index: 9,
            assetIcon: "assets/icons/r_virus.png",
            title: 'Feedback/Bug Reports',
            routeName: '/feedback',
            externalLink: 'https://github.com/fossasia/badgemagic-app/issues',
          ),
          _buildListTile(
            index: 10,
            assetIcon: "assets/icons/r_insurance.png",
            title: 'Privacy Policy',
            routeName: '/privacyPolicy',
            externalLink: 'https://badgemagic.fossasia.org/privacy/',
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required int index,
    IconData? icon,
    String? assetIcon,
    required String title,
    required String routeName,
    String? externalLink,
    String? shareText,
  }) {
    return ListTile(
      dense: true,
      leading: icon != null
          ? Icon(
              icon,
              color: currentIndex == index ? colorAccent : Colors.black,
            )
          : Image.asset(
              assetIcon!,
              height: 18,
              color: currentIndex == index ? colorAccent : Colors.black,
            ),
      title: Text(
        title,
        style: TextStyle(
          color: currentIndex == index ? colorAccent : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      selected: currentIndex == index,
      selectedTileColor: dividerColor,
      onTap: () {
        updateSelectedIndex(index);

        Navigator.pop(context);

        if (externalLink != null) {
          openUrl(externalLink);
        } else if (shareText != null) {
          Share.share(shareText);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            routeName,
            (route) => route.isFirst,
          );
        }
      },
    );
  }
}
