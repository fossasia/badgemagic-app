import 'dart:io';

import 'package:badgemagic/others/converters.dart';
import 'package:badgemagic/others/file_helper.dart';
import 'package:badgemagic/others/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/view/widgets/draw_badge.dart';
import 'package:badgemagic/view/widgets/draw_shape_options_bar.dart';
import 'package:badgemagic/view/widgets/draw_tool_button.dart';
import 'package:badgemagic/view/widgets/save_clipart_name_dialog.dart';
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

  bool _isBadgeGridEmpty(List<List<int>> grid) {
    return grid.every((row) => row.every((cell) => cell == 0));
  }

  Future<void> _saveBadge(FileHelper fileHelper) async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    List<List<int>> badgeGrid = drawToggle
        .getDrawViewGrid()
        .map((e) => e.map((e) => e ? 1 : 0).toList())
        .toList();

    if (_isBadgeGridEmpty(badgeGrid)) {
      ToastUtils().showToast(l10n.pleaseSelectClipart);
      return;
    }

    List<String> hexString = Converters.convertBitmapToLEDHex(badgeGrid, false);

    if (widget.isSavedCard!) {
      await fileHelper.updateBadgeText(widget.filename!, hexString);
    } else if (widget.isSavedClipart!) {
      await fileHelper.updateClipart(widget.filename!, badgeGrid);
    } else {
      if (!mounted) return;
      String? customName = await showSaveClipartNameDialog(context);

      if (customName == null || customName.isEmpty) {
        return;
      }

      await fileHelper.saveImageWithName(
          drawToggle.getDrawViewGrid(), customName);
    }

    await fileHelper.generateClipartCache();
    ToastUtils().showToast(l10n.clipartSavedSuccessfully);
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
                      child: DrawToolButton(
                        icon: Icons.edit,
                        label: l10n.draw,
                        tint: drawToggle.isDrawing
                            ? colorPrimary
                            : colorOnSurface,
                        iconSize: iconSize,
                        fontSize: buttonTextSize,
                        onPressed: () => setState(() {
                          drawToggle.toggleIsDrawing(true);
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DrawToolButton(
                        iconAsset: 'assets/icons/eraser.svg',
                        label: l10n.erase,
                        tint: !drawToggle.isDrawing
                            ? colorPrimary
                            : colorOnSurface,
                        iconSize: iconSize,
                        fontSize: buttonTextSize,
                        onPressed: () => setState(() {
                          drawToggle.toggleIsDrawing(false);
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DrawToolButton(
                        icon: Icons.refresh,
                        label: l10n.reset,
                        tint: colorOnSurface,
                        iconSize: iconSize,
                        fontSize: buttonTextSize,
                        onPressed: () => setState(() {
                          drawToggle.resetDrawViewGrid();
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DrawToolButton(
                        icon: Icons.save,
                        label: l10n.save,
                        tint: colorOnSurface,
                        iconSize: iconSize,
                        fontSize: buttonTextSize,
                        onPressed: () => _saveBadge(fileHelper),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DrawToolButton(
                        icon: Icons.category,
                        label: 'Shapes',
                        tint: _showShapeOptions ? colorPrimary : colorOnSurface,
                        iconSize: iconSize,
                        fontSize: buttonTextSize,
                        onPressed: () => setState(() {
                          _showShapeOptions = !_showShapeOptions;
                          if (!_showShapeOptions) {
                            drawToggle.setShape(DrawShape.freehand);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: drawToggle,
                        builder: (context, _) {
                          final bool canUndo = drawToggle.canUndo;
                          return DrawToolButton(
                            icon: Icons.undo,
                            label: 'Undo',
                            tint: canUndo ? colorOnSurface : colorDisabled,
                            iconSize: iconSize,
                            fontSize: buttonTextSize,
                            onPressed: canUndo ? () => drawToggle.undo() : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: drawToggle,
                        builder: (context, _) {
                          final bool canRedo = drawToggle.canRedo;
                          return DrawToolButton(
                            icon: Icons.redo,
                            label: 'Redo',
                            tint: canRedo ? colorOnSurface : colorDisabled,
                            iconSize: iconSize,
                            fontSize: buttonTextSize,
                            onPressed: canRedo ? drawToggle.redo : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_showShapeOptions)
                DrawShapeOptionsBar(
                  selectedShape: drawToggle.selectedShape,
                  onSelect: (shape) => setState(() {
                    drawToggle.setShape(shape);
                  }),
                  iconSize: iconSize,
                  fontSize: buttonTextSize,
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
