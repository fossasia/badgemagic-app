import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';

class TransitionTab extends StatefulWidget {
  const TransitionTab({super.key});

  @override
  State<TransitionTab> createState() => _TransitionTabState();
}

class _TransitionTabState extends State<TransitionTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = 8.0; // padding to match spacing with tiles

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6.0,
      radius: const Radius.circular(6),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            _buildTileRow([
              AniContainer(
                  animation: null,
                  icon: Icons.sports_esports,
                  animationName: 'Pacman',
                  index: 9),
              AniContainer(
                  animation: null,
                  icon: Icons.chevron_left,
                  animationName: 'Chevron',
                  index: 10),
              AniContainer(
                  animation: null,
                  icon: Icons.diamond,
                  animationName: 'Diamond',
                  index: 11),
            ]),
            _buildTileRow([
              AniContainer(
                  animation: null,
                  icon: Icons.heart_broken,
                  animationName: 'Broken Hearts',
                  index: 12),
              AniContainer(
                  animation: null,
                  icon: Icons.favorite_border,
                  animationName: 'Cupid',
                  index: 13),
              AniContainer(
                  animation: null,
                  icon: Icons.directions_walk,
                  animationName: 'Feet',
                  index: 14),
            ]),
            _buildTileRow([
              AniContainer(
                  animation: null,
                  icon: Icons.set_meal,
                  animationName: 'Fish Kiss',
                  index: 15),
              AniContainer(
                  animation: null,
                  icon: Icons.change_history,
                  animationName: 'Diagonal',
                  index: 16),
              AniContainer(
                  animation: null,
                  icon: Icons.warning,
                  animationName: 'Emergency',
                  index: 17),
            ]),
            _buildTileRow([
              AniContainer(
                  animation: null,
                  icon: Icons.favorite,
                  animationName: 'Beating Hearts',
                  index: 18),
              AniContainer(
                  animation: null,
                  icon: Icons.celebration,
                  animationName: 'Fireworks',
                  index: 19),
              AniContainer(
                  animation: null,
                  icon: Icons.equalizer,
                  animationName: 'Equalizer',
                  index: 20),
            ]),
            _buildTileRow([
              AniContainer(
                animation: null,
                icon: Icons.directions_bike,
                animationName: 'Cycle',
                index: 21,
              )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTileRow(List<AniContainer> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: tiles.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceEvenly,
        children: tiles.map((tile) {
          return tiles.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: tile,
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: tile,
                  ),
                );
        }).toList(),
      ),
    );
  }
}
