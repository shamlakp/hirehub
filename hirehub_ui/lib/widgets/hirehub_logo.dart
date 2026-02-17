import 'package:flutter/material.dart';

class HireHubLogo extends StatelessWidget {
  final double fontSize;
  final bool showText;
  final Color? iconColor;
  final Color? textColor;

  const HireHubLogo({
    super.key,
    this.fontSize = 24,
    this.showText = true,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = iconColor ?? const Color(0xFF673AB7);
    final double iconSize = fontSize * 1.2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Custom Stylized "H" Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(iconSize * 0.25),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract Connectivity Dots
              Positioned(
                top: iconSize * 0.2,
                right: iconSize * 0.2,
                child: Container(
                  width: iconSize * 0.15,
                  height: iconSize * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: iconSize * 0.2,
                left: iconSize * 0.2,
                child: Container(
                  width: iconSize * 0.1,
                  height: iconSize * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(178),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // The "H" Letter
              Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: iconSize * 0.7,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Hire',
                  style: TextStyle(color: textColor ?? Colors.black87),
                ),
                TextSpan(
                  text: 'Hub',
                  style: TextStyle(color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
