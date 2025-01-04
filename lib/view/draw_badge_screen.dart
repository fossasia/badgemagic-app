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
  const DrawBadge(
      {super.key,
      this.filename,
      this.isSavedCard = false,
      this.isSavedClipart = false,
      this.badgeGrid});

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
    super.dispose();
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    FileHelper fileHelper = FileHelper();
    return CommonScaffold(
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
                      SizedBox(
                        width: 100,
                      ),
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
                                  ? Colors.red
                                  : Colors.black,
                            ),
                            Text(
                              'Draw',
                              style: TextStyle(
                                color: drawToggle.isDrawing
                                    ? Colors.red
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
                                  : Colors.red,
                            ),
                            Text(
                              'Erase',
                              style: TextStyle(
                                color: drawToggle.isDrawing
                                    ? Colors.black
                                    : Colors.red,
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
                            Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                            Text(
                              'Reset',
                              style: TextStyle(color: Colors.black),
                            )
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          List<List<int>> badgeGrid = drawToggle
                              .getDrawViewGrid()
                              .map((e) => e.map((e) => e ? 1 : 0).toList())
                              .toList();
                          List<String> hexString =
                              Converters.convertBitmapToLEDHex(
                                  badgeGrid, false);
                          widget.isSavedCard!
                              ? fileHelper.updateBadgeText(
                                  widget.filename!,
                                  hexString,
                                )
                              : widget.isSavedClipart!
                                  ? fileHelper.updateClipart(
                                      widget.filename!, badgeGrid)
                                  : fileHelper
                                      .saveImage(drawToggle.getDrawViewGrid());
                          fileHelper.generateClipartCache();
                          ToastUtils().showToast("Clipart Saved Successfully");
                        },
                        child: const Column(
                          children: [
                            Icon(
                              Icons.save,
                              color: Colors.black,
                            ),
                            Text('Save', style: TextStyle(color: Colors.black))
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
    );
  }
}
