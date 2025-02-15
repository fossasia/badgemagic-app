import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/badge_effect/badgeeffectabstract.dart';
import 'package:badgemagic/badge_effect/invert_led_effect.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EffectContainer extends StatefulWidget {
  final String effect;
  final String effectName;
  final int index;

  const EffectContainer({
    super.key,
    required this.effect,
    required this.effectName,
    required this.index,
  });

  @override
  State<EffectContainer> createState() => _EffectContainerState();
}

class _EffectContainerState extends State<EffectContainer> {
  BadgeEffect? badgeEffect;
  String selectedFont = 'Roboto'; // Default font
  double fontSize = 16.0; // Default size
  Color textColor = Colors.black; // Default color

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
        Provider.of<AnimationBadgeProvider>(context, listen: false);

    return Container(
      margin: EdgeInsets.all(5.w),
      height: 90.h,
      width: 110.w,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (effectCardState.isEffectActive(badgeEffect)) {
              effectCardState.removeEffect(badgeEffect);
            } else {
              effectCardState.addEffect(badgeEffect);
            }
          });

          // Update badge text with font settings
          TextStyle textStyle = GoogleFonts.getFont(
            selectedFont,
            fontSize: fontSize,
            color: textColor,
          );

          effectCardState.badgeAnimation(
            imageProvider.getController().text,
            Converters(),
            effectCardState.isEffectActive(InvertLEDEffect()),
            textStyle: textStyle, // Apply font settings
          );
        },
        child: Card(
          surfaceTintColor: Colors.white,
          color: effectCardState.isEffectActive(badgeEffect)
              ? colorAccent
              : drawerHeaderTitle,
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
              Text(
                widget.effectName,
                style: GoogleFonts.getFont(selectedFont, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
