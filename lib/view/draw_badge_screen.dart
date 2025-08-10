import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/l10n/app_localizations.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawBadge extends StatefulWidget {
  final String? filename;
  final bool? isSavedCard;
  final bool? isSavedClipart;
  final List<List<int>>? badgeGrid;
  const DrawBadge({
    super.key,
    this.filename,
    this.isSavedCard = false,
    this.isSavedClipart = false,
    this.badgeGrid,
  });

  @override
  State<DrawBadge> createState() => _DrawBadgeState();
}

class _DrawBadgeState extends State<DrawBadge> {
  var drawToggle = DrawBadgeProvider();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLandscapeOrientation();
  }

  @override
  void dispose() {
    _resetPortraitOrientation();
    super.dispose();
  }

  void _resetPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    FileHelper fileHelper = FileHelper();
    return WillPopScope(
      onWillPop: () async {
        _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: AppLocalizations.of(context)!.appTitle,
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          key: const Key(drawBadgeScreen),
          child: Align(
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.94,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const SizedBox(width: 100),
                        BMBadge(
                          providerInit: (provider) => drawToggle = provider,
                          badgeGrid: widget.badgeGrid
                              ?.map((e) => e.map((e) => e == 1).toList())
                              .toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.toggleIsDrawing(true);
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.edit,
                                color: drawToggle.getIsDrawing()
                                    ? colorPrimary
                                    : Colors.black,
                              ),
                              Text(
                                AppLocalizations.of(context)!.draw,
                                style: TextStyle(
                                  color: drawToggle.isDrawing
                                      ? colorPrimary
                                      : Colors.black,
                                ),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.toggleIsDrawing(false);
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                Icons.delete,
                                color: drawToggle.isDrawing
                                    ? Colors.black
                                    : colorPrimary,
                              ),
                              Text(
                                AppLocalizations.of(context)!.erase,
                                style: TextStyle(
                                  color: drawToggle.isDrawing
                                      ? Colors.black
                                      : colorPrimary,
                                ),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              drawToggle.resetDrawViewGrid();
                            });
                          },
                          child: Column(
                            children: [
                              const Icon(
                                Icons.refresh,
                                color: Colors.black,
                              ),
                              Text(
                                AppLocalizations.of(context)!.reset,
                                style: const TextStyle(color: Colors.black),
                              )
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              List<List<int>> badgeGrid = drawToggle
                                  .getDrawViewGrid()
                                  .map((e) => e.map((e) => e ? 1 : 0).toList())
                                  .toList();
                              List<String> hexString =
                                  Converters.convertBitmapToLEDHex(
                                      badgeGrid, false);

                              if (widget.isSavedCard!) {
                                await fileHelper.updateBadgeText(
                                    widget.filename!, hexString);
                              } else if (widget.isSavedClipart!) {
                                await fileHelper.updateClipart(
                                    widget.filename!, badgeGrid);
                              } else {
                                await fileHelper
                                    .saveImage(drawToggle.getDrawViewGrid());
                              }

                              await fileHelper.generateClipartCache();

                              ToastUtils().showToast(
                                  AppLocalizations.of(context)!
                                      .clipartSavedSuccessfully);

                              await Future.delayed(
                                  const Duration(milliseconds: 800));

                              if (mounted) {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            } catch (e) {
                              ToastUtils().showToast(
                                  "${AppLocalizations.of(context)!.failedToSaveBadge}: ${e.toString()}");
                            }
                          },
                          child: Column(
                            children: [
                              const Icon(
                                Icons.save,
                                color: Colors.black,
                              ),
                              Text(
                                AppLocalizations.of(context)!.save,
                                style: const TextStyle(color: Colors.black),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
