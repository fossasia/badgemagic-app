import 'dart:math';

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InnerDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.7;

    final paint = Paint()
      ..color = backCircleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.055;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class RadialDialPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  RadialDialPainter({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.8;

    final paint = Paint()
      ..color = backCircleColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = size.shortestSide * 0.02;

    const startAngle = 3 * pi / 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6 * pi / 4,
      false,
      paint,
    );

    final progressPaint = Paint()
      ..color = colorPrimaryDark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = size.shortestSide * 0.045;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6 * pi / 4 * (value / max),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class InnerPointerPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  InnerPointerPainter({
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.5;

    final pointerAngle = 3 * pi / 4 + 6 * pi / 4 * (value / max);
    final pointerLength = radius + size.shortestSide * 0.107;

    final pointerPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = size.shortestSide * 0.028;

    final pointerStart = Offset(
      center.dx + radius * cos(pointerAngle),
      center.dy + radius * sin(pointerAngle),
    );
    final pointerEnd = Offset(
      center.dx + pointerLength * cos(pointerAngle),
      center.dy + pointerLength * sin(pointerAngle),
    );

    canvas.drawLine(pointerStart, pointerEnd, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RadialDial extends StatefulWidget {
  const RadialDial({super.key});

  @override
  State<RadialDial> createState() => _RadialDialState();
}

class _RadialDialState extends State<RadialDial> {
  final double maxValue = 8.0;
  final GlobalKey _dialKey = GlobalKey();
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    SpeedDialProvider outerValueProvider =
        Provider.of<SpeedDialProvider>(context);

    RenderBox? dialBox() =>
        _dialKey.currentContext?.findRenderObject() as RenderBox?;

    bool isTouchOnActiveArea(PointerDownEvent event) {
      final box = dialBox();
      if (box == null) return false;
      final localPosition = box.globalToLocal(event.position);
      final center = Offset(box.size.width / 2, box.size.height / 2);
      final distance = (localPosition - center).distance;

      final double dim = min(box.size.width, box.size.height);
      final double minActiveRadius = dim * 0.15;
      final double maxActiveRadius = dim * 0.6;

      return distance >= minActiveRadius && distance <= maxActiveRadius;
    }

    void updateOuterValue(double angle) {
      const startAngle = 3 * pi / 4;
      const endAngle = startAngle + 6 * pi / 4;
      const totalAngle = 6 * pi / 4;

      double normalizedAngle = angle;

      if (normalizedAngle < pi / 2) {
        normalizedAngle += 2 * pi;
      }

      if (normalizedAngle < startAngle || normalizedAngle > endAngle) {
        double distToStart = (normalizedAngle - startAngle).abs();
        double distToEnd = (normalizedAngle - endAngle).abs();
        if (distToStart < distToEnd) {
          normalizedAngle = startAngle;
        } else {
          normalizedAngle = endAngle;
        }
      }

      final numSections = maxValue;
      final anglePerSection = totalAngle / numSections;

      final section =
          ((normalizedAngle - startAngle) / anglePerSection).round();
      final clampedSection = section.clamp(1, numSections.toInt());

      if (clampedSection != outerValueProvider.getOuterValue()) {
        setState(() {
          outerValueProvider.setDialValue(clampedSection);
        });
      }
    }

    void updateAngle(Offset position, Size size) {
      final center = Offset(size.width / 2, size.height / 2);
      final dx = position.dx - center.dx;
      final dy = position.dy - center.dy;

      var angle = atan2(dy, dx);
      if (angle < 0) {
        angle += 2 * pi;
      }

      updateOuterValue(angle);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double dim = min(constraints.maxWidth, constraints.maxHeight);
        if (!dim.isFinite || dim <= 0) {
          dim = 220;
        }
        final double lowerBound =
            constraints.maxHeight.isFinite && constraints.maxHeight < 200
                ? constraints.maxHeight
                : 200.0;
        dim = dim.clamp(lowerBound, 560.0);
        if (MediaQuery.of(context).size.width < 600) {
          dim = dim * 0.82;
        }
        final double fontSize = dim * 0.25;

        return Center(
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              _SelectivePanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                      _SelectivePanGestureRecognizer>(
                () => _SelectivePanGestureRecognizer(
                  debugOwner: this,
                  shouldClaimGesture: isTouchOnActiveArea,
                ),
                (_SelectivePanGestureRecognizer instance) {
                  instance.onStart = (details) {
                    FocusScope.of(context).unfocus();
                    isDragging = true;
                    final box = dialBox();
                    if (box == null) return;
                    updateAngle(
                        box.globalToLocal(details.globalPosition), box.size);
                  };
                  instance.onUpdate = (details) {
                    if (isDragging) {
                      final box = dialBox();
                      if (box == null) return;
                      updateAngle(
                          box.globalToLocal(details.globalPosition), box.size);
                    }
                  };
                  instance.onEnd = (details) {
                    isDragging = false;
                  };
                },
              ),
            },
            child: SizedBox(
              key: _dialKey,
              width: dim,
              height: dim,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: RadialDialPainter(
                      value: outerValueProvider.getOuterValue().toDouble(),
                      max: maxValue,
                      color: colorPrimaryDark,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  CustomPaint(
                    painter: InnerDialPainter(),
                    child: SizedBox(
                      width: dim * 0.9,
                      height: dim * 0.9,
                    ),
                  ),
                  CustomPaint(
                    painter: InnerPointerPainter(
                      value: outerValueProvider.getOuterValue().toDouble(),
                      max: maxValue,
                      color: colorPrimaryDark,
                    ),
                    child: SizedBox(
                      width: dim * 0.7,
                      height: dim * 0.7,
                    ),
                  ),
                  Text(
                    (outerValueProvider.getOuterValue()).toString(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromRGBO(113, 113, 113, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectivePanGestureRecognizer extends PanGestureRecognizer {
  final bool Function(PointerDownEvent event) shouldClaimGesture;

  _SelectivePanGestureRecognizer({
    super.debugOwner,
    required this.shouldClaimGesture,
  });

  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);

    if (shouldClaimGesture(event)) {
      resolve(GestureDisposition.accepted);
    } else {
      resolve(GestureDisposition.rejected);
    }
  }
}
