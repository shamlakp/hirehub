import 'package:flutter/material.dart';

class MezbanLogo extends StatelessWidget {
  final double fontSize;
  final bool showText;
  final Color? iconColor;
  final Color? textColor;

  const MezbanLogo({
    super.key,
    this.fontSize = 32,
    this.showText = true,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = iconColor ?? const Color(0xFF673AB7);
    final double iconSize = fontSize * 1.2;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New Logo Image
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconSize * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(iconSize * 0.25),
            child: Image.asset(
              'assets/images/mezban_logo.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: primaryColor,
                  child: Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: iconSize * 0.7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'MEZBAN',
                  style: TextStyle(
                    color: textColor ?? Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                TextSpan(
                  text: ' MANPOWER',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      ),
    );
  }
}
