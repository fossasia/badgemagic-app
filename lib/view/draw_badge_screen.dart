import 'package:badgemagic/bademagic_module/utils/byte_array_utils.dart';
import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
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
  late DrawBadgeProvider drawToggle;

  @override
  void initState() {
    super.initState();
    drawToggle = DrawBadgeProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
    });
  }

  @override
  void dispose() {
    _resetPortraitOrientation();
    super.dispose();
  }

  Future<void> _resetPortraitOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      logger.e('Error setting portrait orientation', error: e);
    }
  }

  Future<void> _setLandscapeOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } catch (e) {
      logger.e('Error setting landscape orientation', error: e);
    }
  }

  Future<void> _saveImage() async {
    try {
      List<List<int>> badgeGrid = drawToggle
          .getDrawViewGrid()
          .map((e) => e.map((e) => e ? 1 : 0).toList())
          .toList();
      List<String> hexString =
          Converters.convertBitmapToLEDHex(badgeGrid, false);

      if (widget.isSavedCard == true) {
        await FileHelper().updateBadgeText(
          widget.filename ?? '',
          hexString,
        );
      } else if (widget.isSavedClipart == true) {
        await FileHelper().updateClipart(
          widget.filename ?? '',
          badgeGrid,
        );
      } else {
        await FileHelper().saveImage(drawToggle.getDrawViewGrid());
      }

      await FileHelper().generateClipartCache();
      ToastUtils().showToast("Clipart Saved Successfully");
    } catch (e) {
      logger.e('Error saving image', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _resetPortraitOrientation();
        }
      },
      child: CommonScaffold(
        index: 1,
        title: 'BadgeMagic',
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
                                'Draw',
                                style: TextStyle(
                                  color: drawToggle.getIsDrawing()
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
                                color: drawToggle.getIsDrawing()
                                    ? Colors.black
                                    : colorPrimary,
                              ),
                              Text(
                                'Erase',
                                style: TextStyle(
                                  color: drawToggle.getIsDrawing()
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
                          child: const Column(
                            children: [
                              Icon(Icons.refresh, color: Colors.black),
                              Text('Reset',
                                  style: TextStyle(color: Colors.black))
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _saveImage();
                          },
                          child: const Column(
                            children: [
                              Icon(Icons.save, color: Colors.black),
                              Text('Save',
                                  style: TextStyle(color: Colors.black))
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
