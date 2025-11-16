import 'package:badgemagic/providers/imageprovider.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/utils/custom_transfers/layout_config.dart';

class InlineImage extends SpecialText {
  final LayoutConfig layoutConfig;
  InlineImageProvider textData = GetIt.instance.get<InlineImageProvider>();
  InlineImage(TextStyle? textStyle, {this.start, required this.layoutConfig})
      : super(InlineImage.flag, '>>', textStyle);
  static const String flag = '<<';
  final int? start;

  @override
  InlineSpan finishText() {
    final layout = layoutConfig;
    final String key = toString();

    if (key.length > 4 && key.startsWith('<<') && key.endsWith('>>')) {
      try {
        final int index = int.parse(key.substring(2, key.length - 2));
        var vectorIndex = textData.imageCache.keys.toList()[index];

        final image = textData.imageCache[vectorIndex];
        if (image != null) {
          return ImageSpan(
            MemoryImage(image),
            imageWidth: layout.iconSize * 1.2,
            imageHeight: layout.iconSize * 1.0,
            actualText: key,
            start: start!,
            fit: BoxFit.contain,
          );
        } else {
          throw Exception("Image not found in cache.");
        }
      } catch (e) {
        return TextSpan(
          text: key,
          style: textStyle,
        );
      }
    } else {
      return TextSpan(
        text: key,
        style: textStyle,
      );
    }
  }
}

class ImageBuilder extends SpecialTextSpanBuilder {
  final LayoutConfig layoutConfig;
  ImageBuilder({required this.layoutConfig});
  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index,
      int? start}) {
    if (flag.contains(InlineImage.flag)) {
      return InlineImage(
        layoutConfig: layoutConfig,
        textStyle,
        start: 999999999999999999,
      );
    }
    return null;
  }
}
