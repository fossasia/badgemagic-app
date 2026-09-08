import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/color.dart';

Future<Uint8List?> showImageCropScreen(
  BuildContext context,
  Uint8List imageBytes, {
  double? aspectRatio,
}) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => ImageCropScreen(
        imageBytes: imageBytes,
        aspectRatio: aspectRatio,
      ),
    ),
  );
}

class _AspectRatioOption {
  final String label;
  final double? ratio;

  const _AspectRatioOption(this.label, this.ratio);
}

class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final double? aspectRatio;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.aspectRatio,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  final CropController _controller = CropController();
  bool _isCropping = false;
  double? _selectedRatio;

  @override
  void initState() {
    super.initState();
    _selectedRatio = widget.aspectRatio;
  }

  bool get _ratioLocked => widget.aspectRatio != null;

  void _selectRatio(double? ratio) {
    setState(() => _selectedRatio = ratio);
    _controller.aspectRatio = ratio;
  }

  Widget _cornerBracket(double size, EdgeAlignment edgeAlignment) {
    const double hitSize = 48;
    final double shift = size / 2 - hitSize / 2;
    return Transform.translate(
      offset: Offset(shift, shift),
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: CustomPaint(
          painter: _CornerPainter(edgeAlignment),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final List<_AspectRatioOption> options = [
      _AspectRatioOption(appLocalizations.cropFree, null),
      const _AspectRatioOption('1:1', 1),
      const _AspectRatioOption('4:3', 4 / 3),
      const _AspectRatioOption('3:4', 3 / 4),
      const _AspectRatioOption('16:9', 16 / 9),
      const _AspectRatioOption('9:16', 9 / 16),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: colorAccent,
        foregroundColor: Colors.white,
        title: Text(appLocalizations.cropImage),
        actions: [
          IconButton(
            tooltip: appLocalizations.cropImage,
            icon: const Icon(Icons.check),
            onPressed: _isCropping
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _controller.crop();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Crop(
                  controller: _controller,
                  image: widget.imageBytes,
                  aspectRatio: widget.aspectRatio,
                  initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                    size: 0.85,
                    aspectRatio: widget.aspectRatio,
                  ),
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.55),
                  radius: 2,
                  overlayBuilder: (context, rect) => IgnorePointer(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _GridPainter(),
                    ),
                  ),
                  cornerDotBuilder: _cornerBracket,
                  onCropped: (result) {
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        if (mounted) Navigator.of(context).pop(croppedImage);
                      case CropFailure():
                        if (mounted) setState(() => _isCropping = false);
                    }
                  },
                ),
                if (_isCropping)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          if (!_ratioLocked)
            SafeArea(
              top: false,
              child: Container(
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final option in options)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(option.label),
                            selected: _selectedRatio == option.ratio,
                            onSelected: _isCropping
                                ? null
                                : (_) => _selectRatio(option.ratio),
                            selectedColor: colorAccent,
                            backgroundColor: Colors.grey.shade800,
                            shape: const StadiumBorder(),
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: _selectedRatio == option.ratio
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Offset.zero & size, border);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final EdgeAlignment alignment;

  _CornerPainter(this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    const double arm = 18;
    final paint = Paint()
      ..color = colorAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final Offset vertex = Offset(size.width / 2, size.height / 2);
    final bool right = alignment == EdgeAlignment.topRight ||
        alignment == EdgeAlignment.bottomRight;
    final bool bottom = alignment == EdgeAlignment.bottomLeft ||
        alignment == EdgeAlignment.bottomRight;
    final double hDir = right ? -1 : 1;
    final double vDir = bottom ? -1 : 1;

    canvas.drawLine(vertex, vertex + Offset(arm * hDir, 0), paint);
    canvas.drawLine(vertex, vertex + Offset(0, arm * vDir), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.alignment != alignment;
}
