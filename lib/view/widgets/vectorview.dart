import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Clipart grouping
// ---------------------------------------------------------------------------
// Built-in cliparts are loaded from `assets/vectors/` in asset-manifest order,
// which is essentially arbitrary, so visually-similar icons end up scattered
// across the grid. To make the picker easier to browse we sort the built-in
// cliparts into the ordered category list below. Each category lists keyword
// substrings that are matched (case-insensitively) against the asset filename.
//
// The order of this list defines the on-screen order of the groups, and the
// keyword order inside a group defines the order within that group. The first
// category that matches a filename wins, so keep keywords reasonably specific.
const List<List<String>> _clipartGroups = [
  // Emoji / faces
  [
    'smile_face',
    'face',
    'sad_face',
    'expressionless',
    'without_mouth',
    'mustache',
  ],
  // Thumbs / gestures
  ['thumbs_up', 'thumb_up', 'thumb_down'],
  // Love / hearts
  ['heart_filled', 'heart'],
  // Stars
  ['star_outline', 'star'],
  // Arrows / directions
  [
    'up_arrow',
    'down_arrow',
    'left_arrow',
    'right_arrow',
    'arrow_left',
    'north_east_arrow',
    'north_west_arrow',
    'south_east_arrow',
    'south_west_arrow',
    'arrow',
    'subdirectory',
  ],
  // Media controls
  ['play_pause', 'play', 'pause'],
  // Music
  ['music'],
  // Clock / time
  ['clock'],
  // Weather / sky
  ['sun', 'moon', 'lightning', 'bolt'],
  // Status: check / cross / block / info
  ['check', 'tick', 'cross', 'block', 'info'],
  // Shapes
  ['diamond', 'hexagon', 'square', 'triangle', 'bar'],
  // Communication / objects
  ['mail', 'bell', 'camera', 'flag', 'home', 'gift'],
  // Creatures / game
  ['invader', 'oneup', 'spider', 'mushroom', 'apple'],
  // Misc
  ['mix', 'dustbin'],
];

// Built-in cliparts that are visual duplicates of another clipart and should
// not be shown in the picker. clip_arrow_left.svg, despite its name, renders as
// a RIGHT-pointing arrow identical to clip_right_arrow.SVG, so we hide it.
//
// NOTE: this only hides the clipart from the grid; the asset and its imageCache
// key are intentionally kept so saved badges that reference its `<<NN>>`
// placeholder (and every other clipart's index) stay valid.
const Set<String> _hiddenDuplicateAssets = {
  'assets/vectors/clip_arrow_left.svg',
};

// Returns a sortable rank for an asset path: (group index, keyword index).
// Unknown assets sort after all known groups, preserving a stable order.
List<int> _groupRank(String assetPath) {
  final name = assetPath.toLowerCase();
  for (int g = 0; g < _clipartGroups.length; g++) {
    final keywords = _clipartGroups[g];
    for (int k = 0; k < keywords.length; k++) {
      if (name.contains(keywords[k])) {
        return [g, k];
      }
    }
  }
  return [_clipartGroups.length, 0];
}

class VectorGridView extends StatefulWidget {
  final ScrollController? controller;

  const VectorGridView({super.key, this.controller});

  @override
  State<VectorGridView> createState() => _VectorGridViewState();
}

class _VectorGridViewState extends State<VectorGridView> {
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
    final inlineImageProvider = Provider.of<InlineImageProvider>(context);
    final vectors = inlineImageProvider.vectors;
    String pathFor(int key) => key < vectors.length ? vectors[key] : '';

    final allKeys = inlineImageProvider.imageCache.keys.toList();

    final savedKeys = allKeys.whereType<List>().toList()
      ..sort((a, b) {
        // newest first (based on first element string/id)
        final aId = a.isNotEmpty ? a.first.toString() : '';
        final bId = b.isNotEmpty ? b.first.toString() : '';
        return bId.compareTo(aId);
      });

    // Built-in cliparts: hide visual duplicates, then group similar icons
    // together. Sorting only changes display order; the imageCache key (the
    // `<<NN>>` placeholder index) is preserved, so selection/saved badges are
    // unaffected.
    final defaultKeys = allKeys
        .whereType<int>()
        .where((key) => key < vectors.length)
        .where((key) => !_hiddenDuplicateAssets.contains(pathFor(key)))
        .toList()
      ..sort((a, b) {
        final ra = _groupRank(pathFor(a));
        final rb = _groupRank(pathFor(b));
        if (ra[0] != rb[0]) return ra[0].compareTo(rb[0]);
        if (ra[1] != rb[1]) return ra[1].compareTo(rb[1]);
        return pathFor(a).compareTo(pathFor(b));
      });

    final keys = <dynamic>[
      ...savedKeys,
      ...defaultKeys,
    ];

    return GridView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: keys.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/drawBadge');
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              surfaceTintColor: Colors.white,
              color: Colors.white,
              elevation: 2,
              child: Center(
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colorPrimary,
                ),
              ),
            ),
          );
        }

        final imageKey = keys[index - 1];

        final imageBytes = inlineImageProvider.imageCache[imageKey];

        if (imageBytes == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            inlineImageProvider.insertInlineImage(imageKey);
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            surfaceTintColor: Colors.white,
            color: Colors.white,
            elevation: 2,
            // Fit each clipart to its cell. The previous `scale: 0.1` sized
            // each image by its raw pixel count, so cliparts looked wildly
            // uneven. BoxFit.contain scales every (normalized, square) bitmap
            // to fill its cell uniformly, preserving aspect ratio with no
            // stretching or cropping and balanced padding.
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        );
      },
    );
  }
}
