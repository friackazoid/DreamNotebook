import 'package:flutter/material.dart';

class DottedBackground extends StatelessWidget {
  const DottedBackground({
    super.key,
    required this.child,
    this.dotSpacing = 22,
    this.dotRadius = 1.2,
  });

  final Widget child;
  final double dotSpacing;
  final double dotRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPaperPainter(
        dotColor: Theme.of(context).dividerColor.withOpacity(0.45),
        dotSpacing: dotSpacing,
        dotRadius: dotRadius,
      ),
      child: child,
    );
  }
}

class _DottedPaperPainter extends CustomPainter {
  _DottedPaperPainter({
    required this.dotColor,
    required this.dotSpacing,
    required this.dotRadius,
  });

  final Color dotColor;
  final double dotSpacing;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double y = dotSpacing / 2; y < size.height; y += dotSpacing) {
      for (double x = dotSpacing / 2; x < size.width; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPaperPainter oldDelegate) {
    return dotColor != oldDelegate.dotColor ||
        dotSpacing != oldDelegate.dotSpacing ||
        dotRadius != oldDelegate.dotRadius;
  }
}
