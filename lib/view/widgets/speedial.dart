import 'dart:math';

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/speed_dial_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class InnerDialPainter extends CustomPainter {
  final double scale;
  InnerDialPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.7;

    final paint = Paint()
      ..color = backCircleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.w * scale;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant InnerDialPainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

class RadialDialPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;
  final double scale;

  RadialDialPainter({
    required this.value,
    required this.max,
    required this.color,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.8;

    final paint = Paint()
      ..color = backCircleColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 4.w * scale;

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
      ..strokeWidth = 9.w * scale;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6 * pi / 4 * (value / max),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialDialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.scale != scale;
  }
}

class InnerPointerPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;
  final double scale;

  InnerPointerPainter({
    required this.value,
    required this.max,
    required this.color,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) * 0.5;

    final pointerAngle = 3 * pi / 4 + 6 * pi / 4 * (value / max);
    final pointerLength = radius + (15.w * scale);

    final pointerPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 4.w * scale;

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
  bool shouldRepaint(covariant InnerPointerPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.scale != scale;
  }
}

class RadialDial extends StatefulWidget {
  final bool isSmall;
  const RadialDial({super.key, this.isSmall = false});

  @override
  State<RadialDial> createState() => _RadialDialState();
}

class _RadialDialState extends State<RadialDial> {
  final double maxValue = 8.0;
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    SpeedDialProvider outerValueProvider =
        Provider.of<SpeedDialProvider>(context);

    final double scale = widget.isSmall ? 0.75 : 1.2;
    const duration = Duration(milliseconds: 300);

    bool isTouchOnActiveArea(PointerDownEvent event) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(event.position);
      final center = Offset(box.size.width / 2, box.size.height / 2);
      final distance = (localPosition - center).distance;

      final double minActiveRadius = 30.w * scale;
      final double maxActiveRadius = 120.w * scale;

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

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      alignment: const Alignment(0.0, 0.15),
      child: SizedBox(
        width: 240.w * scale,
        height: 240.h * scale,
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
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  updateAngle(renderBox.globalToLocal(details.globalPosition),
                      renderBox.size);
                };
                instance.onUpdate = (details) {
                  if (isDragging) {
                    RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    updateAngle(renderBox.globalToLocal(details.globalPosition),
                        renderBox.size);
                  }
                };
                instance.onEnd = (details) {
                  isDragging = false;
                };
              },
            ),
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeInOut,
                width: 200.w * scale,
                height: 210.h * scale,
                child: CustomPaint(
                  painter: RadialDialPainter(
                    value: outerValueProvider.getOuterValue().toDouble(),
                    max: maxValue,
                    color: colorPrimaryDark,
                    scale: scale,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeInOut,
                width: 180.w * scale,
                height: 180.h * scale,
                child: CustomPaint(
                  painter: InnerDialPainter(scale: scale),
                ),
              ),
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeInOut,
                width: 140.w * scale,
                height: 140.h * scale,
                child: CustomPaint(
                  painter: InnerPointerPainter(
                    value: outerValueProvider.getOuterValue().toDouble(),
                    max: maxValue,
                    color: colorPrimaryDark,
                    scale: scale,
                  ),
                ),
              ),
              Positioned(
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: 50.sp * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(113, 113, 113, 1),
                  ),
                  child: Text(
                    (outerValueProvider.getOuterValue()).toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
