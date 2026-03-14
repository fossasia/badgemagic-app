import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/view/draw_badge_screen.dart';
import 'package:badgemagic/view/widgets/badge_delete_dialog.dart';
import 'package:badgemagic/view/widgets/clipart_led_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavedClipartListView extends StatelessWidget {
  final Map<String, List<List<int>>?> images;
  final FileHelper file = FileHelper();

  final void Function(String) refreshClipartCallback;

  SavedClipartListView({
    super.key,
    required this.images,
    required this.refreshClipartCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final grid = images.values.elementAt(index)!;
        final fileName = images.keys.elementAt(index);
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 150.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: ClipartLedPreview(grid: grid),
                ),
              ),
              Container(height: 1, color: Colors.grey.shade300),
              SizedBox(
                height: 50.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DrawBadge(
                                  filename: fileName,
                                  isSavedClipart: true,
                                  badgeGrid: grid,
                                )));
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => file.shareClipartData(fileName),
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        _showDeleteDialog(context).then((value) async {
                          if (value) {
                            await file.deleteFile(fileName);
                            refreshClipartCallback(fileName);
                          }
                        });
                      },
                      tooltip: 'Delete',
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
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const DeleteBadgeDialog();
      },
    );
  }
}
