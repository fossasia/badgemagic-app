import 'package:badgemagic/others/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<String?> showSaveClipartNameDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  final l10n = GetIt.instance.get<LocalizationService>().l10n;

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        titlePadding:
            const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
