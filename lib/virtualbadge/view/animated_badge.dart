import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AnimationBadge extends StatefulWidget {
  const AnimationBadge({super.key});

  @override
  State<AnimationBadge> createState() => _AnimationBadgeState();
}

class _AnimationBadgeState extends State<AnimationBadge> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, left: 15.w, right: 15.w),
      padding: EdgeInsets.all(8.dg),
      height: 100.h,
      width: 500.w,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Consumer<AnimationBadgeProvider>(
          builder: (context, provider, widget) {
        provider.initializeAnimation();
        return CustomPaint(
          size: const Size(400, 480),
          painter: BadgePaint(grid: provider.getPaintGrid()),
        );
      }),
    );
  }
}
