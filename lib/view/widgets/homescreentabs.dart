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
        EffectContainer(
          effect: effInvert,
          effectName: l10n.invertEffect,
          index: 0,
        ),
        EffectContainer(
          effect: effFlash,
          effectName: l10n.flashEffect,
          index: 1,
        ),
        EffectContainer(
          effect: effMarque,
          effectName: l10n.marqueeEffect,
          index: 2,
        ),
      ],
    );
  }
}

//Animation tab to show animation choices for the user
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
              Semantics(
                label: 'Left',
                child: AniContainer(
                  animation: aniLeft,
                  animationName: l10n.animationLeft,
                  index: 0,
                ),
              ),
              Semantics(
                label: 'Right',
                child: AniContainer(
                  animation: aniRight,
                  animationName: l10n.animationRight,
                  index: 1,
                ),
              ),
              Semantics(
                label: 'Up',
                child: AniContainer(
                  animation: aniUp,
                  animationName: l10n.animationUp,
                  index: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Semantics(
                label: 'Down',
                child: AniContainer(
                  animation: aniDown,
                  animationName: l10n.animationDown,
                  index: 3,
                ),
              ),
              Semantics(
                label: 'Fixed',
                child: AniContainer(
                  animation: aniFixed,
                  animationName: l10n.animationFixed,
                  index: 4,
                ),
              ),
              Semantics(
                label: 'Snowflake',
                child: AniContainer(
                  animation: aniFixed,
                  animationName: l10n.animationSnowflake,
                  index: 5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Semantics(
                label: 'Picture',
                child: AniContainer(
                  animation: aniPicture,
                  animationName: l10n.picture,
                  index: 6,
                ),
              ),
              Semantics(
                label: 'Animation',
                child: AniContainer(
                  animation: animation,
                  animationName: l10n.animation,
                  index: 7,
                ),
              ),
              Semantics(
                label: 'Laser',
                child: AniContainer(
                  animation: aniLaser,
                  animationName: l10n.laser,
                  index: 8,
                ),
              ),
            ],
          ),
          // Special animations moved to Transition tab.
        ],
      ),
    );
  }
}
