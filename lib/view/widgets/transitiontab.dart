import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
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
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
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
                  animationName: l10n.pacman,
                  index: 9,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.chevron_left,
                  animationName: l10n.chevron,
                  index: 10,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.diamond,
                  animationName: l10n.diamond,
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
                  animationName: l10n.brokenHearts,
                  index: 12,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.favorite_border,
                  animationName: l10n.cupid,
                  index: 13,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.directions_walk,
                  animationName: l10n.feet,
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
                  animationName: l10n.fishKiss,
                  index: 15,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.change_history,
                  animationName: l10n.diagonal,
                  index: 16,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.warning,
                  animationName: l10n.emergency,
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
                  animationName: l10n.beatingHearts,
                  index: 18,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.celebration,
                  animationName: l10n.fireworks,
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
