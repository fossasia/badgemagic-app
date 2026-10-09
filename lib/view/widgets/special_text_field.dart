import 'package:badgemagic/providers/inline_image_provider.dart';
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
        final vectorIndex = textData.imageCache.keys.firstWhere(
          (cacheKey) =>
              cacheKey == index ||
              (cacheKey is List && cacheKey.length > 1 && cacheKey[1] == index),
          orElse: () => index,
        );

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

const int kInlineImageSentinelStart = 0x7fffffff;

class ScreenDivider extends SpecialText {
  static const String flag = '|';
  ScreenDivider(TextStyle? textStyle, {this.start})
      : super('|', '', textStyle);
  final int? start;

  @override
  InlineSpan finishText() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 1.5,
        height: 16.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        color: Colors.red.withValues(alpha: 0.5),
      ),
    );
  }
}

class HiddenDivider extends SpecialText {
  static const String flag = '|';
  HiddenDivider(TextStyle? textStyle, {this.start})
      : super('|', '', textStyle);
  final int? start;

  @override
  InlineSpan finishText() {
    return const WidgetSpan(
      child: SizedBox.shrink(), // Completely invisible
    );
  }
}

class ImageBuilder extends SpecialTextSpanBuilder {
  final bool isAnimationMode;

  ImageBuilder({this.isAnimationMode = false});

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index,
      int? start}) {
    if (flag.contains(InlineImage.flag)) {
      return InlineImage(
        textStyle,
        start: kInlineImageSentinelStart,
      );
    } else if (flag.contains(ScreenDivider.flag)) {
      if (isAnimationMode) {
        return ScreenDivider(textStyle, start: index);
      } else {
        return HiddenDivider(textStyle, start: index);
      }
    }
    return null;
  }
}
