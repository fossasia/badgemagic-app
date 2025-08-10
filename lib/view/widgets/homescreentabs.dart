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
    return Column(
      children: [
        Row(
          children: [
            AniContainer(
              animation: aniLeft,
              animationName: AppLocalizations.of(context)!.left,
              index: 0,
            ),
            AniContainer(
              animation: aniRight,
              animationName: AppLocalizations.of(context)!.right,
              index: 1,
            ),
            AniContainer(
              animation: aniUp,
              animationName: AppLocalizations.of(context)!.up,
              index: 2,
            ),
          ],
        ),
        Row(
          children: [
            AniContainer(
              animation: aniDown,
              animationName: AppLocalizations.of(context)!.down,
              index: 3,
            ),
            AniContainer(
              animation: aniFixed,
              animationName: AppLocalizations.of(context)!.fixed,
              index: 4,
            ),
            AniContainer(
              animation: animation,
              animationName: AppLocalizations.of(context)!.animation,
              index: 5,
            ),
          ],
        ),
        Row(
          children: [
            AniContainer(
              animation: aniSnowflake,
              animationName: AppLocalizations.of(context)!.snowflake,
              index: 6,
            ),
            AniContainer(
              animation: aniPicture,
              animationName: AppLocalizations.of(context)!.picture,
              index: 7,
            ),
            AniContainer(
              animation: aniLaser,
              animationName: AppLocalizations.of(context)!.laser,
              index: 8,
            ),
          ],
        ),
      ],
    );
  }
}
