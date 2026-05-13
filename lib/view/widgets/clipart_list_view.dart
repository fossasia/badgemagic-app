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

  final Future<void> Function(String) refreshClipartCallback;

  SavedClipartListView({
    super.key,
    required this.images,
    required this.refreshClipartCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
          margin: EdgeInsets.all(10.dg),
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.r),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(10.dg),
                child: FutureBuilder<Uint8List?>(
                  future: image,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const SizedBox.shrink();
                    }

                    return Image.memory(
                      snapshot.data!,
                      scale: 0.5,
                    );
                  },
                ),
              ),
              Container(
                width: 1.w,
                height: 80.h,
                color: Colors.black,
              ),
              const Spacer(),
              IconButton(
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
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
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
