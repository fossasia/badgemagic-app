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
                  icon: Icons.sports_esports, // Pacman icon
                  animationName: 'Pacman',
                  index: 9,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.chevron_left, // Chevron icon
                  animationName: 'Chevron',
                  index: 10,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.diamond, // Diamond icon
                  animationName: 'Diamond',
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
                  icon: Icons.heart_broken, // Broken Hearts icon
                  animationName: 'Broken Hearts',
                  index: 12,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.favorite_border, // Cupid icon
                  animationName: 'Cupid',
                  index: 13,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.directions_walk, // Feet animation icon
                  animationName: 'Feet',
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
                  icon: Icons.set_meal, // Fish icon
                  animationName: 'Fish Kiss',
                  index: 15,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.change_history, // V shape icon
                  animationName: 'Diagonal',
                  index: 16,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.warning, // Emergency/alert icon
                  animationName: 'Emergency',
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
                  icon: Icons.favorite, // Heart icon
                  animationName: 'Beating Hearts',
                  index: 18,
                ),
                AniContainer(
                  animation: null,
                  icon: Icons.celebration, // Fireworks icon
                  animationName: 'Fireworks',
                  index: 19,
                ),
                AniContainer(
                  animationName: 'Equalizer',
                  index: 20, // This MUST match the index in your animationMap
                  icon: Icons.equalizer,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
