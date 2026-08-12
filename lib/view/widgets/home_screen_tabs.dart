import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:badgemagic/view/widgets/effects_container.dart';
import 'package:flutter/material.dart';

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

class AnimationTab extends StatefulWidget {
  const AnimationTab({super.key});

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;
    return SingleChildScrollView(
      padding: isDesktop ? const EdgeInsets.only(right: 10) : EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.sports_esports,
                  animationName: l10n.pacman,
                  index: 9,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.chevron_left,
                  animationName: l10n.chevron,
                  index: 10,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.diamond,
                  animationName: l10n.diamond,
                  index: 11,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.heart_broken,
                  animationName: l10n.brokenHearts,
                  index: 12,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.favorite_border,
                  animationName: l10n.cupid,
                  index: 13,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.directions_walk,
                  animationName: l10n.feet,
                  index: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.set_meal,
                  animationName: l10n.fishKiss,
                  index: 15,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.change_history,
                  animationName: l10n.diagonal,
                  index: 16,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.warning,
                  animationName: l10n.emergency,
                  index: 17,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.favorite,
                  animationName: l10n.beatingHearts,
                  index: 18,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.celebration,
                  animationName: l10n.fireworks,
                  index: 19,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animationName: l10n.equalizer,
                  index: 20, // This MUST match the index in your animationMap
                  icon: Icons.equalizer,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
