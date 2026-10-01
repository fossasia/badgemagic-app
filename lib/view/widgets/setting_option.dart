import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/color.dart';

Widget buildSwitchCard({
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  IconData? icon,
  Color activeColor = colorPrimary,
}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: SwitchListTile(
      secondary: icon != null
          ? Icon(icon, color: value ? activeColor : Colors.grey)
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      activeColor: activeColor,
      value: value,
      onChanged: onChanged,
    ),
  );
}
