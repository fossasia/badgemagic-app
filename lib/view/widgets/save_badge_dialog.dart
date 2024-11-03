import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SaveBadgeDialog extends StatelessWidget {
  final SpeedDialProvider speed;
  final bool isInverse;
  final AnimationBadgeProvider animationProvider;
  const SaveBadgeDialog({
    super.key,
    required this.textController,
    required this.isInverse,
    required this.animationProvider,
    required this.speed,
  });

  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    SavedBadgeProvider savedBadgeProvider = SavedBadgeProvider();
    TextEditingController badgeNameController = TextEditingController();
    badgeNameController.text = DateTime.now().toString();
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Container(
        height: 150.h, // Increase height for TextField space
        width: 300.w, // Increased width
        padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 10.h), // Added padding for better layout
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: const Text(
                'Save Badge',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // const SizedBox(
            //     height: 10), // Space between title and file name text
            const Text(
              'File Name',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
            const SizedBox(
                height: 10), // Space between file name and text field
            TextField(
              controller: badgeNameController,
              autofocus: true,
              onTap: () {
                // Select all text when the TextField is tapped
                textController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: textController.text.length,
                );
              },
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.red,
                      width: 2), // Thicker border when focused
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    )),
                TextButton(
                  onPressed: () {
                    logger.i(
                        "Flash Effect ${animationProvider.isEffectActive(FlashEffect())} , Marquee Effect ${animationProvider.isEffectActive(MarqueeEffect())} , invert $isInverse , speed ${speed.getOuterValue()} , animation ${animationProvider.getAnimationIndex() ?? 1}");
                    savedBadgeProvider.saveBadgeData(
                        badgeNameController.text,
                        textController.text,
                        animationProvider.isEffectActive(FlashEffect()),
                        animationProvider.isEffectActive(MarqueeEffect()),
                        isInverse,
                        speed.getOuterValue(),
                        animationProvider.getAnimationIndex() ?? 1);
                    ToastUtils().showToast("Badge Saved Successfully");
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
