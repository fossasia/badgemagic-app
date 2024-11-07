import 'package:badgemagic/providers/imageprovider.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

class InlineImage extends SpecialText {
  InlineImageProvider textData = GetIt.instance.get<InlineImageProvider>();
  InlineImage(TextStyle? textStyle, {this.start})
      : super(InlineImage.flag, '>>', textStyle);
  static const String flag = '<<';
  final int? start;

  @override
  InlineSpan finishText() {
    final String key = toString();

    if (key.length > 4 && key.startsWith('<<') && key.endsWith('>>')) {
      try {
        final int index = int.parse(key.substring(2, key.length - 2));
        var vectorIndex = textData.imageCache.keys.toList()[index];

        final image = textData.imageCache[vectorIndex];
        if (image != null) {
          return ImageSpan(
            MemoryImage(image),
            imageWidth: 25.w,
            imageHeight: 20.h,
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
  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index,
      int? start}) {
    if (flag.contains(InlineImage.flag)) {
      return InlineImage(
        textStyle,
        start: 999999999999999999,
      );
    }
    return null;
  }
}
