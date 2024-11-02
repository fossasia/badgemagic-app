import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EffectContainer extends StatefulWidget {
  final String effect;
  final String effectName;
  final int index;

  const EffectContainer(
      {super.key,
      required this.effect,
      required this.effectName,
      required this.index});

  @override
  State<EffectContainer> createState() => _EffectContainerState();
}

class _EffectContainerState extends State<EffectContainer> {
  BadgeEffect? badgeEffect;

  @override
  void initState() {
    super.initState();
    badgeEffect = effectMap[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    AnimationBadgeProvider effectCardState =
        Provider.of<AnimationBadgeProvider>(context);

    return Container(
      margin: EdgeInsets.all(5.w),
      height: 90.h,
      width: 110.w,
      child: GestureDetector(
        onTap: () {
          effectCardState.isEffectActive(badgeEffect)
              ? effectCardState.removeEffect(badgeEffect)
              : effectCardState.addEffect(badgeEffect);
          logger.i(
              'EffectContainer: onTap : ${widget.effectName} : ${effectCardState.isEffectActive(badgeEffect)}');
        },
        child: Card(
          surfaceTintColor: Colors.white,
          color: effectCardState.isEffectActive(badgeEffect)
              ? Colors.red
              : Colors.white,
          elevation: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.effect,
                height: 60.h,
              ),
              Text(widget.effectName),
            ],
          ),
        ),
      ),
    );
  }
}
