import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/bademagic_module/utils/toast_utils.dart';
import 'package:badgemagic/providers/draw_badge_provider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:badgemagic/virtualbadge/view/draw_badge.dart' as vb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:badgemagic/providers/animation_badge_provider.dart';
import 'package:badgemagic/virtualbadge/view/animated_badge.dart';

class CreateFramesScreen extends StatefulWidget {
  const CreateFramesScreen({super.key});

  @override
  State<CreateFramesScreen> createState() => _CreateFramesScreenState();
}

class _CreateFramesScreenState extends State<CreateFramesScreen> {
  DrawBadgeProvider? _drawProvider;
  final int _rows = 11;
  final int _cols = 44;
  final int _totalFrames = 8;
  int _currentFrame = 0;
  final FileHelper _fileHelper = FileHelper();
  final List<List<List<bool>>> _history = [];
  int _historyIndex = -1;
  late List<List<List<int>>> _frames;

  @override
  void initState() {
    super.initState();
    _frames = List.generate(_totalFrames,
        (_) => List.generate(_rows, (_) => List.filled(_cols, 0)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setLandscapeOrientation();
  }

  @override
  void dispose() {
    _resetPortraitOrientation();
    if (_drawProvider != null) {
      _drawProvider!.removeListener(_onProviderChanged);
    }
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

  void _onProviderInit(DrawBadgeProvider provider) {
    _drawProvider = provider;
    _drawProvider!.setShape(DrawShape.freehand);
    _applyFrameToProvider(_currentFrame);
    _pushHistorySnapshot(_drawProvider!.getDrawViewGrid());
    _drawProvider!.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    final provider = _drawProvider;
    if (provider == null) return;
    final current = provider.getDrawViewGrid();
    _pushHistorySnapshot(current);
    if (mounted) setState(() {});
  }

  void _pushHistorySnapshot(List<List<bool>> grid) {
    if (_historyIndex >= 0) {
      final last = _history[_historyIndex];
      if (_gridsEqual(last, grid)) return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_cloneGrid(grid));
    _historyIndex = _history.length - 1;
  }

  bool _gridsEqual(List<List<bool>> a, List<List<bool>> b) {
    if (a.length != b.length || a[0].length != b[0].length) return false;
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }

  List<List<bool>> _cloneGrid(List<List<bool>> src) {
    return List.generate(src.length, (i) => List<bool>.from(src[i]));
  }

  List<List<bool>> _currentProviderGrid() {
    if (_drawProvider == null) {
      return List.generate(_rows, (_) => List<bool>.filled(_cols, false));
    }
    return _drawProvider!.getDrawViewGrid();
  }

  void _applyFrameToProvider(int frameIndex) {
    if (_drawProvider == null) return;
    final data = _frames[frameIndex];
    _drawProvider!.resetDrawViewGrid();
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (data[r][c] == 1) {
          _drawProvider!.setCell(r, c, true, preview: false);
        }
      }
    }
    _drawProvider!.commitGridUpdate();
    _history.clear();
    _historyIndex = -1;
    _pushHistorySnapshot(_drawProvider!.getDrawViewGrid());
  }

  void _storeProviderIntoFrame(int frameIndex) {
    final grid = _currentProviderGrid();
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        _frames[frameIndex][r][c] = grid[r][c] ? 1 : 0;
      }
    }
  }

  void _nextFrame() {
    _storeProviderIntoFrame(_currentFrame);
    setState(() {
      _currentFrame = (_currentFrame + 1).clamp(0, _totalFrames - 1);
    });
    _applyFrameToProvider(_currentFrame);
  }

  void _prevFrame() {
    _storeProviderIntoFrame(_currentFrame);
    setState(() {
      _currentFrame = (_currentFrame - 1).clamp(0, _totalFrames - 1);
    });
    _applyFrameToProvider(_currentFrame);
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _drawProvider?.updateDrawViewGrid(_history[_historyIndex]);
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _drawProvider?.updateDrawViewGrid(_history[_historyIndex]);
    }
  }

  Future<void> _saveFrames() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _storeProviderIntoFrame(_currentFrame);

    int selectedSpeed = 1;
    final nameController = TextEditingController();
    final height = _frames.first.length;
    final width = _frames.first.first.length;
    final stitched = List.generate(
        height, (_) => List<bool>.filled(width * _frames.length, false));
    for (int fi = 0; fi < _frames.length; fi++) {
      for (int r = 0; r < height; r++) {
        for (int c = 0; c < width; c++) {
          stitched[r][fi * width + c] = _frames[fi][r][c] == 1;
        }
      }
    }

    final previewProvider = AnimationBadgeProvider();
    previewProvider.setNewGrid(stitched);
    previewProvider.calculateDuration(selectedSpeed);
    previewProvider.setAnimationMode(animationMap[0]);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Save Frames'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Animation name',
                        hintText: 'e.g. MyAnimation',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Speed'),
                    DropdownButton<int>(
                      isExpanded: true,
                      value: selectedSpeed,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 - Slowest')),
                        DropdownMenuItem(value: 2, child: Text('2')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 4, child: Text('4')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 6, child: Text('6')),
                        DropdownMenuItem(value: 7, child: Text('7')),
                        DropdownMenuItem(value: 8, child: Text('8 - Fastest')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => selectedSpeed = v);
                          previewProvider.calculateDuration(v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ChangeNotifierProvider.value(
                        value: previewProvider,
                        child: const AnimationBadge(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    if (name == null || name.isEmpty) return;

    await _fileHelper.saveFrameAnimationWithName(name, _frames, selectedSpeed);
    ToastUtils().showToast("Frames saved");
  }

  bool _isCurrentFrameEmpty() {
    final grid = _drawProvider?.getDrawViewGrid();
    if (grid == null) return true;
    for (var row in grid) {
      for (var cell in row) {
        if (cell) return false;
      }
    }
    return true;
  }

  Widget _buildCompactButton(bool isDraw, IconData icon, String label) {
    final isSelected = (_drawProvider?.getIsDrawing() ?? true) == isDraw;
    return TextButton(
      onPressed: _drawProvider == null
          ? null
          : () {
              setState(() {
                _drawProvider!.toggleIsDrawing(isDraw);
              });
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.black, size: 20),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return TextButton(
      onPressed: _drawProvider == null
          ? null
          : () {
              setState(() {
                _drawProvider!.resetDrawViewGrid();
              });
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, color: Colors.black, size: 20),
          SizedBox(height: 2),
          Text('Reset', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildUndoButton() {
    return TextButton(
      onPressed: _drawProvider == null ? null : _undo,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo, color: Colors.black, size: 20),
          SizedBox(height: 2),
          Text('Undo', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRedoButton() {
    return TextButton(
      onPressed: _drawProvider == null ? null : _redo,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.redo, color: Colors.black, size: 20),
          SizedBox(height: 2),
          Text('Redo', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return TextButton(
      onPressed: _currentFrame == _totalFrames - 1 ? _saveFrames : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save, color: Colors.black, size: 20),
          SizedBox(height: 2),
          Text('Save', style: TextStyle(color: Colors.black, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _resetPortraitOrientation();
        return true;
      },
      child: CommonScaffold(
        index: 1,
        title: 'Create Frames',
        body: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _prevFrame,
                      icon: const Icon(Icons.chevron_left),
                      color: Colors.grey,
                      iconSize: 28,
                    ),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 3.2,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            vb.BMBadge(
                              providerInit: _onProviderInit,
                            ),
                            if (_isCurrentFrameEmpty())
                              IgnorePointer(
                                ignoring: true,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Frame ${_currentFrame + 1}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _nextFrame,
                      icon: const Icon(Icons.chevron_right),
                      color: Colors.grey,
                      iconSize: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildCompactButton(true, Icons.edit, 'Draw'),
                  _buildCompactButton(false, Icons.delete, 'Erase'),
                  _buildResetButton(),
                  _buildUndoButton(),
                  _buildRedoButton(),
                  _buildSaveButton(),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
