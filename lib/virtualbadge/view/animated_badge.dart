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
        painter: BadgePaint(grid: provider.getPaintGrid()),
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
