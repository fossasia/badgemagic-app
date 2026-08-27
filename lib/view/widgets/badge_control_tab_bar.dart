import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class BadgeControlTabBar extends StatelessWidget {
  final TabController controller;

  const BadgeControlTabBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        labelColor: colorOnSurface,
        unselectedLabelColor: mdGrey400,
        indicatorColor: colorPrimary,
        controller: controller,
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.pressed) ? dividerColor : null,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        tabs: [
          Tab(
            key: const ValueKey('tab_speed'),
            text: l10n.speedTitle,
          ),
          Tab(
            key: const ValueKey('tab_transition'),
            text: l10n.transitionTitle,
          ),
          Tab(
            key: const ValueKey('tab_effects'),
            text: l10n.effectsTitle,
          ),
          Tab(
            key: const ValueKey('tab_animation'),
            text: l10n.animation,
          ),
        ],
      ),
    );
  }
}
