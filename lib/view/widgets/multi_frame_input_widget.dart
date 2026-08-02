import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// A multi-frame text input widget shown when the "Animation" (Splitting)
/// transition is selected. Each frame corresponds to one 44-pixel screen on
/// the physical badge, displayed like a flipbook editor.
class MultiFrameInputWidget extends StatefulWidget {
  /// The global [TextEditingController] shared with the rest of the homescreen
  /// (badge preview, save, transfer). This widget reads from and writes back
  /// to it using `\f` as the frame delimiter.
  final TextEditingController globalController;

  /// Called whenever the combined frame content changes so the caller can
  /// trigger a live badge preview update.
  final VoidCallback onChanged;

  const MultiFrameInputWidget({
    super.key,
    required this.globalController,
    required this.onChanged,
  });

  @override
  State<MultiFrameInputWidget> createState() => _MultiFrameInputWidgetState();
}

class _MultiFrameInputWidgetState extends State<MultiFrameInputWidget> {
  /// One controller per frame.
  final List<TextEditingController> _frameControllers = [];

  /// One focus node per frame — used to track which frame is active for
  /// clipart insertion.
  final List<FocusNode> _focusNodes = [];

  /// Prevents re-entrant updates when we write back to [widget.globalController].
  bool _updatingGlobal = false;

  @override
  void initState() {
    super.initState();
    _initFramesFromGlobal();
    // Keep in sync if the global controller is changed externally (e.g. loading
    // a saved badge).
    widget.globalController.addListener(_onGlobalChanged);
  }

  /// Splits the global controller's text on `\f` and creates a controller +
  /// focus node for every frame. Always ensures at least one frame.
  void _initFramesFromGlobal() {
    final parts = widget.globalController.text.split('\f');
    for (final part in parts.isEmpty ? [''] : parts) {
      _addFrame(initialText: part);
    }
    if (_frameControllers.isEmpty) _addFrame();
  }

  void _addFrame({String initialText = ''}) {
    final ctrl = TextEditingController(text: initialText);
    final fn = FocusNode();

    ctrl.addListener(_onFrameChanged);
    fn.addListener(() {
      if (fn.hasFocus) {
        // Tell the ImageProvider which frame is active so clipart lands here.
        final imageProvider =
            context.read<InlineImageProvider>();
        imageProvider.activeFrameController = ctrl;
      }
    });

    _frameControllers.add(ctrl);
    _focusNodes.add(fn);
  }

  /// Reads from frame controllers, joins with `\f`, and writes to the global
  /// controller so the preview and save/transfer logic stay in sync.
  void _onFrameChanged() {
    if (_updatingGlobal) return;
    _updatingGlobal = true;
    final joined = _frameControllers.map((c) => c.text).join('\f');
    widget.globalController.text = joined;
    _updatingGlobal = false;
    widget.onChanged();
  }

  /// Handles external writes to the global controller (e.g. loading a badge).
  void _onGlobalChanged() {
    if (_updatingGlobal) return;
    final parts = widget.globalController.text.split('\f');
    if (parts.length != _frameControllers.length) {
      // Frame count changed externally — rebuild.
      _disposeFrames();
      for (final part in parts) {
        _addFrame(initialText: part);
      }
      if (mounted) setState(() {});
    } else {
      // Just update text without triggering _onFrameChanged loop.
      _updatingGlobal = true;
      for (int i = 0; i < parts.length; i++) {
        if (_frameControllers[i].text != parts[i]) {
          _frameControllers[i].text = parts[i];
        }
      }
      _updatingGlobal = false;
    }
  }

  void _disposeFrames() {
    for (final c in _frameControllers) {
      c.removeListener(_onFrameChanged);
      c.dispose();
    }
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    _frameControllers.clear();
    _focusNodes.clear();
  }

  void _addNewFrame() {
    setState(() {
      _addFrame();
    });
    _onFrameChanged();
    // Auto-focus the new frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.last.requestFocus();
    });
  }

  void _deleteFrame(int index) {
    if (_frameControllers.length <= 1) return; // Keep at least one frame.
    _frameControllers[index].removeListener(_onFrameChanged);
    _frameControllers[index].dispose();
    _focusNodes[index].dispose();
    setState(() {
      _frameControllers.removeAt(index);
      _focusNodes.removeAt(index);
    });
    _onFrameChanged();
  }

  @override
  void dispose() {
    widget.globalController.removeListener(_onGlobalChanged);
    // Clear the active frame ref in provider if we're being torn down.
    final imageProvider = context.read<InlineImageProvider>();
    if (_frameControllers.contains(imageProvider.activeFrameController)) {
      imageProvider.activeFrameController = null;
    }
    _disposeFrames();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal frame list and add button separated
        SizedBox(
          height: 64.h,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    itemCount: _frameControllers.length,
                    itemBuilder: (context, index) =>
                        _buildFrameCard(index),
                  ),
                ),
              ),
              // Add frame button (separate boundary)
              GestureDetector(
                onTap: _addNewFrame,
                child: Container(
                  width: 44.w,
                  height: 64.h,
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: Icon(Icons.add, color: colorPrimary, size: 22.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrameCard(int index) {
    final isOnly = _frameControllers.length == 1;
    final hasFocus = _focusNodes[index].hasFocus;
    return Container(
      width: 140.w,
      height: 56.h,
      margin: EdgeInsets.only(right: 8.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: hasFocus
              ? colorPrimary
              : Colors.grey.shade300,
          width: hasFocus ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Frame number badge
          Positioned(
            top: 2.h,
            left: 6.w,
            child: Text(
              'Frame ${index + 1}',
              style: TextStyle(
                color: hasFocus ? colorPrimary : Colors.grey.shade600,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Delete button (hidden when only one frame)
          if (!isOnly)
            Positioned(
              top: 2.h,
              right: 2.w,
              child: GestureDetector(
                onTap: () => _deleteFrame(index),
                child: Icon(
                  Icons.close,
                  size: 14.sp,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          // Text input
          Padding(
            padding:
                EdgeInsets.only(top: 16.h, left: 6.w, right: 6.w, bottom: 2.h),
            child: TextField(
              controller: _frameControllers[index],
              focusNode: _focusNodes[index],
              maxLines: null,
              expands: true,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13.sp,
              ),
              cursorColor: colorPrimary,
              decoration: InputDecoration(
                hintText: 'Type...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12.sp,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
