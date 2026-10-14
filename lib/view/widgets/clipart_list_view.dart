import 'dart:typed_data';

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/theme/app_radius.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class SavedClipartListView extends StatelessWidget {
  final Map<String, List<List<int>>?> images;
  final FileHelper file = FileHelper();
  final ImageUtils imageUtils = ImageUtils();

  final Future<void> Function(String) refreshClipartCallback;
  final Future<void> Function(String fileName) onClipartSelected;

  SavedClipartListView({
    super.key,
    required this.images,
    required this.refreshClipartCallback,
    required this.onClipartSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageData = images.values.elementAt(index);
        final String fileName = images.keys.elementAt(index);

        if (imageData == null) {
          return const SizedBox.shrink();
        }

        final Future<Uint8List?> image =
            imageUtils.convert2DListToUint8List(imageData);

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          constraints: BoxConstraints(minHeight: 90.h),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(AppRadius.medium.dg),
            boxShadow: [
              BoxShadow(
                color: colorShadow.withValues(alpha: 0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: FutureBuilder<Uint8List?>(
                  future: image,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Image.memory(
                          snapshot.data!,
                          scale: 0.5,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Flexible(
                flex: 3,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4.w,
                  runSpacing: 4.h,
                  children: [
                    TextButton.icon(
                      onPressed: () async => onClipartSelected(fileName),
                      style: TextButton.styleFrom(
                        foregroundColor: colorPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 6.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.add_circle_outline, size: 18.sp),
                      label: Text(
                        l10n.addToBadge,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colorSurfaceSubtle,
                        foregroundColor: colorNeutralDark,
                        padding: EdgeInsets.all(8.dg),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DrawBadge(
                              filename: fileName,
                              isSavedClipart: true,
                              badgeGrid: imageData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.export,
                      icon: const Icon(Icons.share, color: colorOnSurface),
                      onPressed: () async {
                        await FileHelper().exportClipart(fileName);
                      },
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colorError,
                        foregroundColor: colorOnPrimary,
                        padding: EdgeInsets.all(8.dg),
                      ),
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final value = await _showDeleteDialog(context);
                        if (value) {
                          await file.deleteFile(fileName);
                          await refreshClipartCallback(fileName);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return const DeleteBadgeDialog();
          },
        ) ??
        false;
  }
}
