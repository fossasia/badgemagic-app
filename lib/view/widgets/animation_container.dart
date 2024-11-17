import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AniContainer extends StatefulWidget {
  final String animation;
  final String animationName;
  final int index;

  const AniContainer(
      {super.key,
      required this.animation,
      required this.animationName,
      required this.index});

  @override
  State<AniContainer> createState() => _AniContainerState();
}

class _AniContainerState extends State<AniContainer> {
  BadgeAnimation? badgeAnimation;

  @override
  void initState() {
    badgeAnimation = animationMap[widget.index];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AnimationBadgeProvider animationCardState =
        Provider.of<AnimationBadgeProvider>(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      height: 50.h,
      width: 110.w,
      child: GestureDetector(
        onTap: () {
          animationCardState.setAnimationMode(badgeAnimation);
        },
        child: Card(
          surfaceTintColor: Colors.white,
          color: animationCardState.isAnimationActive(badgeAnimation)
              ? Colors.red
              : Colors.white,
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Image.asset(
                  widget.animation,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                widget.animationName,
                style: TextStyle(fontSize: 9.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
