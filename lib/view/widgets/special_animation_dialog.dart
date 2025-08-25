import 'package:badgemagic/services/localization_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool?> showSpecialAnimationDialog(
    BuildContext context, String textToClear) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = GetIt.instance.get<LocalizationService>().l10n;
      return AlertDialog(
        title: Text(l10n.switchToSpecialAnimation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.specialAnimationWarning),
            if (textToClear.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      textToClear,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: l10n.copyText,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: textToClear));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.textCopied)),
                      );
                    },
                  ),
                ],
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      );
    },
  );
}
