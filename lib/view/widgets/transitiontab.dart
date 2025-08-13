import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';

// Transition tab to show special animations
class TransitionTab extends StatefulWidget {
  const TransitionTab({super.key});

  @override
  State<TransitionTab> createState() => _TransitionTabState();
}

class _TransitionTabState extends State<TransitionTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.sports_esports,
                  animationName: AppLocalizations.of(context)!.pacman,
                  index: 9,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.chevron_left,
                  animationName: AppLocalizations.of(context)!.chevron,
                  index: 10,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.diamond,
                  animationName: AppLocalizations.of(context)!.diamond,
                  index: 11,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.heart_broken,
                  animationName: AppLocalizations.of(context)!.brokenHearts,
                  index: 12,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.favorite_border,
                  animationName: AppLocalizations.of(context)!.cupid,
                  index: 13,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.directions_walk,
                  animationName: AppLocalizations.of(context)!.feet,
                  index: 14,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.set_meal,
                  animationName: AppLocalizations.of(context)!.fishKiss,
                  index: 15,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.change_history,
                  animationName: AppLocalizations.of(context)!.diagonal,
                  index: 16,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.warning,
                  animationName: AppLocalizations.of(context)!.emergency,
                  index: 17,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                AniContainer(
                  animation: null,
                  icon: Icons.favorite,
                  animationName: AppLocalizations.of(context)!.beatingHearts,
                  index: 18,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.celebration,
                  animationName: AppLocalizations.of(context)!.fireworks,
                  index: 19,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
