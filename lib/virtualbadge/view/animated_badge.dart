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
    // UI simulation (clamped 0–100%): 0%->0.5, 25%->0.6, 50%->0.75, 75%->0.85, 100%->1.0
    // This makes lower brightness levels more visible in the UI while still showing clear differences
    final percentage = brightnessProvider.getBrightnessPercentage();
    final brightnessOpacity = _mapBrightnessToOpacity(percentage.toDouble());
    
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

  double _mapBrightnessToOpacity(double percentage) {
    // Clamp to [0, 100] to avoid weird values from the provider
    final clamped = percentage.clamp(0.0, 100.0);

    if (clamped <= 25.0) {
      // 0% -> 0.5, 25% -> 0.6
      return 0.5 + (clamped / 25.0) * (0.6 - 0.5);
    } else if (clamped <= 50.0) {
      // 25% -> 0.6, 50% -> 0.75
      return 0.6 + ((clamped - 25.0) / 25.0) * (0.75 - 0.6);
    } else if (clamped <= 75.0) {
      // 50% -> 0.75, 75% -> 0.85
      return 0.75 + ((clamped - 50.0) / 25.0) * (0.85 - 0.75);
    } else {
      // 75% -> 0.85, 100% -> 1.0
      return 0.85 + ((clamped - 75.0) / 25.0) * (1.0 - 0.85);
    }
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
