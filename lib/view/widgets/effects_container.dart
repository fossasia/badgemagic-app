import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
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
    InlineImageProvider imageProvider =
        Provider.of<InlineImageProvider>(context, listen: false);
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
          effectCardState.badgeAnimation(imageProvider.getController().text,
              Converters(), effectCardState.isEffectActive(InvertLEDEffect()));
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
              Flexible(
                child: Image.asset(
                  widget.effect,
                  fit: BoxFit.contain,
                ),
              ),
              Text(widget.effectName),
            ],
          ),
        ),
      ),
    );
  }
}
