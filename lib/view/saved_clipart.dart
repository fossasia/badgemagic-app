import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/view/widgets/clipart_list_view.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/utils/custom_transfers/layout_config.dart';

class SavedClipart extends StatefulWidget {
  const SavedClipart({super.key});

  @override
  State<SavedClipart> createState() => _SavedClipartState();
}

class _SavedClipartState extends State<SavedClipart> {
  InlineImageProvider imageprovider = GetIt.instance<InlineImageProvider>();
  FileHelper file = FileHelper();

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

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final layout = useLayoutConfig(context);
    return CommonScaffold(
      index: 3,
      key: const Key(savedClipartScreen),
      title: l10n.savedClipartTitle,
      body: imageprovider.clipartsCache.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: layout.padding * 3),
                    child: SvgPicture.asset(
                      'assets/icons/empty_badge.svg',
                      height: layout.iconSize * 8,
                    ),
                  ),
                  SizedBox(height: layout.spacing * 2),
                  Text(l10n.noSavedClipart,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20 * layout.fontScale,
                      )),
                  Text(l10n.noSavedClipartMessage,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14 * layout.fontScale,
                      )),
                ],
              ),
            )
          : SavedClipartListView(
              images: imageprovider.clipartsCache,
              refreshClipartCallback: (String fileName) async {
                imageprovider.clipartsCache.remove(fileName);
                setState(() {
                  logger.i('Clipart $fileName deleted');
                });
                imageprovider.removeFromCache(fileName);
                imageprovider.generateImageCache();
              },
            ), // Use the separate ListView widget here
    );
  }
}
