import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/badge_effect/flash_effect.dart';
import 'package:badgemagic/badge_effect/marquee_effect.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SaveBadgeDialog extends StatelessWidget {
  final SpeedDialProvider speed;
  final bool isInverse;
  final AnimationBadgeProvider animationProvider;
  final TextEditingController textController;
  final String? fontFamily;

  const SaveBadgeDialog({
    super.key,
    required this.textController,
    required this.isInverse,
    required this.animationProvider, // Restore this parameter
    required this.speed,
    this.fontFamily,
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
        height: 150.h,
        width: 300.w,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 1,
              child: Text(
                'Save Badge',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Text(
              'File Name',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: badgeNameController,
              autofocus: true,
              onTap: () {
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
                  borderSide: BorderSide(color: Colors.red, width: 2),
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
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final trimmedBadgeName = badgeNameController.text.trim();
                    final filePath = '${directory.path}/$trimmedBadgeName.json';
                    final file = File(filePath);

                    final files = directory.listSync();
                    List<String> caseInsensitiveMatches = [];
                    for (var f in files) {
                      if (f is File) {
                        final filename =
                            f.path.split(Platform.pathSeparator).last;
                        if (filename.toLowerCase().endsWith('.json')) {
                          final baseName =
                              filename.substring(0, filename.length - 5).trim();
                          if (baseName.toLowerCase() ==
                              trimmedBadgeName.toLowerCase()) {
                            caseInsensitiveMatches.add(filename);
                          }
                        }
                      }
                    }

                    String? caseInsensitiveMatch =
                        caseInsensitiveMatches.isNotEmpty
                            ? caseInsensitiveMatches.first
                            : null;

                    bool caseSensitiveExists = await file.exists();

                    if (caseSensitiveExists) {
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
                        ToastUtils()
                            .showToast('Please enter a new badge name.');
                        return;
                      } else if (result == 'update') {
                        savedBadgeProvider.saveBadgeData(
                          badgeNameController.text,
                          textController.text,
                          animationProvider.isEffectActive(FlashEffect()),
                          animationProvider.isEffectActive(MarqueeEffect()),
                          isInverse,
                          speed.getOuterValue(),
                          animationProvider.getAnimationIndex() ?? 1,
                          fontStyle:
                              fontFamily != null && fontFamily!.isNotEmpty
                                  ? GoogleFonts.getFont(fontFamily!)
                                  : null,
                        );
                        ToastUtils().showToast('Badge updated successfully.');
                        Future.delayed(const Duration(milliseconds: 100), () {
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil(
                                  '/savedBadge', (route) => false);
                        });
                        return;
                      } else {
                        return;
                      }
                    } else if (caseInsensitiveMatch != null) {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Similar badge name exists'),
                          content: Text(
                              "A badge with a similar name already exists: '${caseInsensitiveMatch.substring(0, caseInsensitiveMatch.length - 5)}'. What would you like to do?"),
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
                        ToastUtils()
                            .showToast('Please enter a new badge name.');
                        return;
                      } else if (result == 'update') {
                        final existingFilePath =
                            '${directory.path}/$caseInsensitiveMatch';
                        final existingFile = File(existingFilePath);
                        await existingFile.writeAsString('');
                        savedBadgeProvider.saveBadgeData(
                          caseInsensitiveMatch.substring(
                              0, caseInsensitiveMatch.length - 5),
                          textController.text,
                          animationProvider.isEffectActive(FlashEffect()),
                          animationProvider.isEffectActive(MarqueeEffect()),
                          isInverse,
                          speed.getOuterValue(),
                          animationProvider.getAnimationIndex() ?? 1,
                          fontStyle:
                              fontFamily != null && fontFamily!.isNotEmpty
                                  ? GoogleFonts.getFont(fontFamily!)
                                  : null,
                        );
                        ToastUtils().showToast('Badge updated successfully.');
                        Future.delayed(const Duration(milliseconds: 100), () {
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil(
                                  '/savedBadge', (route) => false);
                        });
                        return;
                      } else {
                        return;
                      }
                    } else {
                      savedBadgeProvider.saveBadgeData(
                        badgeNameController.text,
                        textController.text,
                        animationProvider.isEffectActive(FlashEffect()),
                        animationProvider.isEffectActive(MarqueeEffect()),
                        isInverse,
                        speed.getOuterValue(),
                        animationProvider.getAnimationIndex() ?? 1,
                        fontStyle: fontFamily != null && fontFamily!.isNotEmpty
                            ? GoogleFonts.getFont(fontFamily!)
                            : null,
                      );
                      ToastUtils().showToast('Badge saved successfully.');
                      Navigator.of(context).pop();
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
