import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SaveBadgeDialog extends StatelessWidget {
  final SpeedDialProvider speed;
  final bool isInverse;
  final AnimationBadgeProvider animationProvider; // Restore this field
  final TextEditingController textController;

  const SaveBadgeDialog({
    super.key,
    required this.textController,
    required this.isInverse,
    required this.animationProvider, // Restore this parameter
    required this.speed,
  });

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
                  onPressed: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final filePath =
                        '${directory.path}/${badgeNameController.text}.json';
                    final file = File(filePath);
                    if (await file.exists()) {
                      // Show dialog: Cancel or Overwrite
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Badge name exists'),
                          content: const Text(
                              'A badge with this name already exists. What would you like to do?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'rename'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'update'),
                              child: const Text('Overwrite'),
                            ),
                          ],
                        ),
                      );
                      if (result == 'rename') {
                        // Do nothing, let user change the name
                        ToastUtils()
                            .showToast('Please enter a new badge name.');
                        return;
                      } else if (result == 'update') {
                        // Overwrite existing badge
                        savedBadgeProvider.saveBadgeData(
                          badgeNameController.text,
                          textController.text,
                          animationProvider.isEffectActive(FlashEffect()),
                          animationProvider.isEffectActive(MarqueeEffect()),
                          isInverse,
                          speed.getOuterValue(),
                          animationProvider.getAnimationIndex() ?? 1,
                        );
                        ToastUtils().showToast('Badge updated successfully.');
                        Navigator.of(context).pop();
                        return;
                      } else {
                        // Dialog dismissed
                        return;
                      }
                    } else {
                      // File does not exist, save as new
                      savedBadgeProvider.saveBadgeData(
                        badgeNameController.text,
                        textController.text,
                        animationProvider.isEffectActive(FlashEffect()),
                        animationProvider.isEffectActive(MarqueeEffect()),
                        isInverse,
                        speed.getOuterValue(),
                        animationProvider.getAnimationIndex() ?? 1,
                      );
                      ToastUtils().showToast('Badge saved successfully.');
                      // Reset the saved badge state since we've created a new badge
                      savedBadgeProvider.setIsSavedBadgeData(false);
                      Navigator.of(context).pop(); // Just close the dialog
                    }
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
