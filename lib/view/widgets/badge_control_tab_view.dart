import 'package:badgemagic/view/widgets/home_screen_tabs.dart';
import 'package:badgemagic/view/widgets/speed_dial.dart';
import 'package:badgemagic/view/widgets/transition_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BadgeControlTabView extends StatelessWidget {
  final TabController controller;
  final ValueChanged<bool>? onDialInteracting;

  const BadgeControlTabView({
    super.key,
    required this.controller,
    this.onDialInteracting,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      child: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: [
          GestureDetector(
            onPanDown: (_) => onDialInteracting?.call(true),
            onPanCancel: () => onDialInteracting?.call(false),
            onPanEnd: (_) => onDialInteracting?.call(false),
            child: RadialDial(),
          ),
          const TransitionTab(),
          const EffectTab(),
          const AnimationTab(),
        ],
      ),
    );
  }
}
