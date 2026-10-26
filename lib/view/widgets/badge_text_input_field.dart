import 'dart:math' as math;

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/theme/app_radius.dart';
import 'package:badgemagic/view/widgets/special_text_field.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';

import '../../others/localization_service.dart';
import '../../others/toast_utils.dart';

class BadgeTextInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPrefixToggle;
  final VoidCallback onFontChanged;

  const BadgeTextInputField({
    super.key,
    required this.controller,
    required this.onPrefixToggle,
    required this.onFontChanged,
  });

  static TextStyle _getFontStyle(String fontName) {
    const baseStyle = TextStyle(fontSize: 12);
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Open Sans':
        return GoogleFonts.openSans(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lato':
        return GoogleFonts.lato(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Poppins':
        return GoogleFonts.poppins(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Montserrat':
        return GoogleFonts.montserrat(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Orbitron':
        return GoogleFonts.orbitron(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      case 'Lexend':
        return GoogleFonts.lexend(
            textStyle: baseStyle.copyWith(fontWeight: FontWeight.w700));
      default:
        return baseStyle;
    }
  }

  static const Map<String, int> _charLedWidths = {
    '0': 8,
    '1': 7,
    '2': 8,
    '3': 8,
    '4': 8,
    '5': 8,
    '6': 8,
    '7': 8,
    '8': 8,
    '9': 8,
    '#': 8,
    '&': 8,
    '_': 9,
    '-': 8,
    '?': 8,
    '@': 9,
    '(': 5,
    ')': 5,
    '=': 7,
    '+': 7,
    '!': 5,
    "'": 3,
    ':': 3,
    '%': 8,
    '/': 8,
    '"': 7,
    '[': 5,
    ']': 5,
    ' ': 3,
    '*': 9,
    ',': 3,
    '.': 3,
    '\$': 8,
    '~': 8,
    '{': 7,
    '}': 7,
    '<': 7,
    '>': 7,
    '^': 8,
    '`': 3,
    ';': 3,
    '\\': 8,
    '|': 3,
    'a': 8,
    'b': 8,
    'c': 8,
    'd': 8,
    'e': 8,
    'f': 7,
    'g': 8,
    'h': 8,
    'i': 5,
    'j': 7,
    'k': 8,
    'l': 5,
    'm': 8,
    'n': 8,
    'o': 8,
    'p': 8,
    'q': 8,
    'r': 8,
    's': 8,
    't': 7,
    'u': 8,
    'v': 8,
    'w': 8,
    'x': 8,
    'y': 7,
    'z': 8,
    'A': 8,
    'B': 8,
    'C': 8,
    'D': 8,
    'E': 8,
    'F': 8,
    'G': 8,
    'H': 8,
    'I': 7,
    'J': 7,
    'K': 8,
    'L': 8,
    'M': 8,
    'N': 8,
    'O': 7,
    'P': 8,
    'Q': 8,
    'R': 8,
    'S': 8,
    'T': 7,
    'U': 8,
    'V': 8,
    'W': 8,
    'X': 8,
    'Y': 7,
    'Z': 8,
  };

  static int _getCharWidth(String char) => _charLedWidths[char] ?? 8;

  static final RegExp _emojiRegex = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\udc00-\udfff]|\ud83d[\udc00-\udfff]|\ud83e[\udc00-\udfff]|[\uFE00-\uFE0F])',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final isAnimationMode =
        Provider.of<AnimationBadgeProvider>(context).getAnimationIndex() == 5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      child: Material(
        color: drawerHeaderTitle,
        borderRadius: BorderRadius.circular(AppRadius.medium.r),
        elevation: 4,
        child: ExtendedTextField(
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (_emojiRegex.hasMatch(newValue.text)) {
                final strippedText = newValue.text.replaceAll(_emojiRegex, ' ');
                ToastUtils().showToast(l10n.notSupportedEmojis);
                final newSelectionOffset = math.min(
                  newValue.selection.baseOffset,
                  strippedText.length,
                );
                return TextEditingValue(
                  text: strippedText,
                  selection: TextSelection.collapsed(
                    offset: math.max(0, newSelectionOffset),
                  ),
                );
              }
              return newValue;
            }),
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (!isAnimationMode) return newValue;
              if (newValue.text.length <= oldValue.text.length) {
                return newValue;
              }

              String text = newValue.text;
              int cursor = newValue.selection.baseOffset;
              if (cursor <= 0 || cursor > text.length) return newValue;

              while (true) {
                final frameStart = text.lastIndexOf('|', cursor - 1) + 1;
                final currentFrame = text.substring(frameStart, cursor);

                int frameWidth = 0;
                int overflowIndex = -1;
                int i = 0;
                while (i < currentFrame.length) {
                  int itemWidth = 8;
                  int itemLen = 1;

                  if (currentFrame[i] == '<' &&
                      i + 5 < currentFrame.length &&
                      currentFrame[i + 5] == '>') {
                    itemWidth = 12;
                    itemLen = 6;
                  } else if (currentFrame[i] == '[' &&
                      i + 3 < currentFrame.length &&
                      currentFrame[i + 3] == ']') {
                    itemWidth = 12;
                    itemLen = 4;
                  } else {
                    itemWidth = _getCharWidth(currentFrame[i]);
                    itemLen = 1;
                  }

                  if (frameWidth + itemWidth > 44) {
                    overflowIndex = frameStart + i;
                    break;
                  }
                  frameWidth += itemWidth;
                  i += itemLen;
                }

                if (overflowIndex != -1) {
                  text =
                      '${text.substring(0, overflowIndex)}|${text.substring(overflowIndex)}';
                  cursor = (cursor > overflowIndex) ? cursor + 1 : cursor;
                } else {
                  break;
                }
              }

              return TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: cursor),
              );
            }),
          ],
          controller: controller,
          specialTextSpanBuilder: ImageBuilder(
            isAnimationMode: isAnimationMode,
          ),
          style: Provider.of<FontProvider>(context).selectedFont != null
              ? _getFontStyle(Provider.of<FontProvider>(context).selectedFont!)
                  .copyWith(fontSize: 14)
              : const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium.r),
              borderSide: BorderSide(color: colorPrimary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            prefixIcon: IconButton(
              onPressed: onPrefixToggle,
              icon: const Icon(Icons.tag_faces_outlined),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
            suffixIcon: Consumer<AnimationBadgeProvider>(
              builder: (context, aniProvider, _) {
                final isAnimationMode = aniProvider.getAnimationIndex() == 5;
                return Container(
                  constraints: BoxConstraints(
                    maxWidth: math.min(
                        MediaQuery.of(context).size.width *
                            (isAnimationMode ? 0.42 : 0.280),
                        isAnimationMode ? 300.0 : 200.0),
                  ),
                  padding: EdgeInsets.only(left: 8.w, right: 4.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAnimationMode)
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6.r),
                            onTap: () {
                              final sel = controller.selection;
                              final text = controller.text;
                              final insertPos =
                                  sel.isValid ? sel.baseOffset : text.length;
                              final newText =
                                  '${text.substring(0, insertPos)}|${text.substring(insertPos)}';
                              controller.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: insertPos + 1,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 12,
                                    color: colorPrimary,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    l10n.addFrame,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: colorPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Consumer<FontProvider>(
                          builder: (context, fontProvider, _) {
                            return MenuAnchor(
                              alignmentOffset: const Offset(0, 8),
                              style: MenuStyle(
                                alignment: AlignmentDirectional.bottomEnd,
                                minimumSize:
                                    const WidgetStatePropertyAll(Size(180, 0)),
                                backgroundColor:
                                    const WidgetStatePropertyAll(colorSurface),
                                surfaceTintColor:
                                    const WidgetStatePropertyAll(colorSurface),
                                elevation: const WidgetStatePropertyAll(6),
                                padding: WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(vertical: 6.h),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.large.r),
                                  ),
                                ),
                              ),
                              menuChildren: <String?>[
                                null,
                                ...fontProvider.availableFonts,
                              ].map((opt) {
                                final label = opt ?? 'Default';
                                final selected =
                                    fontProvider.selectedFont == opt;
                                return MenuItemButton(
                                  onPressed: () {
                                    fontProvider.changeFont(opt);
                                    onFontChanged();
                                  },
                                  trailingIcon: selected
                                      ? Icon(Icons.check,
                                          size: 18, color: colorPrimary)
                                      : const SizedBox(width: 18),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.h),
                                    child: Text(
                                      label,
                                      style: (opt == null
                                              ? const TextStyle()
                                              : _getFontStyle(opt))
                                          .copyWith(
                                        fontSize: 14,
                                        color: selected
                                            ? colorPrimary
                                            : colorTextStrong,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              builder: (context, controller, child) {
                                return InkWell(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.medium.r),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    controller.isOpen
                                        ? controller.close()
                                        : controller.open();
                                  },
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 6.h),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            fontProvider.selectedFont ??
                                                'Default',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              color: mdGrey400,
                                              fontSize: 12.sp,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 20,
                                          color: mdGrey400,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
