import 'dart:math' as math;

import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/view/widgets/special_text_field.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  static final RegExp _emojiRegex = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\udc00-\udfff]|\ud83d[\udc00-\udfff]|\ud83e[\udc00-\udfff]|[\uFE00-\uFE0F])',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      child: Material(
        color: drawerHeaderTitle,
        borderRadius: BorderRadius.circular(10.r),
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
          ],
          controller: controller,
          specialTextSpanBuilder: ImageBuilder(),
          style: Provider.of<FontProvider>(context).selectedFont != null
              ? _getFontStyle(Provider.of<FontProvider>(context).selectedFont!)
                  .copyWith(fontSize: 14)
              : const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
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
            suffixIcon: Container(
              constraints: BoxConstraints(
                maxWidth:
                    math.min(MediaQuery.of(context).size.width * 0.280, 200.0),
              ),
              padding: EdgeInsets.only(left: 8.w, right: 8.w),
              child: Consumer<FontProvider>(
                builder: (context, fontProvider, _) {
                  return MenuAnchor(
                    alignmentOffset: const Offset(0, 8),
                    style: MenuStyle(
                      alignment: AlignmentDirectional.bottomEnd,
                      minimumSize: const WidgetStatePropertyAll(Size(180, 0)),
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
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                    menuChildren: <String?>[
                      null,
                      ...fontProvider.availableFonts,
                    ].map((opt) {
                      final label = opt ?? 'Default';
                      final selected = fontProvider.selectedFont == opt;
                      return MenuItemButton(
                        onPressed: () {
                          fontProvider.changeFont(opt);
                          onFontChanged();
                        },
                        trailingIcon: selected
                            ? Icon(Icons.check, size: 18, color: colorPrimary)
                            : const SizedBox(width: 18),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            label,
                            style: (opt == null
                                    ? const TextStyle()
                                    : _getFontStyle(opt))
                                .copyWith(
                              fontSize: 14,
                              color: selected ? colorPrimary : colorTextStrong,
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
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          controller.isOpen
                              ? controller.close()
                              : controller.open();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  fontProvider.selectedFont ?? 'Default',
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
          ),
        ),
      ),
    );
  }
}
