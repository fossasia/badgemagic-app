import 'package:badgemagic/constants.dart';
import 'package:flutter/material.dart';

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

class GifGridView extends StatefulWidget {
  final ScrollController? controller;
  final ValueChanged<String> onGifSelected;
  final String? selectedPath;

  const GifGridView({
    super.key,
    this.controller,
    required this.onGifSelected,
    this.selectedPath,
  });

  @override
  State<GifGridView> createState() => _GifGridViewState();
}

class _GifGridViewState extends State<GifGridView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(right: 10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: presetGifs.length,
      itemBuilder: (context, index) {
        final gif = presetGifs[index];
        final String path = gif['path']!;
        final String label = gif['label']!;
        final bool isSelected = widget.selectedPath == path;
        return _GifTile(
          path: path,
          label: label,
          isSelected: isSelected,
          onTap: () => widget.onGifSelected(path),
        );
      },
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
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.1725,
                    0,
                    0,
                    0,
                    255,
                    0,
                    -0.8157,
                    0,
                    0,
                    255,
                    0,
                    0,
                    -0.8157,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Image.asset(
                    path,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
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
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
