import 'package:badgemagic/bademagic_module/models/messages.dart';
import 'package:badgemagic/bademagic_module/models/speed.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SaveBadgeCard extends StatelessWidget {
  final MapEntry<String, Map<String, dynamic>> badgeData;
  final int index;
  final Function(String) onDelete;
  final Function(String) onShare;
  final Function(String) onEdit;
  final Function(Map<String, dynamic>) onPlay;
  final Function(Map<String, dynamic>) onQuickTransfer;

  SaveBadgeCard({
    super.key,
    required this.badgeData,
    required this.index,
    required this.onDelete,
    required this.onShare,
    required this.onEdit,
    required this.onPlay,
    required this.onQuickTransfer,
  });

  final FileHelper file = FileHelper();

  @override
  Widget build(BuildContext context) {
    final parsedData = file.jsonToData(badgeData.value);
    final Message messageData = parsedData.messages[0];

    final String rawName = badgeData.key.substring(0, badgeData.key.length - 5);
    final String badgeName =
        rawName.length > 12 ? '${rawName.substring(0, 15)}...' : rawName;

    final bool isTransferred = index < 8;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin:
              EdgeInsets.only(top: 14.h, bottom: 8.h, left: 10.w, right: 10.w),
          padding:
              EdgeInsets.only(top: 18.h, bottom: 12.h, left: 12.w, right: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              width: 1.5,
              color: isTransferred ? colorPrimary : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      badgeName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color:
                            isTransferred ? Colors.black : Colors.grey.shade700,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility,
                            color: colorPrimary, size: 24.sp),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        tooltip: 'Preview',
                        onPressed: () => onPlay(badgeData.value),
                      ),
                      SizedBox(width: 2.w),
                      _buildPopupMenu(),
                      SizedBox(width: 2.w),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.only(
                              left: 6.w, right: 4.w, top: 4.h, bottom: 4.h),
                          child: Icon(Icons.drag_indicator,
                              color: Colors.grey.shade400, size: 28.sp),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSpeedAndMode(messageData, isTransferred),
                  _buildStatusChips(messageData, isTransferred),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 4.h,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isTransferred ? colorPrimary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                isTransferred ? 'Slot ${index + 1}' : 'Unassigned',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black87),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (String result) {
        switch (result) {
          case 'transfer':
            onQuickTransfer(badgeData.value);
            break;
          case 'edit':
            onEdit(badgeData.key);
            break;
          case 'share':
            onShare(badgeData.key);
            break;
          case 'delete':
            onDelete(badgeData.key);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'transfer', child: Text('Transfer')),
        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        const PopupMenuItem<String>(value: 'share', child: Text('Share')),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildStatusChips(Message msg, bool active) {
    Color iconColor = active ? colorPrimary : Colors.grey.shade500;
    return Row(
      children: [
        if (msg.flash) _miniIcon("assets/icons/flash.png", iconColor),
        if (msg.marquee) _miniIcon("assets/icons/square.png", iconColor),
        if (badgeData.value['messages'][0]['invert'] ?? false)
          _miniIcon("assets/icons/t_invert.png", iconColor),
      ],
    );
  }

  Widget _miniIcon(String asset, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: Image.asset(asset, color: color, height: 16.h),
    );
  }

  Widget _buildSpeedAndMode(Message msg, bool active) {
    Color bgColor = active ? colorPrimary : Colors.grey.shade400;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: Text(
            'Speed: ${Speed.getIntValue(msg.speed)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: Text(
            msg.mode.toString().split('.').last.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
