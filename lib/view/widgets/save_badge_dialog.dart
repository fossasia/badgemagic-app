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
import 'package:badgemagic/l10n/app_localizations.dart';

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
    badgeNameController.text =
        '${AppLocalizations.of(context)!.badge} ${DateTime.now().toString()}';

    // Set up the initial selection to select all text when the dialog opens
    badgeNameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: badgeNameController.text.length,
    );
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
              child: Text(
                AppLocalizations.of(context)!.saveBadge,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.badgeName,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: badgeNameController,
              autofocus: true,
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
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.red),
                    )),
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
                          title: Text(
                              AppLocalizations.of(context)!.badgeNameExists),
                          content: Text(
                              AppLocalizations.of(context)!.badgeExistsMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'rename'),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'update'),
                              child:
                                  Text(AppLocalizations.of(context)!.overwrite),
                            ),
                          ],
                        ),
                      );
                      if (result == 'rename') {
                        ToastUtils().showToast(AppLocalizations.of(context)!
                            .pleaseEnterNewBadgeName);
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
                        );
                        ToastUtils().showToast(AppLocalizations.of(context)!
                            .badgeUpdatedSuccessfully);
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
                          title: Text(
                              AppLocalizations.of(context)!.similarBadgeExists),
                          content: Builder(
                            builder: (context) {
                              final badgeName = caseInsensitiveMatch.substring(
                                  0, caseInsensitiveMatch.length - 5);
                              final message = AppLocalizations.of(context)!
                                  .similarBadgeExistsMessage(badgeName);
                              return Text(message);
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'rename'),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'update'),
                              child:
                                  Text(AppLocalizations.of(context)!.overwrite),
                            ),
                          ],
                        ),
                      );
                      if (result == 'rename') {
                        ToastUtils().showToast(AppLocalizations.of(context)!
                            .pleaseEnterNewBadgeName);
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
                        );
                        ToastUtils().showToast(AppLocalizations.of(context)!
                            .badgeUpdatedSuccessfully);
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
                      );
                      ToastUtils().showToast(
                          AppLocalizations.of(context)!.badgeSavedSuccessfully);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(color: Colors.red),
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
