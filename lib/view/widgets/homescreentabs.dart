import 'package:badgemagic/constants.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EffectContainer(
          effect: effInvert,
          effectName: AppLocalizations.of(context)!.invertEffect,
          index: 0,
        ),
        EffectContainer(
          effect: effFlash,
          effectName: AppLocalizations.of(context)!.flashEffect,
          index: 1,
        ),
        EffectContainer(
          effect: effMarque,
          effectName: AppLocalizations.of(context)!.marqueeEffect,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              AniContainer(
                animation: aniLeft,
                animationName: AppLocalizations.of(context)!.animationLeft,
                index: 0,
              ),
              AniContainer(
                animation: aniRight,
                animationName: AppLocalizations.of(context)!.animationRight,
                index: 1,
              ),
              AniContainer(
                animation: aniUp,
                animationName: AppLocalizations.of(context)!.animationUp,
                index: 2,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniDown,
                animationName: AppLocalizations.of(context)!.animationDown,
                index: 3,
              ),
              Semantics(
                label: 'Fixed',
                child: AniContainer(
                  animation: aniFixed,
                  animationName: AppLocalizations.of(context)!.animationFixed,
                  index: 4,
                ),
              ),
              AniContainer(
                animation: aniFixed,
                animationName: AppLocalizations.of(context)!.animationSnowflake,
                index: 5,
              ),
            ],
          ),
          Row(
            children: [
              Semantics(
                label: 'Picture',
                child: AniContainer(
                  animation: aniPicture,
                  animationName: AppLocalizations.of(context)!.picture,
                  index: 6,
                ),
              ),
              Semantics(
                label: 'Animation',
                child: AniContainer(
                  animation: animation,
                  animationName: AppLocalizations.of(context)!.animation,
                  index: 7,
                ),
              ),
              Semantics(
                label: 'Laser',
                child: AniContainer(
                  animation: aniLaser,
                  animationName: AppLocalizations.of(context)!.laser,
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
