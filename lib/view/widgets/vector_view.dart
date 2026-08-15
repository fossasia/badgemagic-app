import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:flutter/foundation.dart';
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
  late final TextEditingController _messageController;
  Set<int> _selectedIndices = {};

  static final RegExp _placeholderRegExp = RegExp(r'<<(\d+)>>');

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _messageController =
        Provider.of<InlineImageProvider>(context, listen: false)
            .getController();
    _messageController.addListener(_updateSelectionFromText);
    _updateSelectionFromText();
  }

  void _updateSelectionFromText() {
    final indices = _placeholderRegExp
        .allMatches(_messageController.text)
        .map((m) => int.parse(m.group(1)!))
        .toSet();
    if (!setEquals(indices, _selectedIndices)) {
      setState(() {
        _selectedIndices = indices;
      });
    }
  }

  int _indexForKey(dynamic key) {
    if (key is int) return key;
    if (key is List && key.length > 1 && key[1] is int) return key[1] as int;
    return -1;
  }

  int _columnsForWidth(double width) {
    if (width < 300) return (width / 48).round().clamp(3, 6);
    if (width <= 520) return 7;
    return (width / 54).round();
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSelectionFromText);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = _columnsForWidth(constraints.maxWidth);
        return GridView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(right: 4.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
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
                  surfaceTintColor: colorSurface,
                  color: colorSurface,
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

            final bool isSelected =
                _selectedIndices.contains(_indexForKey(imageKey));

            return GestureDetector(
              onTap: () {
                inlineImageProvider.insertInlineImage(imageKey);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: isSelected
                      ? BorderSide(color: colorTextSecondary, width: 2)
                      : BorderSide.none,
                ),
                surfaceTintColor: colorSurface,
                color: isSelected ? colorBorder : colorSurface,
                elevation: isSelected ? 4 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
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
      },
    );
  }
}
