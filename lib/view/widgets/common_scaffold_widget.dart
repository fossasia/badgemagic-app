import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../providers/animation_badge_provider.dart';
import '../../services/localization_service.dart';

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final int index;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar; // 👈 Added

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    required this.index,
    this.bottomNavigationBar, // 👈 Added
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
        backgroundColor: colorPrimary,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Consumer<AnimationBadgeProvider>(
            builder: (context, animProvider, _) {
              if (!animProvider.isNgConnected) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          l10n.connected,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: BMDrawer(
        selectedIndex: index,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar, // 👈 Forwarded
    );
  }
}
