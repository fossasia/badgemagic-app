import 'dart:math' as math;

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class BadgeActionButtons extends StatelessWidget {
  final Future<void> Function() onSave;
  final Future<void> Function() onTransfer;

  const BadgeActionButtons({
    super.key,
    required this.onSave,
    required this.onTransfer,
  });

  Widget _actionButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    final double height = math.min(50.h, 54.0);
    return SizedBox(
      height: height,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: colorSurfaceMuted,
          foregroundColor: colorTextStrong,
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Consumer<AnimationBadgeProvider>(
      builder: (context, animationProvider, _) {
        final isSpecial = animationProvider.isSpecialAnimationSelected();
        return Row(
          children: [
            if (!isSpecial) ...[
              Expanded(
                child: _actionButton(
                  label: l10n.saveButton,
                  onTap: onSave,
                ),
              ),
              SizedBox(width: 24.w),
            ],
            Expanded(
              child: _actionButton(
                label: l10n.transferButton,
                onTap: onTransfer,
              ),
            ),
          ],
        );
      },
    );
  }
}
