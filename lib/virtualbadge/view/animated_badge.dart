import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/brightness_provider.dart';
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
    final animationProvider = context.watch<AnimationBadgeProvider>();
    final brightnessProvider = context.watch<BrightnessProvider>();
    
    // Map brightness percentage to a UI-friendly opacity range
    // Physical badge: 25%->0x30, 50%->0x20, 75%->0x10, 100%->0x00
    // UI simulation: 25%->0.6, 50%->0.75, 75%->0.85, 100%->1.0
    // This makes lower brightness levels more visible in the UI while still showing clear differences
    final percentage = brightnessProvider.getBrightnessPercentage();
    final brightnessOpacity = 0.5 + (percentage / 100.0 * 0.5); // Maps 25%->0.625, 100%->1.0
    
    return AspectRatio(
      aspectRatio: 3.2,
      child: CustomPaint(
        painter: BadgePaint(
          grid: animationProvider.getPaintGrid(),
          brightness: brightnessOpacity,
        ),
      ),
    );
  }
}

// class AnimationBadgeROW extends LeafRenderObjectWidget {
//   final AnimationBadgeProvider provider;

//   const AnimationBadgeROW({super.key, required this.provider});

//   @override
//   RenderObject createRenderObject(BuildContext context) {
//     final renderObject = BadgeRenderObject(provider: provider);
//     provider.addListener(renderObject.onProviderUpdate);
//     return renderObject;
//   }

//   @override
//   void updateRenderObject(
//       BuildContext context, covariant BadgeRenderObject renderObject) {
//     renderObject.provider = provider;
//   }
// }

// class BadgeRenderObject extends RenderBox with RenderObjectWithChildMixin {
//   AnimationBadgeProvider provider;

//   BadgeRenderObject({required this.provider});

//   @override
//   void performLayout() {
//     var width = constraints.maxWidth;
//     size = constraints.constrain(Size(width, width / 3.2));
//   }

//   @override
//   void paint(PaintingContext context, Offset offset) {
//     final Canvas canvas = context.canvas;
//     BadgePaint(grid: provider.getPaintGrid()).paint(canvas, size);
//   }

//   @override
//   bool get alwaysNeedsCompositing => true;

//   void onProviderUpdate() {
//     markNeedsPaint();
//   }
// }
