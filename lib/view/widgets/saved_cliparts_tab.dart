import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/view/widgets/clipart_led_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

/// Tab on Create Badge screen that lists saved cliparts; tap to apply as badge (overwrite).
class SavedClipartsTab extends StatelessWidget {
  const SavedClipartsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final imageProvider = GetIt.instance<InlineImageProvider>();

    if (imageProvider.clipartsCache.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            l10n.noSavedClipartMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return Consumer<InlineImageProvider>(
      builder: (context, provider, _) {
        final entries = provider.clipartsCache.entries.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                l10n.savedCliparts,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final e = entries[index];
                  final grid = e.value!;
                  return _ClipartChip(
                    grid: grid,
                    onTap: () {
                      final aniProvider = Provider.of<AnimationBadgeProvider>(
                          context,
                          listen: false);
                      aniProvider.setClipartAsBadge(grid);
                      provider.getController().clear();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClipartChip extends StatelessWidget {
  final List<List<int>> grid;
  final VoidCallback onTap;

  const _ClipartChip({required this.grid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: colorPrimary.withValues(alpha: 0.5)),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.r),
            child: ClipartLedPreview(grid: grid),
          ),
        ),
      ),
    );
  }
}
