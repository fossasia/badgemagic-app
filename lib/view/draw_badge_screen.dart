import 'package:badgemagic/bademagic_module/utils/converters.dart';
import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badgemagic/utils/custom_transfers/layout_config.dart';

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
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final layout = useLayoutConfig(context);

    return WillPopScope(
      onWillPop: () async {
        _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: l10n.appTitle,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              key: const Key(drawBadgeScreen),
              children: [
                SizedBox(height: layout.spacing),

                // Badge takes most of the available space
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: layout.padding),
                    child: BMBadge(
                      providerInit: (provider) => drawToggle = provider,
                      badgeGrid: widget.badgeGrid
                          ?.map((e) => e.map((e) => e == 1).toList())
                          .toList(),
                    ),
                  ),
                ),

                SizedBox(height: layout.spacing),

                // Control buttons - compact layout with closer spacing
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                              child: _buildCompactButton(
                                  true, Icons.edit, l10n.draw,layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(
                              child: _buildCompactButton(
                                  false, Icons.delete, l10n.erase,layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(child: _buildResetButton(layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(child: _buildSaveButton(fileHelper,layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(child: _buildShapesToggleButton(layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(child: _buildUndoButton(layout)),
                          SizedBox(width: layout.spacing / 4),
                          Flexible(child: _buildRedoButton(layout)),
                        ],
                      ),
                      SizedBox(height: layout.spacing),
                    ],
                  ),
                )),
                // Shape options - only show when toggled, fixed height
                if (_showShapeOptions)
                  Container(
                    height: layout.iconSize * 2.5,
                    padding: EdgeInsets.symmetric(horizontal: layout.padding),
                    child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Free',
                          child: _buildCompactShapeCard(context,
                              DrawShape.freehand, Icons.gesture, l10n.free,layout),
                        ),
                        SizedBox(height: layout.spacing / 4),
                        Semantics(
                          label: 'Square',
                          child: _buildCompactShapeCard(context,
                              DrawShape.square, Icons.crop_square, l10n.square,layout),
                        ),
                        SizedBox(height: layout.spacing / 4),
                        Semantics(
                          label: 'Rect',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.rectangle,
                              Icons.rectangle_outlined,
                              l10n.rectangle,layout),
                        ),
                        SizedBox(height: layout.spacing / 4),
                        Semantics(
                          label: 'Circle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.circle,
                              Icons.circle_outlined,
                              l10n.circle,layout),
                        ),
                        SizedBox(height: layout.spacing / 4),
                        Semantics(
                          label: 'Triangle',
                          child: _buildCompactShapeCard(
                              context,
                              DrawShape.triangle,
                              Icons.change_history,
                              l10n.triangle,layout),
                        ),
                      ],
                    ),
                  )),

                SizedBox(height: layout.spacing),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label,LayoutConfig layout) {
    final isSelected = drawToggle.isDrawing == isDraw;

    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.toggleIsDrawing(isDraw);
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
        minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? colorPrimary : Colors.black, size: layout.iconSize),
          SizedBox(height: layout.spacing / 4),
          Text(label,
              style: TextStyle(
                  color: isSelected ? colorPrimary : Colors.black,
                  fontSize: 10 * layout.fontScale,)),
        ],
      ),
    );
  }

  Widget _buildResetButton(LayoutConfig layout) {
    return TextButton(
      onPressed: () {
        setState(() {
          drawToggle.resetDrawViewGrid();
        });
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
        minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, size: layout.iconSize),
          SizedBox(height: layout.spacing / 4),
          Text(GetIt.instance.get<LocalizationService>().l10n.reset,
              style: TextStyle(color: Colors.black, fontSize: 10 * layout.fontScale)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(FileHelper fileHelper,LayoutConfig layout) {
    return TextButton(
      onPressed: () async {
        List<List<int>> badgeGrid = drawToggle
            .getDrawViewGrid()
            .map((e) => e.map((e) => e ? 1 : 0).toList())
            .toList();
        List<String> hexString =
            Converters.convertBitmapToLEDHex(badgeGrid, false);

        if (widget.isSavedCard!) {
          await fileHelper.updateBadgeText(widget.filename!, hexString);
        } else if (widget.isSavedClipart!) {
          await fileHelper.updateClipart(widget.filename!, badgeGrid);
        } else {
          await fileHelper.saveImage(drawToggle.getDrawViewGrid());
        }

        fileHelper.generateClipartCache();
        ToastUtils().showToast(GetIt.instance
            .get<LocalizationService>()
            .l10n
            .clipartSavedSuccessfully);

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
        minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save, size: layout.iconSize),
          SizedBox(height: layout.spacing / 4),
          Text(GetIt.instance.get<LocalizationService>().l10n.save,
              style: TextStyle(color: Colors.black, fontSize: 10 * layout.fontScale)),
        ],
      ),
    );
  }

  Widget _buildShapesToggleButton(LayoutConfig layout) {
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
        padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
        minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category,
              color: _showShapeOptions ? colorPrimary : Colors.black, size: layout.iconSize,),
          SizedBox(height: layout.spacing / 4),
          Text('Shapes', // Using hardcoded string for semantic label
              style: TextStyle(
                  color: _showShapeOptions ? colorPrimary : Colors.black,
                  fontSize: 10 * layout.fontScale)),
        ],
      ),
    );
  }

  Widget _buildUndoButton(LayoutConfig layout) {
    return AnimatedBuilder(
      animation: drawToggle,
      builder: (context, _) {
        final bool canUndo = drawToggle.canUndo;
        final Color buttonColor = canUndo ? Colors.black : Colors.grey;

        return TextButton(
          onPressed: canUndo
              ? () {
                  drawToggle.undo();
                }
              : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
            minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo, color: buttonColor, size: layout.iconSize,),
              SizedBox(height: layout.spacing / 4),
              Text('Undo', style: TextStyle(color: buttonColor, fontSize: 10 * layout.fontScale)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRedoButton(LayoutConfig layout) {
    return AnimatedBuilder(
      animation: drawToggle,
      builder: (context, _) {
        final bool canRedo = drawToggle.canRedo;
        final Color buttonColor = canRedo ? Colors.black : Colors.grey;

        return TextButton(
          onPressed: canRedo ? drawToggle.redo : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding),
            minimumSize: Size(layout.iconSize * 2.5, layout.iconSize * 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.redo, color: buttonColor, size: layout.iconSize),
              SizedBox(height: layout.spacing / 4),
              Text('Redo', style: TextStyle(color: buttonColor, fontSize: 10 * layout.fontScale)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactShapeCard(
      BuildContext context, DrawShape shape, IconData icon, String label, LayoutConfig layout) {
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
        padding: EdgeInsets.symmetric(vertical: layout.spacing / 2, horizontal: layout.padding / 2),
        minimumSize: Size(layout.iconSize * 2.3, layout.iconSize * 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: layout.iconSize * 0.9),
          SizedBox(height: layout.spacing / 4),
          Text(label,
              style: TextStyle(fontSize: 9 * layout.fontScale),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
