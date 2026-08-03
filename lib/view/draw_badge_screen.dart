import 'dart:io';

import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

bool isDesktop =
    kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

class _DrawBadgeState extends State<DrawBadge> {
  var drawToggle = DrawBadgeProvider();
  bool _showShapeOptions = false;

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

  Future<String?> _showNameDialog() async {
    TextEditingController controller = TextEditingController();
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          titlePadding:
              const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 4),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          actionsPadding: const EdgeInsets.only(right: 8, bottom: 4, top: 0),
          title: Text(
            l10n.save,
            style: const TextStyle(fontSize: 16),
          ),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter clipart name',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(l10n.save),
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FileHelper fileHelper = FileHelper();
    final l10n = GetIt.instance.get<LocalizationService>().l10n;

    return CommonScaffold(
      index: 1,
      title: l10n.appTitle,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          double buttonTextSize = (width * 0.012).clamp(9.0, 14.0);
          double iconSize = (width * 0.025).clamp(18.0, 26.0);
          double buttonHeight = (width * 0.06).clamp(45.0, 65.0);

          return Column(
            key: const Key(drawBadgeScreen),
            children: [
              const SizedBox(height: 8),
              isDesktop
                  ? Expanded(
                      flex: 8,
                      child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: AspectRatio(
                                aspectRatio: 44 / 13,
                                child: BMBadge(
                                  providerInit: (provider) =>
                                      drawToggle = provider,
                                  badgeGrid: widget.badgeGrid
                                      ?.map(
                                          (e) => e.map((e) => e == 1).toList())
                                      .toList(),
                                ),
                              ),
                            ),
                          )))
                  : Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: BMBadge(
                          providerInit: (provider) => drawToggle = provider,
                          badgeGrid: widget.badgeGrid
                              ?.map((e) => e.map((e) => e == 1).toList())
                              .toList(),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: _buildCompactButton(true, Icons.edit, l10n.draw,
                            iconSize, buttonTextSize, buttonHeight)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildCompactButton(false, Icons.delete,
                            l10n.erase, iconSize, buttonTextSize, buttonHeight,
                            iconAsset: 'assets/icons/eraser.svg')),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildResetButton(
                            iconSize, buttonTextSize, buttonHeight)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildSaveButton(fileHelper, iconSize,
                            buttonTextSize, buttonHeight)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildShapesToggleButton(
                            iconSize, buttonTextSize, buttonHeight)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildUndoButton(
                            iconSize, buttonTextSize, buttonHeight)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildRedoButton(
                            iconSize, buttonTextSize, buttonHeight)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_showShapeOptions)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 40.w, vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Free',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.freehand,
                              Icons.gesture,
                              l10n.free,
                              iconSize * 0.9,
                              buttonTextSize * 0.9,
                              buttonHeight * 0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Square',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.square,
                              Icons.crop_square,
                              l10n.square,
                              iconSize * 0.9,
                              buttonTextSize * 0.9,
                              buttonHeight * 0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Rect',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.rectangle,
                              Icons.rectangle_outlined,
                              l10n.rectangle,
                              iconSize * 0.9,
                              buttonTextSize * 0.9,
                              buttonHeight * 0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Circle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.circle,
                              Icons.circle_outlined,
                              l10n.circle,
                              iconSize * 0.9,
                              buttonTextSize * 0.9,
                              buttonHeight * 0.9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Triangle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.triangle,
                              Icons.change_history,
                              l10n.triangle,
                              iconSize * 0.9,
                              buttonTextSize * 0.9,
                              buttonHeight * 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label,
      double iconSize, double fontSize, double height,
      {String? iconAsset}) {
    final isSelected = drawToggle.isDrawing == isDraw;
    final tint = isSelected ? colorPrimary : Colors.black;

    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.toggleIsDrawing(isDraw);
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconAsset != null
              ? SvgPicture.asset(
                  iconAsset,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                )
              : Icon(icon, color: tint, size: iconSize),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: tint, fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildResetButton(double iconSize, double fontSize, double height) {
    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.resetDrawViewGrid();
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, color: Colors.black, size: iconSize),
          const SizedBox(height: 4),
          Text(GetIt.instance.get<LocalizationService>().l10n.reset,
              style: TextStyle(color: Colors.black, fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  bool _isBadgeGridEmpty(List<List<int>> grid) {
    return grid.every((row) => row.every((cell) => cell == 0));
  }

  Widget _buildSaveButton(
      FileHelper fileHelper, double iconSize, double fontSize, double height) {
    return TextButton(
      onPressed: () async {
        List<List<int>> badgeGrid = drawToggle
            .getDrawViewGrid()
            .map((e) => e.map((e) => e ? 1 : 0).toList())
            .toList();

        if (_isBadgeGridEmpty(badgeGrid)) {
          ToastUtils().showToast(GetIt.instance
              .get<LocalizationService>()
              .l10n
              .pleaseSelectClipart);
          return;
        }

        List<String> hexString =
            Converters.convertBitmapToLEDHex(badgeGrid, false);

        if (widget.isSavedCard!) {
          await fileHelper.updateBadgeText(widget.filename!, hexString);
        } else if (widget.isSavedClipart!) {
          await fileHelper.updateClipart(widget.filename!, badgeGrid);
        } else {
          String? customName = await _showNameDialog();

          if (customName == null || customName.isEmpty) {
            return;
          }

          await fileHelper.saveImageWithName(
              drawToggle.getDrawViewGrid(), customName);
        }

        fileHelper.generateClipartCache();
        ToastUtils().showToast(GetIt.instance
            .get<LocalizationService>()
            .l10n
            .clipartSavedSuccessfully);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save, color: Colors.black, size: iconSize),
          const SizedBox(height: 4),
          Text(GetIt.instance.get<LocalizationService>().l10n.save,
              style: TextStyle(color: Colors.black, fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildShapesToggleButton(
      double iconSize, double fontSize, double height) {
    return TextButton(
      onPressed: () {
        setState(() {
          _showShapeOptions = !_showShapeOptions;

          // Reset to Freehand when hiding shape options
          if (!_showShapeOptions) {
            drawToggle.setShape(DrawShape.freehand);
          }
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category,
              color: _showShapeOptions ? colorPrimary : Colors.black,
              size: iconSize),
          const SizedBox(height: 4),
          Text('Shapes',
              style: TextStyle(
                  color: _showShapeOptions ? colorPrimary : Colors.black,
                  fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildUndoButton(double iconSize, double fontSize, double height) {
    return AnimatedBuilder(
      animation: drawToggle,
      builder: (context, _) {
        final bool canUndo = drawToggle.canUndo;
        final Color buttonColor = canUndo ? Colors.black : Colors.grey;

        return TextButton(
          onPressed: canUndo ? () => drawToggle.undo() : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            minimumSize: const Size(60, 40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.undo, color: buttonColor, size: iconSize),
              const SizedBox(height: 4),
              Text('Undo',
                  style: TextStyle(color: buttonColor, fontSize: fontSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedoButton(double iconSize, double fontSize, double height) {
    return AnimatedBuilder(
      animation: drawToggle,
      builder: (context, _) {
        final bool canRedo = drawToggle.canRedo;
        final Color buttonColor = canRedo ? Colors.black : Colors.grey;

        return TextButton(
          onPressed: canRedo ? drawToggle.redo : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            minimumSize: const Size(60, 40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.redo, color: buttonColor, size: iconSize),
              const SizedBox(height: 4),
              Text('Redo',
                  style: TextStyle(color: buttonColor, fontSize: fontSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactShapeCard(
      BuildContext context,
      DrawShape shape,
      IconData icon,
      String label,
      double iconSize,
      double fontSize,
      double height) {
    final isSelected = drawToggle.selectedShape == shape;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          drawToggle.setShape(shape);
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black,
        backgroundColor: isSelected ? colorPrimary : Colors.white,
        elevation: isSelected ? 2 : 1,
        side:
            BorderSide(color: isSelected ? colorPrimary : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        minimumSize: const Size(55, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
