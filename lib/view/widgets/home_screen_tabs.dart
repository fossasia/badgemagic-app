import 'dart:math';

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/view/widgets/gifview.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:badgemagic/view/widgets/effects_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EffectTab extends StatefulWidget {
  const EffectTab({
    super.key,
  });

  @override
  State<EffectTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EffectContainer(
            effect: effInvert,
            effectName: l10n.invertEffect,
            index: 0,
          ),
        ),
        Expanded(
          child: EffectContainer(
            effect: effFlash,
            effectName: l10n.flashEffect,
            index: 1,
          ),
        ),
        Expanded(
          child: EffectContainer(
            effect: effMarque,
            effectName: l10n.marqueeEffect,
            index: 2,
          ),
        ),
      ],
    );
  }
}

class GifAniContainer extends StatelessWidget {
  final String assetPath;
  final String label;
  final String? selectedGifPath;
  final VoidCallback onTap;

  const GifAniContainer({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.selectedGifPath,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationBadgeProvider>(
      builder: (context, animProv, _) {
        final isSelected = animProv.isGifActive && selectedGifPath == assetPath;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
          height: 65.h,
          child: GestureDetector(
            onTap: onTap,
            child: Card(
              surfaceTintColor: colorSurface,
              color: isSelected ? colorPrimaryDark : drawerHeaderTitle,
              elevation: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Icon(
                      gifPreviewIcons[assetPath] ?? Icons.gif,
                      size: 36,
                      color: isSelected
                          ? colorOnPrimary
                          : const Color.fromARGB(255, 117, 117, 117),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isSelected ? colorOnPrimary : colorOnSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimationGridContent extends StatelessWidget {
  final String? selectedGifPath;
  final ValueChanged<String>? onGifSelected;

  const AnimationGridContent({
    super.key,
    this.selectedGifPath,
    this.onGifSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    final items = <(String, Widget)>[
      for (final gif in presetGifs)
        (
          gif['label']!,
          GifAniContainer(
            key: ValueKey('gif_${gif['path']}'),
            assetPath: gif['path']!,
            label: gif['label']!,
            selectedGifPath: selectedGifPath,
            onTap: () => onGifSelected?.call(gif['path']!),
          ),
        ),
      (
        l10n.beatingHearts,
        AniContainer(
            key: const ValueKey('ani_18'),
            animation: null,
            icon: Icons.favorite,
            animationName: l10n.beatingHearts,
            index: 18)
      ),
      (
        l10n.brokenHearts,
        AniContainer(
            key: const ValueKey('ani_12'),
            animation: null,
            icon: Icons.heart_broken,
            animationName: l10n.brokenHearts,
            index: 12)
      ),
      (
        l10n.chevron,
        AniContainer(
            key: const ValueKey('ani_10'),
            animation: null,
            icon: Icons.chevron_left,
            animationName: l10n.chevron,
            index: 10)
      ),
      (
        l10n.cupid,
        AniContainer(
            key: const ValueKey('ani_13'),
            animation: null,
            icon: Icons.favorite_border,
            animationName: l10n.cupid,
            index: 13)
      ),
      (
        l10n.diagonal,
        AniContainer(
            key: const ValueKey('ani_16'),
            animation: null,
            icon: Icons.change_history,
            animationName: l10n.diagonal,
            index: 16)
      ),
      (
        l10n.diamond,
        AniContainer(
            key: const ValueKey('ani_11'),
            animation: null,
            icon: Icons.diamond,
            animationName: l10n.diamond,
            index: 11)
      ),
      (
        l10n.emergency,
        AniContainer(
            key: const ValueKey('ani_17'),
            animation: null,
            icon: Icons.warning,
            animationName: l10n.emergency,
            index: 17)
      ),
      (
        l10n.equalizer,
        AniContainer(
            key: const ValueKey('ani_20'),
            animation: null,
            icon: Icons.equalizer,
            animationName: l10n.equalizer,
            index: 20)
      ),
      (
        l10n.feet,
        AniContainer(
            key: const ValueKey('ani_14'),
            animation: null,
            icon: Icons.directions_walk,
            animationName: l10n.feet,
            index: 14)
      ),
      (
        l10n.fireworks,
        AniContainer(
            key: const ValueKey('ani_19'),
            animation: null,
            icon: Icons.celebration,
            animationName: l10n.fireworks,
            index: 19)
      ),
      (
        l10n.fishKiss,
        AniContainer(
            key: const ValueKey('ani_15'),
            animation: null,
            icon: Icons.set_meal,
            animationName: l10n.fishKiss,
            index: 15)
      ),
      (
        l10n.pacman,
        AniContainer(
            key: const ValueKey('ani_9'),
            animation: null,
            icon: Icons.sports_esports,
            animationName: l10n.pacman,
            index: 9)
      ),
    ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));

    return Column(
      children: [
        for (int r = 0; r < items.length; r += 3)
          Row(
            children: [
              for (int c = r; c < min(r + 3, items.length); c++)
                Expanded(child: items[c].$2),
            ],
          ),
      ],
    );
  }
}

class AnimationTab extends StatelessWidget {
  final String? selectedGifPath;
  final ValueChanged<String>? onGifSelected;

  const AnimationTab({super.key, this.selectedGifPath, this.onGifSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AnimationGridContent(
        selectedGifPath: selectedGifPath,
        onGifSelected: onGifSelected,
      ),
    );
  }
}
