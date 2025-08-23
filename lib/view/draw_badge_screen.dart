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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              key: const Key(drawBadgeScreen),
              children: [
                const SizedBox(height: 8),

                // Badge takes most of the available space
                Expanded(
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

                const SizedBox(height: 8),

                // Control buttons - compact layout with closer spacing
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main action buttons - centered and closer together
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCompactButton(true, Icons.edit,
                              AppLocalizations.of(context)!.draw),
                          const SizedBox(width: 8),
                          _buildCompactButton(false, Icons.delete,
                              AppLocalizations.of(context)!.erase),
                          const SizedBox(width: 8),
                          _buildResetButton(),
                          const SizedBox(width: 8),
                          _buildSaveButton(fileHelper),
                          const SizedBox(width: 8),
                          _buildShapesToggleButton(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Shape options - only show when toggled, fixed height
                if (_showShapeOptions)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Free',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.freehand,
                              Icons.gesture,
                              AppLocalizations.of(context)!.free),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          label: 'Square',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.square,
                              Icons.crop_square,
                              AppLocalizations.of(context)!.square),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          label: 'Rect',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.rectangle,
                              Icons.rectangle_outlined,
                              AppLocalizations.of(context)!.rectangle),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          label: 'Circle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.circle,
                              Icons.circle_outlined,
                              AppLocalizations.of(context)!.circle),
                        ),
                        const SizedBox(width: 6),
                        Semantics(
                          label: 'Triangle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.triangle,
                              Icons.change_history,
                              AppLocalizations.of(context)!.triangle),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label) {
    final isSelected = drawToggle.isDrawing == isDraw;

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
        children: [
          Icon(icon, color: isSelected ? colorPrimary : Colors.black, size: 20),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: isSelected ? colorPrimary : Colors.black,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
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
        children: [
          const Icon(Icons.refresh, color: Colors.black, size: 20),
          const SizedBox(height: 2),
          Text(AppLocalizations.of(context)!.reset,
              style: const TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(FileHelper fileHelper) {
    return TextButton(
      onPressed: () {
        List<List<int>> badgeGrid = drawToggle
            .getDrawViewGrid()
            .map((e) => e.map((e) => e ? 1 : 0).toList())
            .toList();
        List<String> hexString =
            Converters.convertBitmapToLEDHex(badgeGrid, false);

        if (widget.isSavedCard!) {
          fileHelper.updateBadgeText(widget.filename!, hexString);
        } else if (widget.isSavedClipart!) {
          fileHelper.updateClipart(widget.filename!, badgeGrid);
        } else {
          fileHelper.saveImage(drawToggle.getDrawViewGrid());
        }

        fileHelper.generateClipartCache();
        ToastUtils()
            .showToast(AppLocalizations.of(context)!.clipartSavedSuccessfully);

        Future.delayed(const Duration(milliseconds: 800), () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.save, color: Colors.black, size: 20),
          const SizedBox(height: 2),
          Text(AppLocalizations.of(context)!.save,
              style: const TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildShapesToggleButton() {
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
        children: [
          Icon(Icons.category,
              color: _showShapeOptions ? colorPrimary : Colors.black, size: 20),
          const SizedBox(height: 2),
          Text('Shapes', // Using hardcoded string for semantic label
              style: TextStyle(
                  color: _showShapeOptions ? colorPrimary : Colors.black,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCompactShapeCard(
      BuildContext context, DrawShape shape, IconData icon, String label) {
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
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
