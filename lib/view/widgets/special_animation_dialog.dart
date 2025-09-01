import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool?> showSpecialAnimationDialog(
    BuildContext context, String textToClear) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Switch to Special Animation?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Selecting this animation will overwrite your current text.'),
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
                    tooltip: 'Copy text',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: textToClear));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Text copied to clipboard!')),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}
