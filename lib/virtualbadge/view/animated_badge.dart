import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnimationBadge extends StatefulWidget {
  const AnimationBadge({super.key});

  @override
  State<AnimationBadge> createState() => _AnimationBadgeState();
}

class _AnimationBadgeState extends State<AnimationBadge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimationBadgeProvider>().initializeAnimation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimationBadgeProvider>();
    return AspectRatio(
      aspectRatio: 3.2,
      child: CustomPaint(
        painter: BadgePaint(
          grid: provider.getPaintGrid(),
          textStyle:
              provider.textStyle, // Updated to pass the selected font style
          text: provider.currentMessage, // Pass the current message to display
        ),
      ),
    );
  }
}
