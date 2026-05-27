import 'dart:typed_data';

import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/image_utils.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavedClipartListView extends StatelessWidget {
  final Map<String, List<List<int>>?> images;
  final FileHelper file = FileHelper();
  final ImageUtils imageUtils = ImageUtils();

  final void Function(String) refreshClipartCallback;

  SavedClipartListView({
    super.key,
    required this.images,
    required this.refreshClipartCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
      itemCount: images.length,
      itemBuilder: (context, index) {
        Future<Uint8List?> image = imageUtils
            .convert2DListToUint8List(images.values.elementAt(index)!);
        String fileName = images.keys.elementAt(index);

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          height: 90.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.dg),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
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
              const Spacer(),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                  padding: EdgeInsets.all(8.dg),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => DrawBadge(
                            filename: fileName,
                            isSavedClipart: true,
                            badgeGrid: images.values.elementAt(index),
                          )));
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              SizedBox(width: 10.w),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(8.dg),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () {
                  _showDeleteDialog(context).then((value) async {
                    if (value) {
                      await file.deleteFile(fileName);
                      refreshClipartCallback(fileName);
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const DeleteBadgeDialog();
      },
    );
  }
}
