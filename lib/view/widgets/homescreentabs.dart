import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:badgemagic/view/widgets/effects_container.dart';
import 'package:flutter/material.dart';

//effects tab to show effects that the user can select
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

// Animation tab to show special animations
class AnimationTab extends StatefulWidget {
  const AnimationTab({super.key});

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.sports_esports, // Pacman icon
                  animationName: l10n.pacman,
                  index: 9,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.chevron_left, // Chevron icon
                  animationName: l10n.chevron,
                  index: 10,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.diamond, // Diamond icon
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
                  icon: Icons.heart_broken, // Broken Hearts icon
                  animationName: l10n.brokenHearts,
                  index: 12,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.favorite_border, // Cupid icon
                  animationName: l10n.cupid,
                  index: 13,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.directions_walk, // Feet animation icon
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
                  icon: Icons.set_meal, // Fish icon
                  animationName: l10n.fishKiss,
                  index: 15,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.change_history, // V shape icon
                  animationName: l10n.diagonal,
                  index: 16,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.warning, // Emergency/alert icon
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
                  icon: Icons.favorite, // Heart icon
                  animationName: l10n.beatingHearts,
                  index: 18,
                ),
              ),
              Expanded(
                child: AniContainer(
                  animation: null,
                  icon: Icons.celebration, // Fireworks icon
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
