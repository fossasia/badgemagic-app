import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../others/localization_service.dart';

Future<String?> showPinAuthDialog(BuildContext context) async {
  final l10n = GetIt.instance.get<LocalizationService>().l10n;
  final TextEditingController pinController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.badgeAuthentication),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterPinInstruction),
              const SizedBox(height: 16),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold),
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return l10n.pinLengthError;
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  hintText: '0000',
                  hintStyle: TextStyle(color: Colors.grey, letterSpacing: 16),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: Text(l10n.send),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(pinController.text);
              }
            },
          ),
        ],
      );
    },
  );
}
