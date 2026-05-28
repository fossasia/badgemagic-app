import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:get_it/get_it.dart';

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
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Drawer(
      backgroundColor: drawerHeaderTitle,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Center(
                child: Text(
                  l10n.appTitle,
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
            title: l10n.createBadges,
            routeName: '/',
          ),
          Semantics(
            label: 'Draw Clipart',
            child: _buildListTile(
              index: 1,
              assetIcon: "assets/icons/signature.png",
              title: l10n.drawClipart,
              routeName: '/drawBadge',
            ),
          ),
          Semantics(
            label: 'Saved Badges',
            child: _buildListTile(
              index: 2,
              assetIcon: "assets/icons/r_save.png",
              title: l10n.savedBadges,
              routeName: '/savedBadge',
            ),
          ),
          _buildListTile(
            index: 3,
            assetIcon: "assets/icons/r_save.png",
            title: l10n.savedCliparts,
            routeName: '/savedClipart',
          ),
          _buildListTile(
            index: 4,
            assetIcon: "assets/icons/setting.png",
            title: l10n.settings,
            routeName: '/settings',
          ),
          _buildListTile(
            index: 5,
            assetIcon: "assets/icons/r_team.png",
            title: l10n.aboutUs,
            routeName: '/aboutUs',
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Text(
              l10n.other,
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
            title: l10n.buyBadge,
            routeName: '/buyBadge',
            externalLink: 'https://badgemagic.fossasia.org/shop/',
          ),
          _buildListTile(
            index: 7,
            icon: Icons.share,
            title: l10n.shareApp,
            routeName: '/share',
            shareText: l10n.shareAppText,
          ),
          _buildListTile(
            index: 8,
            icon: Icons.star,
            title: l10n.rateUs,
            routeName: '/rateUs',
            externalLink: Platform.isIOS
                ? 'https://apps.apple.com/us/app/badge-magic/id6740176888?action=write-review'
                : 'https://play.google.com/store/apps/details?id=org.fossasia.badgemagic',
          ),
          _buildListTile(
            index: 9,
            assetIcon: "assets/icons/r_virus.png",
            title: l10n.feedbackBugReports,
            routeName: '/feedback',
            externalLink: 'https://github.com/fossasia/badgemagic-app/issues',
          ),
          _buildListTile(
            index: 10,
            assetIcon: "assets/icons/r_insurance.png",
            title: l10n.privacyPolicy,
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
    required dynamic title,
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
      title: title is String
          ? Text(
              title,
              style: TextStyle(
                color: currentIndex == index ? colorAccent : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : title,
      selected: currentIndex == index,
      selectedTileColor: dividerColor,
      onTap: () {
        updateSelectedIndex(index);

        Navigator.pop(context);

        if (externalLink != null) {
          openUrl(externalLink);
        } else if (shareText != null) {
          SharePlus.instance.share(ShareParams(text: shareText));
        } else {
          if (ModalRoute.of(context)?.settings.name == routeName) {
            return;
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              routeName,
              (route) => route.isFirst,
            );
          }
        }
      },
    );
  }
}
