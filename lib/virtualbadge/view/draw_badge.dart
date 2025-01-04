import 'package:badgemagic/bademagic_module/utils/badge_utils.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/badge_paint.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BMBadge extends StatefulWidget {
  final void Function(DrawBadgeProvider provider)? providerInit;
  final List<List<bool>>? badgeGrid;
  const BMBadge({super.key, this.providerInit, this.badgeGrid});

  @override
  State<BMBadge> createState() => _BMBadgeState();
}

class _BMBadgeState extends State<BMBadge> {
  BadgeUtils badgeUtils = BadgeUtils();
  var drawProvider = DrawBadgeProvider();

  @override
  void initState() {
    if (widget.providerInit != null) {
      widget.providerInit!(drawProvider);
    }
    if (widget.badgeGrid != null) {
      drawProvider.updateDrawViewGrid(widget.badgeGrid!);
    }
    super.initState();
  }

  static const int rows = 11;
  static const int cols = 44;

  void _handlePanUpdate(DragUpdateDetails details) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    MapEntry<double, double> badgeOffsetBackground =
        badgeUtils.getBadgeOffsetBackground(renderBox.size);
    double offsetHeightBadgeBackground = badgeOffsetBackground.key;
    double offsetWidthBadgeBackground = badgeOffsetBackground.value;

    MapEntry<double, double> badgeSize = badgeUtils.getBadgeSize(
        offsetHeightBadgeBackground,
        offsetWidthBadgeBackground,
        renderBox.size);
    double badgeHeight = badgeSize.key;
    double badgeWidth = badgeSize.value;

    var cellSize = badgeWidth / cols;

    MapEntry<double, double> cellStartCoordinate =
        badgeUtils.getCellStartCoordinate(offsetWidthBadgeBackground,
            offsetHeightBadgeBackground, badgeWidth, badgeHeight);
    double cellStartX = cellStartCoordinate.key;
    double cellStartY = cellStartCoordinate.value;

    double cellEnd = cellStartX + (cellSize * cols);
    double cellEndY = cellStartY + ((cellSize * 0.93) * rows);

    if (localPosition.dx > cellStartX &&
        localPosition.dx > cellStartY &&
        localPosition.dx < cellEnd &&
        localPosition.dy < cellEndY * 1.1) {
      int col = ((localPosition.dx - cellStartX) / (cellSize * 0.93))
          .floor()
          .clamp(0, 43);
      int row =
          ((localPosition.dy - cellStartY) / cellSize).floor().clamp(0, 10);
      drawProvider.setDrawViewGrid(row, col);
    }

    setState(() {
      // drawProvider.setDrawViewGrid(row, col);
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    Size size = Size(width, width / 3.2);
    return ChangeNotifierProvider(
      create: (context) => drawProvider,
      child: GestureDetector(
          onPanUpdate: _handlePanUpdate,
          child: AspectRatio(
            aspectRatio: 3.2,
            child: Consumer<DrawBadgeProvider>(
              builder: (context, value, child) => CustomPaint(
                  painter: BadgePaint(grid: value.getDrawViewGrid()),
                  size: size),
            ),
          )),
    );
  }
}

// class AnimationBadgeROW extends LeafRenderObjectWidget {
//   final DrawBadgeProvider provider;

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
//   DrawBadgeProvider provider;

//   BadgeRenderObject({required this.provider});

//   @override
//   void performLayout() {
//     var width = constraints.maxWidth;
//     var height = constraints.maxHeight;

//     // Maintain aspect ratio but ensure it fits within the available height
//     var desiredHeight = width / 3.2;
//     if (desiredHeight > height) {
//       desiredHeight = height;
//     }

//     size = constraints.constrain(Size(width, desiredHeight));
//   }

//   @override
//   void paint(PaintingContext context, Offset offset) {
//     final Canvas canvas = context.canvas;
//     BadgePaint(grid: provider.getDrawViewGrid()).paint(canvas, size);
//   }

//   @override
//   bool get alwaysNeedsCompositing => true;

//   void onProviderUpdate() {
//     markNeedsPaint();
//   }

//   @override
//   bool hitTest(BoxHitTestResult result, {required Offset position}) {
//     if (size.contains(position)) {
//       result.add(BoxHitTestEntry(this, position));
//       return true;
//     }
//     return false;
//   }
// }
