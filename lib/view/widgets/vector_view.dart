import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
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

int _getCategoryIndex(String assetPath) {
  final name = assetPath.toLowerCase();

  // 1. Faces & Hands
  if (name.contains('smile_face') ||
      name.contains('face') ||
      name.contains('sad_face') ||
      name.contains('expressionless') ||
      name.contains('without_mouth') ||
      name.contains('mustache') ||
      name.contains('thumbs') ||
      name.contains('thumb')) {
    return 1;
  }

  // 2. Hearts & Stars
  if (name.contains('heart') || name.contains('star')) {
    return 2;
  }

  // 3. Arrows
  if (name.contains('arrow') || name.contains('subdirectory')) {
    return 3;
  }

  // 4. Media & Time
  if (name.contains('play') ||
      name.contains('pause') ||
      name.contains('music') ||
      name.contains('clock')) {
    return 4;
  }

  // 5. Nature & Weather
  if (name.contains('sun') ||
      name.contains('moon') ||
      name.contains('lightning') ||
      name.contains('bolt')) {
    return 5;
  }

  // 6. Symbols & Shapes
  if (name.contains('check') ||
      name.contains('tick') ||
      name.contains('cross') ||
      name.contains('block') ||
      name.contains('info') ||
      name.contains('diamond') ||
      name.contains('hexagon') ||
      name.contains('square') ||
      name.contains('triangle') ||
      name.contains('bar')) {
    return 6;
  }

  // 7. Objects & Retro
  return 7;
}

class ClipartCategory {
  final String title;
  final IconData icon;
  final List<dynamic> keys;

  ClipartCategory({
    required this.title,
    required this.icon,
    required this.keys,
  });
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

  final List<GlobalKey> _sectionKeys = List.generate(8, (_) => GlobalKey());
  int _activeCategoryIndex = 0;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _messageController.removeListener(_updateSelectionFromText);
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isAutoScrolling || !mounted) return;

    final viewPortBox = context.findRenderObject() as RenderBox?;
    if (viewPortBox == null) return;

    int activeIndex = 0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final sectionContext = _sectionKeys[i].currentContext;
      if (sectionContext != null) {
        final box = sectionContext.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPos =
              box.localToGlobal(Offset.zero, ancestor: viewPortBox);
          if (localPos.dy <= 40.0) {
            activeIndex = i;
          }
        }
      }
    }

    if (activeIndex != _activeCategoryIndex) {
      setState(() {
        _activeCategoryIndex = activeIndex;
      });
    }
  }

  void _scrollToSection(int index) async {
    final sectionContext = _sectionKeys[index].currentContext;
    if (sectionContext != null) {
      setState(() {
        _activeCategoryIndex = index;
        _isAutoScrolling = true;
      });
      await Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 50));
      _isAutoScrolling = false;
    }
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

    final List<List<dynamic>> defaultGroupedKeys = List.generate(8, (_) => []);
    for (final key in defaultKeys) {
      final index = _getCategoryIndex(pathFor(key));
      defaultGroupedKeys[index].add(key);
    }

    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    final categories = [
      ClipartCategory(
        title: l10n.clipartCategoryPersonalized,
        icon: Icons.brush_outlined,
        keys: savedKeys,
      ),
      ClipartCategory(
        title: l10n.clipartCategoryFaces,
        icon: Icons.sentiment_satisfied_alt_outlined,
        keys: defaultGroupedKeys[1],
      ),
      ClipartCategory(
        title: l10n.clipartCategoryHeartsStars,
        icon: Icons.favorite_border_rounded,
        keys: defaultGroupedKeys[2],
      ),
      ClipartCategory(
        title: l10n.clipartCategoryArrows,
        icon: Icons.arrow_outward_rounded,
        keys: defaultGroupedKeys[3],
      ),
      ClipartCategory(
        title: l10n.clipartCategoryMediaTime,
        icon: Icons.play_circle_outline_rounded,
        keys: defaultGroupedKeys[4],
      ),
      ClipartCategory(
        title: l10n.clipartCategoryNatureWeather,
        icon: Icons.wb_sunny_outlined,
        keys: defaultGroupedKeys[5],
      ),
      ClipartCategory(
        title: l10n.clipartCategorySymbolsShapes,
        icon: Icons.category_outlined,
        keys: defaultGroupedKeys[6],
      ),
      ClipartCategory(
        title: l10n.clipartCategoryObjectsRetro,
        icon: Icons.videogame_asset_outlined,
        keys: defaultGroupedKeys[7],
      ),
    ];

    return Column(
      children: [
        // Category Tab Bar
        Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => true,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isActive = index == _activeCategoryIndex;
                return GestureDetector(
                  onTap: () => _scrollToSection(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? colorPrimary : Colors.transparent,
                          width: 2.h,
                        ),
                      ),
                    ),
                    child: Icon(
                      cat.icon,
                      color: isActive ? colorPrimary : Colors.grey[600],
                      size: 20.dg,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Scrollable Grids
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 4.0,
            radius: const Radius.circular(10),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(right: 12.w, bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(categories.length, (catIndex) {
                    final cat = categories[catIndex];

                    if (catIndex != 0 && cat.keys.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      key: _sectionKeys[catIndex],
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 4.w, top: 12.h, bottom: 6.h),
                          child: Text(
                            cat.title,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: cat.keys.length + (catIndex == 0 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (catIndex == 0 && index == 0) {
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: colorPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final imageKey = catIndex == 0
                                ? cat.keys[index - 1]
                                : cat.keys[index];
                            final imageBytes =
                                inlineImageProvider.imageCache[imageKey];

                            if (imageBytes == null) {
                              return const SizedBox.shrink();
                            }

                            final bool isSelected = _selectedIndices
                                .contains(_indexForKey(imageKey));

                            return GestureDetector(
                              onTap: () {
                                inlineImageProvider.insertInlineImage(imageKey);
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: isSelected
                                      ? BorderSide(
                                          color: colorTextSecondary, width: 2)
                                      : BorderSide.none,
                                ),
                                surfaceTintColor: colorSurface,
                                color: isSelected ? colorBorder : colorSurface,
                                elevation: isSelected ? 4 : 2,
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
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
