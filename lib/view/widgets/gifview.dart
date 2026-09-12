import 'dart:async';
import 'dart:math' as math;

import 'package:badgemagic/badge_animation/animation_abstract.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/view/widgets/special_animation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

const List<Map<String, String>> presetGifs = [
  {'path': 'assets/gifs/cosmic_cat.gif', 'label': 'Cosmic Cat'},
  {'path': 'assets/gifs/dino_run.gif', 'label': 'Dino Run'},
  {'path': 'assets/gifs/invader.gif', 'label': 'Invader'},
  {'path': 'assets/gifs/rocket.gif', 'label': 'Rocket'},
  {'path': 'assets/gifs/smiley.gif', 'label': 'Smiley'},
  {'path': 'assets/gifs/ghost.gif', 'label': 'Ghost'},
  {'path': 'assets/gifs/skull.gif', 'label': 'Skull'},
  {'path': 'assets/gifs/dvd.gif', 'label': 'DVD'},
  {'path': 'assets/gifs/bounce.gif', 'label': 'Bounce'},
  {'path': 'assets/gifs/coffee.gif', 'label': 'Coffee'},
  {'path': 'assets/gifs/rain.gif', 'label': 'Rain'},
  {'path': 'assets/gifs/wave.gif', 'label': 'Wave'},
];

class GifAnimationGridView extends StatefulWidget {
  final ScrollController? controller;
  final ValueChanged<String> onGifSelected;
  final String? selectedGifPath;
  final bool nested;

  const GifAnimationGridView({
    super.key,
    this.controller,
    required this.onGifSelected,
    this.selectedGifPath,
    this.nested = false,
  });

  @override
  State<GifAnimationGridView> createState() => _GifAnimationGridViewState();
}

class _GifAnimationGridViewState extends State<GifAnimationGridView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    final items =
        <({bool isGif, String? path, IconData? icon, String label, int index})>[
      for (final g in presetGifs)
        (
          isGif: true,
          path: g['path']!,
          icon: null,
          label: g['label']!,
          index: -1
        ),
      (
        isGif: false,
        path: null,
        icon: Icons.sports_esports,
        label: l10n.pacman,
        index: 9
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.chevron_left,
        label: l10n.chevron,
        index: 10
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.diamond,
        label: l10n.diamond,
        index: 11
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.heart_broken,
        label: l10n.brokenHearts,
        index: 12
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.favorite_border,
        label: l10n.cupid,
        index: 13
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.directions_walk,
        label: l10n.feet,
        index: 14
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.set_meal,
        label: l10n.fishKiss,
        index: 15
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.change_history,
        label: l10n.diagonal,
        index: 16
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.warning,
        label: l10n.emergency,
        index: 17
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.favorite,
        label: l10n.beatingHearts,
        index: 18
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.celebration,
        label: l10n.fireworks,
        index: 19
      ),
      (
        isGif: false,
        path: null,
        icon: Icons.equalizer,
        label: l10n.equalizer,
        index: 20
      ),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return Consumer<AnimationBadgeProvider>(
      builder: (context, animProv, _) => GridView.builder(
        controller: widget.nested ? null : _scrollController,
        shrinkWrap: true,
        physics: widget.nested
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(right: 10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item.isGif) {
            final isSelected =
                animProv.isGifActive && widget.selectedGifPath == item.path;
            return _GifTile(
              path: item.path!,
              label: item.label,
              isSelected: isSelected,
              onTap: () => widget.onGifSelected(item.path!),
            );
          } else {
            return _AnimationGifTile(
              icon: item.icon!,
              label: item.label,
              index: item.index,
            );
          }
        },
      ),
    );
  }
}

class _GifTile extends StatelessWidget {
  final String path;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GifTile({
    required this.path,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: isSelected ? colorPrimary : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        surfaceTintColor: Colors.white,
        color: isSelected ? const Color(0xFFFFF2F2) : Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AnimatingGifLedPreview(assetPath: path),
              ),
              const SizedBox(height: 4),
              _TileFooter(label: label, isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimationGifTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;

  const _AnimationGifTile({
    required this.icon,
    required this.label,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationBadgeProvider>(
      builder: (context, animProv, _) {
        final badgeAnimation = animationMap[index];
        final isSelected = animProv.isAnimationActive(badgeAnimation);
        return GestureDetector(
          onTap: () async {
            final textController =
                Provider.of<InlineImageProvider>(context, listen: false)
                    .getController();
            if (textController.text.trim().isNotEmpty) {
              final shouldSwitch = await showSpecialAnimationDialog(
                  context, textController.text.trim());
              if (shouldSwitch == true) {
                textController.clear();
                animProv.setAnimationMode(badgeAnimation);
                animProv.badgeAnimation('', Converters(), false);
              }
              return;
            }
            animProv.setAnimationMode(badgeAnimation);
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: BorderSide(
                color: isSelected ? colorPrimary : Colors.transparent,
                width: isSelected ? 1.5 : 0,
              ),
            ),
            surfaceTintColor: Colors.white,
            color: isSelected ? const Color(0xFFFFF2F2) : Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: badgeAnimation != null
                        ? _AnimatingLedPreview(animation: badgeAnimation)
                        : Icon(icon,
                            color: isSelected ? colorPrimary : Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  _TileFooter(label: label, isSelected: isSelected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TileFooter extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TileFooter({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isSelected
              ? Icons.stop_circle_rounded
              : Icons.play_circle_fill_rounded,
          color: colorPrimary,
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? colorPrimary : Colors.black87,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatingLedPreview extends StatefulWidget {
  final BadgeAnimation animation;

  const _AnimatingLedPreview({required this.animation});

  @override
  State<_AnimatingLedPreview> createState() => _AnimatingLedPreviewState();
}

class _AnimatingLedPreviewState extends State<_AnimatingLedPreview> {
  static const _rows = 11;
  static const _cols = 44;

  late List<List<bool>> _grid;
  late List<List<bool>> _work;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _grid = List.generate(_rows, (_) => List.generate(_cols, (_) => false));
    _work = List.generate(_rows, (_) => List.generate(_cols, (_) => false));
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      widget.animation.processAnimation(_rows, _cols, _index, _work, _grid);
      setState(() {
        final tmp = _grid;
        _grid = _work;
        _work = tmp;
        _index++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LedPainter(grid: _grid));
  }
}

class _AnimatingGifLedPreview extends StatefulWidget {
  final String assetPath;

  const _AnimatingGifLedPreview({required this.assetPath});

  @override
  State<_AnimatingGifLedPreview> createState() =>
      _AnimatingGifLedPreviewState();
}

class _AnimatingGifLedPreviewState extends State<_AnimatingGifLedPreview> {
  final _imageUtils = ImageUtils();
  List<List<List<bool>>> _frames = [];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final frames =
          _imageUtils.decodeGifFramesToBool(bytes.buffer.asUint8List());
      if (!mounted || frames.isEmpty) return;
      setState(() => _frames = frames);
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _frames.length);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) return const SizedBox.shrink();
    return CustomPaint(painter: _LedPainter(grid: _frames[_index]));
  }
}

class _LedPainter extends CustomPainter {
  final List<List<bool>> grid;

  const _LedPainter({required this.grid});

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid[0].isEmpty) return;
    final rows = grid.length;
    final cols = grid[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final r = math.min(cellW, cellH) * 0.38;

    final onPaint = Paint()..color = const Color(0xFF5C0000);
    final offPaint = Paint()..color = const Color(0xFFEEEEEE);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawCircle(
          Offset(col * cellW + cellW / 2, row * cellH + cellH / 2),
          r,
          grid[row][col] ? onPaint : offPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LedPainter old) => old.grid != grid;
}
