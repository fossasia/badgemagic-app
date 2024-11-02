import 'package:badgemagic/bademagic_module/utils/global_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ToastUtils {
  final context = GlobalContextProvider.instance.context!;
  // Create a toast message
  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10),
        elevation: 10,
        duration: const Duration(seconds: 1),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage('assets/icons/icon.png'),
              height: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              ),
            )
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dismissDirection: DismissDirection.startToEnd,
      ),
    );
  }

  // Create a error toast
  void showErrorToast(String message) {
    showToast('Error: $message');
  }
}
