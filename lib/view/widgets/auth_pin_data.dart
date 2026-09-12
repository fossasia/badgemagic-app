import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showPinAuthDialog(BuildContext context) async {
  final TextEditingController pinController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Badge Authentication'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Enter the 4-digit security code to unlock the badge transfer:'),
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
                    return 'PIN must be exactly 4 digits';
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
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: const Text('Send'),
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
