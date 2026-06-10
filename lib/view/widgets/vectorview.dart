import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const List<List<String>> _clipartGroups = [
  [
    'smile_face',
    'face',
    'sad_face',
    'expressionless',
    'without_mouth',
    'mustache',
  ],
  ['thumbs_up', 'thumb_up', 'thumb_down'],
  ['heart_filled', 'heart'],
  ['star_outline', 'star'],
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
  ['play_pause', 'play', 'pause'],
  ['music'],
  ['clock'],
  ['sun', 'moon', 'lightning', 'bolt'],
  ['check', 'tick', 'cross', 'block', 'info'],
  ['diamond', 'hexagon', 'square', 'triangle', 'bar'],
  ['mail', 'bell', 'camera', 'flag', 'home', 'gift'],
  ['invader', 'oneup', 'spider', 'mushroom', 'apple'],
  ['mix', 'dustbin'],
];

const Set<String> _hiddenDuplicateAssets = {
  'assets/vectors/clip_arrow_left.svg',
  'assets/vectors/clip_thumbs_up.SVG',
};

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
        final aId = a.isNotEmpty ? a.first.toString() : '';
        final bId = b.isNotEmpty ? b.first.toString() : '';
        return bId.compareTo(aId);
      });

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
      padding: const EdgeInsets.only(right: 12.0),
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
