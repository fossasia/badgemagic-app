import 'package:badgemagic/others/byte_array_utils.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/others/image_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/inline_image_provider.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:badgemagic/view/widgets/clipart_list_view.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';

class SavedClipartScreen extends StatefulWidget {
  const SavedClipartScreen({super.key});

  @override
  State<SavedClipartScreen> createState() => _SavedClipartScreenState();
}

class _SavedClipartScreenState extends State<SavedClipartScreen> {
  InlineImageProvider imageprovider = GetIt.instance<InlineImageProvider>();
  FileHelper file = FileHelper();
  final ImageUtils _imageUtils = ImageUtils();
  final ToastUtils _toastUtils = ToastUtils();

  @override
  void initState() {
    _setOrientation();
    super.initState();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Object? _cacheKeyForFileName(String fileName) {
    for (final key in imageprovider.imageCache.keys) {
      if (key is List && key.isNotEmpty && key[0].toString() == fileName) {
        return key;
      }
    }
    return null;
  }

  Future<void> _addClipartToBadge(String fileName) async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    Object? cacheKey = _cacheKeyForFileName(fileName);

    if (cacheKey == null) {
      final imageData = imageprovider.clipartsCache[fileName];
      if (imageData != null) {
        final bytes = await _imageUtils.convert2DListToUint8List(imageData);
        file.addToCache(bytes, fileName);
        cacheKey = _cacheKeyForFileName(fileName);
      }
    }

    if (cacheKey == null) {
      _toastUtils.showErrorToast(l10n.couldNotAddClipartToBadge);
      return;
    }

    imageprovider.insertInlineImage(cacheKey);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return CommonScaffold(
      index: 3,
      key: const Key(savedClipartScreen),
      title: l10n.savedClipartTitle,
      actions: [
        TextButton(
          onPressed: () async {
            bool success = await file.importClipart(context);
            if (success) {
              setState(() {});
            }
          },
          child: Text(
            l10n.import,
            style: const TextStyle(color: drawerHeaderTitle),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/drawBadge');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.create,
            style: const TextStyle(color: drawerHeaderTitle),
          ),
        ),
      ],
      body: imageprovider.clipartsCache.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 50.0.w),
                    child: SvgPicture.asset(
                      'assets/icons/empty_badge.svg',
                      height: 200.h,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    l10n.noSavedClipart,
                    style: TextStyle(
                      color: colorOnSurface,
                      fontSize: 20.sp,
                    ),
                  ),
                  Text(
                    l10n.noSavedClipartMessage,
                    style: TextStyle(
                      color: colorOnSurface,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            )
          : SavedClipartListView(
              images: imageprovider.clipartsCache,
              refreshClipartCallback: (String fileName) async {
                imageprovider.clipartsCache.remove(fileName);
                imageprovider.removeFromCache(fileName);

                setState(() {
                  logger.i('Clipart $fileName deleted');
                });
              },
              onClipartSelected: _addClipartToBadge,
            ),
    );
  }
}
