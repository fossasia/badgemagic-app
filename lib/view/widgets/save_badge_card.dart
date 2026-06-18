import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/providers/badge_slot_provider..dart';
import 'package:badgemagic/providers/imageprovider.dart';
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

  @override
  Widget build(BuildContext context) {
    BadgeMessageProvider badge = BadgeMessageProvider();
    return Container(
      width: 370.w,
      padding: EdgeInsets.all(6.dg),
      margin: EdgeInsets.all(10.dg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.dg),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
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
                          .w), // Adding some padding to separate text and buttons.
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
                        final navigator = Navigator.of(context);
                        // Show confirmation dialog before editing
                        final confirmed =
                            await provider.showEditBadgeConfirmation(context);
                        if (confirmed) {
                          // Navigate to HomeScreen for editing the badge
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                savedBadgeFilename: badgeData.key,
                              ),
                            ),
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
                            null, badgeData.value, true, context);
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
                        final slotProvider = Provider.of<BadgeSlotProvider>(
                            context,
                            listen: false);
                        final imgProvider = Provider.of<InlineImageProvider>(
                            context,
                            listen: false);
                        final aniProvider = Provider.of<AnimationBadgeProvider>(
                            context,
                            listen: false);
                        final confirmed = await _showDeleteDialog(context);
                        if (confirmed == true) {
                          file.deleteFile(badgeData.key);
                          if (slotProvider.isSelected(badgeData.key)) {
                            slotProvider.toggleSelection(badgeData.key);
                          }
                          toastUtils.showToast("Badge Deleted Successfully");
                          await refreshBadgesCallback(badgeData);
                          provider.updateSelectionPreview(
                              slotProvider.selectedBadges,
                              imgProvider.savedBadgeCache,
                              aniProvider);
                        }
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
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (file.jsonToData(badgeData.value).messages[0].flash)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Image.asset(
                          "assets/icons/flash.png",
                          color: Colors.white,
                          height: 14.h,
                        ),
                      ),
                    if (file.jsonToData(badgeData.value).messages[0].marquee)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Image.asset(
                          "assets/icons/square.png",
                          color: Colors.white,
                          height: 14.h,
                        ),
                      ),
                    if (badgeData.value['messages'][0]['invert'] ?? false)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Image.asset(
                          "assets/icons/t_invert.png",
                          color: Colors.white,
                          height: 14.h,
                        ),
                      ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/icons/t_double.png",
                            color: Colors.white,
                            height: 14.h,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Speed.getIntValue(
                              file
                                  .jsonToData(badgeData.value)
                                  .messages[0]
                                  .speed,
                            ).toString(),
                            style: const TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                    Container(
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
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Consumer<BadgeSlotProvider>(
                builder: (context, selectionProvider, _) {
                  final isSelected =
                      selectionProvider.isSelected(badgeData.key);
                  return Switch(
                    value: isSelected,
                    onChanged: (selectionProvider.canSelectMore || isSelected)
                        ? (value) {
                            selectionProvider.toggleSelection(badgeData.key);
                            final cache = Provider.of<InlineImageProvider>(
                                    context,
                                    listen: false)
                                .savedBadgeCache;
                            final aniProvider =
                                Provider.of<AnimationBadgeProvider>(context,
                                    listen: false);
                            Provider.of<SavedBadgeProvider>(context,
                                    listen: false)
                                .updateSelectionPreview(
                                    selectionProvider.selectedBadges,
                                    cache,
                                    aniProvider);
                          }
                        : null,
                    activeThumbColor: colorPrimary,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
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
