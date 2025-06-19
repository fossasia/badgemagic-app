import 'package:badgemagic/constants.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class BMDrawer extends StatefulWidget {
  final int selectedIndex;

  const BMDrawer({super.key, required this.selectedIndex});

  @override
  State<BMDrawer> createState() => _BMDrawerState();
}

class _BMDrawerState extends State<BMDrawer> {
  late AppLocalizations? loc;
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
    loc = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: drawerHeaderTitle,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.red,
              ),
              child: Center(
                child: Text(
                  loc?.appTitle ?? 'Badge Magic',
                  style: const TextStyle(
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
            title: loc?.drawerCreateBadges ?? 'Create Badges',
            routeName: '/',
          ),
          _buildListTile(
            index: 1,
            assetIcon: "assets/icons/signature.png",
            title: loc?.drawerDrawClipart ?? 'Draw Clipart',
            routeName: '/drawBadge',
          ),
          _buildListTile(
            index: 2,
            assetIcon: "assets/icons/r_save.png",
            title: loc?.drawerSavedBadges ?? 'Saved Badges',
            routeName: '/savedBadge',
          ),
          _buildListTile(
            index: 3,
            assetIcon: "assets/icons/r_save.png",
            title: loc?.drawerSavedCliparts ?? 'Saved Cliparts',
            routeName: '/savedClipart',
          ),
          _buildListTile(
            index: 4,
            assetIcon: "assets/icons/setting.png",
            title: loc?.drawerSettings ?? 'Settings',
            routeName: '/settings',
          ),
          _buildListTile(
            index: 5,
            assetIcon: "assets/icons/r_team.png",
            title: loc?.drawerAboutUs ?? 'About Us',
            routeName: '/aboutUs',
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Text(
              loc?.drawerOther ?? 'Other',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _buildListTile(
            index: 6,
            assetIcon: "assets/icons/r_price.png",
            title: loc?.drawerBuyBadge ?? 'Buy Badge',
            routeName: '/buyBadge',
            externalLink: 'https://badgemagic.fossasia.org/shop/',
          ),
          _buildListTile(
            index: 7,
            icon: Icons.share,
            title: loc?.drawerShare ?? 'Share',
            routeName: '/share',
            shareText: loc?.drawerShareText ??
                'Badge Magic is an app to control LED name badges. This app provides features to portray names, graphics and simple animations on LED badges. You can also download it from below link https://play.google.com/store/apps/details?id=org.fossasia.badgemagic',
          ),
          _buildListTile(
            index: 8,
            icon: Icons.star,
            title: loc?.drawerRateUs ?? 'Rate Us',
            routeName: '/rateUs',
            externalLink: Platform.isIOS
                ? 'https://apps.apple.com/us/app/badge-magic/id6740176888?action=write-review'
                : 'https://play.google.com/store/apps/details?id=org.fossasia.badgemagic',
          ),
          _buildListTile(
            index: 9,
            assetIcon: "assets/icons/r_virus.png",
            title: loc?.drawerFeedback ?? 'Feedback/Bug Reports',
            routeName: '/feedback',
            externalLink: 'https://github.com/fossasia/badgemagic-app/issues',
          ),
          _buildListTile(
            index: 10,
            assetIcon: "assets/icons/r_insurance.png",
            title: loc?.drawerPrivacyPolicy ?? 'Privacy Policy',
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
