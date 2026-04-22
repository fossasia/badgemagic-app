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

  final void Function(String) refreshClipartCallback; // Pass the filename

  SavedClipartListView({
    super.key,
    required this.images,
    required this.refreshClipartCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: images.length, // Number of images
      itemBuilder: (context, index) {
        Future<Uint8List?> image = imageUtils.convert2DListToUint8List(
            images.values.elementAt(index)!); // Get the image
        String fileName = images.keys.elementAt(index); // Get the filename
        return Container(
          margin: EdgeInsets.all(10.dg),
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.w),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(10.dg),
                child: FutureBuilder<Uint8List?>(
                  future: image,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return Image.memory(
                        snapshot.data!,
                        scale: 0.5,
                      );
                    }
                  },
                ),
              ),
              SizedBox(
                width: 130.w,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () { 
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => DrawBadge(
                              filename: fileName,
                              isSavedClipart: true,
                              badgeGrid: images.values.elementAt(index),
                            )));
                  },
                  icon: const Icon(Icons.edit),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    _showDeleteDialog(context).then((value) async {
                    if (value) {
                      await file.deleteFile(fileName); // Pass the filename
                      refreshClipartCallback(
                          fileName); // Pass filename to callback
                    }
                  });
                  },
                ),
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
