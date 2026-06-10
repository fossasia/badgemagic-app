import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final allKeys = inlineImageProvider.imageCache.keys.toList();

    final savedKeys = allKeys.whereType<List>().toList()
      ..sort((a, b) {
        // newest first (based on first element string/id)
        final aId = a.isNotEmpty ? a.first.toString() : '';
        final bId = b.isNotEmpty ? b.first.toString() : '';
        return bId.compareTo(aId);
      });

    final defaultKeys = allKeys
        .whereType<int>()
        .where((key) => key < inlineImageProvider.vectors.length)
        .toList()
      ..sort();

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
              padding: const EdgeInsets.all(2.0),
              child: Image.memory(
                imageBytes,
                scale: 0.1,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
