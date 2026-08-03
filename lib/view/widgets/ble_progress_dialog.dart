import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bademagic_module/bluetooth/connect_state.dart';
import '../../constants.dart';

enum BleDialogStatus { searching, connecting, transferring, success, error }

class BleProgressDialog extends StatelessWidget {
  final BleDialogStatus status;
  final double progress;
  final String message;

  const BleProgressDialog({
    super.key,
    required this.status,
    required this.progress,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFinished =
        status == BleDialogStatus.success || status == BleDialogStatus.error;

    return PopScope(
        canPop: false,
        child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            contentPadding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            actionsPadding: EdgeInsets.only(bottom: 8.h),
            content: SizedBox(
              width: 150.w,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 12.h),
                  _buildIconOrAnimation(),
                  SizedBox(height: 16.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (status == BleDialogStatus.transferring) ...[
                    SizedBox(height: 12.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: indicatorColor,
                        minHeight: 6.h,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (isFinished)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    textStyle:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              if (!isFinished)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    textStyle:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    ConnectState.stopAllBleOperations();
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
            ]));
  }

  Widget _buildIconOrAnimation() {
    switch (status) {
      case BleDialogStatus.searching:
        return const _TweakedPulseAnimation(
          child: Icon(Icons.bluetooth_searching, size: 44, color: colorPrimary),
        );
      case BleDialogStatus.connecting:
        return const Icon(Icons.bluetooth_connected,
            size: 44, color: colorPrimary);
      case BleDialogStatus.transferring:
        return const Icon(Icons.swap_vertical_circle_outlined,
            size: 44, color: colorPrimary);
      case BleDialogStatus.success:
        return const Icon(Icons.check_circle_outline,
            size: 44, color: colorPrimary);
      case BleDialogStatus.error:
        return const Icon(Icons.error_outline_rounded,
            size: 44, color: Colors.red);
    }
  }
}

class _TweakedPulseAnimation extends StatefulWidget {
  final Widget child;
  const _TweakedPulseAnimation({required this.child});

  @override
  State<_TweakedPulseAnimation> createState() => _TweakedPulseAnimationState();
}

class _TweakedPulseAnimationState extends State<_TweakedPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
