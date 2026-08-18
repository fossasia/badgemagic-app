import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/vector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BadgeClipartPicker extends StatelessWidget {
  final bool visible;
  final ScrollController controller;

  const BadgeClipartPicker({
    super.key,
    required this.visible,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Visibility(
        visible: visible,
        child: Container(
          height: visible ? 200.h : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: colorSurfaceMuted,
          ),
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8),
          child: Scrollbar(
            controller: controller,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 4.0,
            radius: const Radius.circular(10),
            child: VectorGridView(controller: controller),
          ),
        ),
      ),
    );
  }
}
