import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';

class DeleteBadgeDialog extends StatelessWidget {
  const DeleteBadgeDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.delete, color: Colors.black),
                  SizedBox(width: 10.w),
                  Text(l10n.delete,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
              SizedBox(height: 16.h),
              Text(l10n.deleteBadgeConfirmation,
                  style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(l10n.cancel,
                          style: const TextStyle(color: Colors.red))),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(l10n.ok,
                          style: const TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
