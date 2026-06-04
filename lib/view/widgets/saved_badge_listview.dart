import 'dart:convert';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/saved_badge_provider.dart';
import 'package:badgemagic/providers/badge_message_provider.dart';
import 'package:badgemagic/view/homescreen.dart';
import 'package:badgemagic/view/widgets/save_badge_card.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../providers/badge_slot_provider..dart';

class BadgeListView extends StatelessWidget {
  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback;

  const BadgeListView({
    super.key,
    required this.refreshBadgesCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeSlotProvider>(
      builder: (context, slotProvider, _) {
        final savedBadges = slotProvider.orderedBadges;

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: EdgeInsets.only(bottom: 80.h, top: 10.h),
          itemCount: savedBadges.length,
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: 1.0 + (0.03 * animation.value),
                  child: child,
                );
              },
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) {
            slotProvider.reorderBadges(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final badge = savedBadges[index];

            return Container(
              key: ValueKey(badge.key),
              child: SaveBadgeCard(
                badgeData: badge,
                index: index,
                onQuickTransfer: (data) {
                  List<Map<String, dynamic>> messagesList = [];
                  final rawMessage =
                      Map<String, dynamic>.from(data['messages'][0]);
                  messagesList.add(rawMessage);

                  Map<String, dynamic> blankTemplate = Map.from(rawMessage);
                  blankTemplate['text'] = <String>[];

                  while (messagesList.length < 8) {
                    messagesList.add(Map.from(blankTemplate));
                  }

                  final safeTransferData = {'messages': messagesList};

                  debugPrint("====== ⚡ QUICK TRANSFER ⚡ ======");
                  debugPrint(jsonEncode(safeTransferData));

                  BadgeMessageProvider().checkAndTransfer(null, null, null,
                      null, null, null, safeTransferData, true, context);
                },
                onDelete: (key) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeleteBadgeDialog(),
                  );
                  if (!context.mounted) return;
                  if (confirm == true) {
                    FileHelper().deleteFile(key);
                    slotProvider.removeBadge(key);
                    ToastUtils().showToast("Badge Deleted Successfully");
                    refreshBadgesCallback(badge);
                  }
                },
                onShare: (key) {
                  FileHelper().shareBadgeData(key);
                },
                onEdit: (key) async {
                  final provider =
                      Provider.of<SavedBadgeProvider>(context, listen: false);
                  final confirmed =
                      await provider.showEditBadgeConfirmation(context);
                  if (!context.mounted) return;
                  if (confirmed) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            HomeScreen(savedBadgeFilename: key),
                      ),
                    );
                  }
                },
                onPlay: (data) {
                  Provider.of<SavedBadgeProvider>(context, listen: false)
                      .savedBadgeAnimation(
                    data,
                    Provider.of<AnimationBadgeProvider>(context, listen: false),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
