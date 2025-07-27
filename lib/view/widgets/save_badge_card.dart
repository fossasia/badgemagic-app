import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SaveBadgeCard extends StatelessWidget {
  final MapEntry<String, Map<String, dynamic>> badgeData;

  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback;
  final FileHelper file = FileHelper();
  final Converters converters = Converters();
  final ToastUtils toastUtils = ToastUtils();
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  SaveBadgeCard({
    super.key,
    required this.badgeData,
    required this.refreshBadgesCallback,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  // Helper methods to safely access badge data properties
  bool _safeGetFlashValue(Map<String, dynamic> data) {
    try {
      return file.jsonToData(data).messages[0].flash;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  bool _safeGetMarqueeValue(Map<String, dynamic> data) {
    try {
      return file.jsonToData(data).messages[0].marquee;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  bool _safeGetInvertValue(Map<String, dynamic> data) {
    try {
      if (data.containsKey('messages') &&
          data['messages'] is List &&
          data['messages'].isNotEmpty &&
          data['messages'][0] is Map<String, dynamic>) {
        return data['messages'][0]['invert'] ?? false;
      }
      return false;
    } catch (e) {
      // If there's an error, default to false
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    BadgeMessageProvider badge = BadgeMessageProvider();
    return GestureDetector(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Container(
          width: 370.w,
          padding: EdgeInsets.all(6.dg),
          margin: EdgeInsets.all(10.dg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.dg),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border:
                isSelected ? Border.all(color: colorPrimary, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Wrapping the text with Flexible to ensure it doesn't overflow.
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: 8
                              .w), // Adding some padding to separate text and buttons
                      child: Text(
                        badgeData.key.substring(0, badgeData.key.length - 5),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow
                            .ellipsis, // Use ellipsis to indicate overflowed text
                        maxLines: 1, // Limit to 1 line for a cleaner look
                      ),
                    ),
                  ),
                  Consumer<SavedBadgeProvider>(
                    builder: (context, provider, widget) => Row(
                      mainAxisSize: MainAxisSize.min, // Keep the row compact
                      children: [
                        IconButton(
                          icon: Image.asset(
                            "assets/icons/t_play.png",
                            height: 20,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            provider.savedBadgeAnimation(
                                badgeData.value,
                                Provider.of<AnimationBadgeProvider>(context,
                                    listen: false));
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            final shouldEdit = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit Badge'),
                                content: const Text(
                                    'Do you want to edit this badge?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldEdit == true) {
                              // Extract the speed value from the saved badge
                              final speed = Speed.getIntValue(file
                                  .jsonToData(badgeData.value)
                                  .messages[0]
                                  .speed);
                              String badgeFilename = badgeData.key;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(
                                    savedBadgeFilename: badgeFilename,
                                    initialSpeed: speed, // Pass the speed value
                                  ),
                                ),
                                (route) => false, // Remove all previous routes
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            "assets/icons/t_updown.png",
                            height: 24.h,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            logger.d("BadgeData: ${badgeData.value}");
                            //We can Acrtually call a method to generate the data just by transffering the JSON data
                            //so we would not necessarily need the Providers.
                            badge.checkAndTransfer(null, null, null, null, null,
                                null, badgeData.value, true);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            file.shareBadgeData(badgeData.key);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            //add a dialog for confirmation before deleting
                            await _showDeleteDialog(context)
                                .then((value) async {
                              if (value == true) {
                                file.deleteFile(badgeData.key);
                                toastUtils
                                    .showToast("Badge Deleted Successfully");
                                await refreshBadgesCallback(badgeData);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Row(
                    children: [
                      Visibility(
                        visible: _safeGetFlashValue(badgeData.value),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/icons/flash.png",
                                color: Colors.white,
                                height: 14.h,
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Visibility(
                        visible: _safeGetMarqueeValue(badgeData.value),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/icons/square.png",
                                color: Colors.white,
                                height: 14.h,
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Visibility(
                        visible: _safeGetInvertValue(badgeData.value),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorPrimary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/icons/t_invert.png",
                                color: Colors.white,
                                height: 14.h,
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/icons/t_double.png",
                            color: Colors.white,
                            height: 14.h,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Speed.getIntValue(file
                                    .jsonToData(badgeData.value)
                                    .messages[0]
                                    .speed)
                                .toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        file
                            .jsonToData(badgeData.value)
                            .messages[0]
                            .mode
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Consumer<BadgeSlotProvider>(
                    builder: (context, selectionProvider, _) {
                      final isSelected =
                          selectionProvider.isSelected(badgeData.key);
                      return Switch(
                        value: isSelected,
                        onChanged: (selectionProvider.canSelectMore ||
                                isSelected)
                            ? (value) =>
                                selectionProvider.toggleSelection(badgeData.key)
                            : null,
                        activeColor: colorPrimary,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteBadgeDialog();
      },
    );
  }
}
