import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class BadgeControlTabBar extends StatelessWidget {
  final TabController controller;
  final bool isNarrow;

  const BadgeControlTabBar({
    super.key,
    required this.controller,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Container(
      margin: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorSurfaceSubtle,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colorTransparent,
        indicator: BoxDecoration(
          color: colorPrimary,
          borderRadius: BorderRadius.circular(30.r),
        ),
        splashBorderRadius: BorderRadius.circular(30.r),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        labelColor: colorOnPrimary,
        unselectedLabelColor: mdGrey400,
        controller: controller,
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.all(colorTransparent),
        labelPadding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: isNarrow ? 1.h : 2.h,
        ),
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
