import 'dart:io';

import 'package:badgemagic/bademagic_module/utils/file_helper.dart';
import 'package:badgemagic/constants.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

/// A dialog that allows the user to rename an existing saved badge.
///
/// Pre-fills the text field with the current badge name (stripped of `.json`).
/// Validates that the new name is not empty and does not already exist on disk
/// (case-insensitively). On success, calls [refreshBadgesCallback] so the
/// list updates immediately.
class RenameBadgeDialog extends StatefulWidget {
  /// The current filename including the `.json` extension, e.g. `MyBadge.json`.
  final String currentFilename;

  /// The full badge data entry (needed to pass back to [refreshBadgesCallback])
  final MapEntry<String, Map<String, dynamic>> badgeData;

  /// Called after a successful rename so the parent list view refreshes.
  final Future<void> Function(MapEntry<String, Map<String, dynamic>>)
      refreshBadgesCallback;

  const RenameBadgeDialog({
    super.key,
    required this.currentFilename,
    required this.badgeData,
    required this.refreshBadgesCallback,
  });

  @override
  State<RenameBadgeDialog> createState() => _RenameBadgeDialogState();
}

class _RenameBadgeDialogState extends State<RenameBadgeDialog> {
  late final TextEditingController _nameController;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the current name, stripping the `.json` extension
    final currentName = widget.currentFilename.endsWith('.json')
        ? widget.currentFilename.substring(
            0, widget.currentFilename.length - 5)
        : widget.currentFilename;
    _nameController = TextEditingController(text: currentName);
    // Select all text so the user can immediately type a new name
    _nameController.selection =
        TextSelection(baseOffset: 0, extentOffset: currentName.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onRename() async {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      setState(() => _errorText = l10n.badgeNameEmpty);
      return;
    }

    final currentName = widget.currentFilename.endsWith('.json')
        ? widget.currentFilename.substring(
            0, widget.currentFilename.length - 5)
        : widget.currentFilename;
    if (newName == currentName) {
      Navigator.of(context).pop();
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final dirList = Directory(directory.path).listSync();
    final existingNames = dirList
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) {
          final base = f.path.split(Platform.pathSeparator).last;
          return base.substring(0, base.length - 5);
        })
        .toList();

    final isDuplicate = existingNames.any(
      (name) =>
          name.toLowerCase() == newName.toLowerCase() &&
          name.toLowerCase() != currentName.toLowerCase(),
    );

    if (isDuplicate) {
      setState(() => _errorText = l10n.badgeAlreadyExists);
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    final success =
        await FileHelper().renameBadge(widget.currentFilename, newName);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final updatedEntry = MapEntry('$newName.json', widget.badgeData.value);
      await widget.refreshBadgesCallback(updatedEntry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            GetIt.instance.get<LocalizationService>().l10n.badgeRenamedSuccessfully,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      if (!mounted) return;
      setState(
        () => _errorText = GetIt.instance
            .get<LocalizationService>()
            .l10n
            .couldNotRenameBadge,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        width: 300.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.renameBadge,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.newName,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: colorPrimary,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 200,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorPrimary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorPrimary, width: 2),
                ),
              ),
            ),
            // Inline error message
            if (_errorText != null) ...[
              SizedBox(height: 4.h),
              Text(
                _errorText!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: colorPrimary),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _onRename,
                  child: _isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorPrimary,
                          ),
                        )
                      : Text(
                          l10n.rename,
                          style: TextStyle(color: colorPrimary),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
