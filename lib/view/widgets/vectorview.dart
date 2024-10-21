import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VectorGridView extends StatefulWidget {
  const VectorGridView({super.key});

  @override
  State<VectorGridView> createState() => _VectorGridViewState();
}

class _VectorGridViewState extends State<VectorGridView> {
  @override
  Widget build(BuildContext context) {
    InlineImageProvider inlineImageProvider =
        Provider.of<InlineImageProvider>(context);
    List keys = inlineImageProvider.imageCache.keys.toList();
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
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
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.memory(
                    inlineImageProvider.imageCache[keys[index]]!,
                    scale: 0.1,
                  )),
            ));
      },
      itemCount: keys.length,
    );
  }
}
