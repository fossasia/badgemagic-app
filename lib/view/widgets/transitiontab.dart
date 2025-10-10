import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/view/widgets/animation_container.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              AniContainer(
                animation: aniLeft,
                animationName: l10n.animationLeft,
                index: 0,
              ),
              AniContainer(
                animation: aniRight,
                animationName: l10n.animationRight,
                index: 1,
              ),
              AniContainer(
                animation: aniUp,
                animationName: l10n.animationUp,
                index: 2,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniDown,
                animationName: l10n.animationDown,
                index: 3,
              ),
              AniContainer(
                animation: aniFixed,
                animationName: l10n.animationFixed,
                index: 4,
              ),
              AniContainer(
                animation: animation,
                animationName: l10n.animation,
                index: 5,
              ),
            ],
          ),
          Row(
            children: [
              AniContainer(
                animation: aniSnowflake,
                animationName: l10n.animationSnowflake,
                index: 6,
              ),
              AniContainer(
                animation: aniPicture,
                animationName: l10n.animationPicture,
                index: 7,
              ),
              AniContainer(
                animation: aniLaser,
                animationName: l10n.animationLaser,
                index: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
