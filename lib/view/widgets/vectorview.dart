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
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  // Reorders the imageCache keys so similar built-in cliparts sit together,
  // WITHOUT changing the keys themselves. The key is the placeholder index a
  // saved badge references (`<<NN>>`), so it must be preserved; only the
  // display order changes. User-added cliparts use non-int (List) keys and are
  // appended after the built-ins.
  List<Object> _groupedKeys(InlineImageProvider provider) {
    final vectors = provider.vectors;

    String pathFor(Object key) =>
        (key is int && key < vectors.length) ? vectors[key] : '';

    // Hide visual-duplicate built-ins from the grid (keys are preserved, only
    // the display is filtered, so selection/placeholders are unaffected).
    final keys = provider.imageCache.keys.where((key) {
      return !_hiddenDuplicateAssets.contains(pathFor(key));
    }).toList();

    keys.sort((a, b) {
      final aIsInt = a is int;
      final bIsInt = b is int;
      if (aIsInt != bIsInt) return aIsInt ? -1 : 1; // built-ins first
      if (!aIsInt) return 0; // keep custom cliparts in insertion order

      final ra = _groupRank(pathFor(a));
      final rb = _groupRank(pathFor(b));
      if (ra[0] != rb[0]) return ra[0].compareTo(rb[0]);
      if (ra[1] != rb[1]) return ra[1].compareTo(rb[1]);
      return pathFor(a).compareTo(pathFor(b));
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);
    final List<Object> keys = _groupedKeys(inlineImageProvider);
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
      itemBuilder: (context, index) {
        if (index == keys.length) {
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

        return GestureDetector(
            onTap: () {
              inlineImageProvider.insertInlineImage(keys[index]);
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
                  inlineImageProvider.imageCache[keys[index]]!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ));
      },
      itemCount: keys.length + 1,
    );
  }
}
