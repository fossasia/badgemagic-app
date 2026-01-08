import 'package:badgemagic/bademagic_module/models/brightness.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/brightness_provider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class BrightnessControl extends StatefulWidget {
  const BrightnessControl({super.key});

  @override
  State<BrightnessControl> createState() => _BrightnessControlState();
}

class _BrightnessControlState extends State<BrightnessControl> {
  @override
  Widget build(BuildContext context) {
    final brightnessProvider = Provider.of<BrightnessProvider>(context);
    final animationProvider = Provider.of<AnimationBadgeProvider>(context);
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    
    final bool isAnimationActive = animationProvider.isSpecialAnimationSelected();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${l10n.brightness}: ${brightnessProvider.getBrightnessPercentage()}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isAnimationActive ? Colors.grey : colorPrimaryDark,
                ),
              ),
              if (isAnimationActive) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
          if (isAnimationActive)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                l10n.brightnessNotAvailableForAnimations,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: brightnessProvider.getBrightnessPercentage().toDouble(),
                  min: 25,
                  max: 100,
                  divisions: 3,
                  activeColor: isAnimationActive ? Colors.grey : colorPrimaryDark,
                  inactiveColor: backCircleColor,
                  label: '${brightnessProvider.getBrightnessPercentage()}%',
                  onChanged: isAnimationActive ? null : (value) {
                    setState(() {
                      brightnessProvider.setBrightness(
                        Brightness.fromPercentage(value.toInt()),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
