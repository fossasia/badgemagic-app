import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DrawToolButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final Color tint;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onPressed;

  const DrawToolButton({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.tint,
    required this.iconSize,
    required this.fontSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconAsset != null
              ? SvgPicture.asset(
                  iconAsset!,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                )
              : Icon(icon, color: tint, size: iconSize),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: tint, fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
