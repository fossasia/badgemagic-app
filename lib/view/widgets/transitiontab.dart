import 'package:badgemagic/constants.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';

// Transition tab to show basic animations
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              AniContainer(
                animation: aniLeft,
                animationName: 'Left',
                index: 0,
              ),
              AniContainer(
                animation: aniRight,
                animationName: 'Right',
                index: 1,
              ),
              AniContainer(
                animation: aniUp,
                animationName: 'Up',
                index: 2,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniDown,
                animationName: 'Down',
                index: 3,
              ),
              AniContainer(
                animation: aniFixed,
                animationName: 'Fixed',
                index: 4,
              ),
              AniContainer(
                animation: animation,
                animationName: 'Animation',
                index: 5,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniSnowflake,
                animationName: 'Snowflake',
                index: 6,
              ),
              AniContainer(
                animation: aniPicture,
                animationName: 'Picture',
                index: 7,
              ),
              AniContainer(
                animation: aniLaser,
                animationName: 'Laser',
                index: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
