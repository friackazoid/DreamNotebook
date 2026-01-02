import 'package:flutter/material.dart';

class NotebookBackground extends StatelessWidget {
  const NotebookBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NotebookPaperPainter(
        lineColor: Theme.of(context).colorScheme.surfaceVariant,
        marginColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
      child: child,
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  _NotebookPaperPainter({required this.lineColor, required this.marginColor});

  final Color lineColor;
  final Color marginColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.45)
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 2;

    const spacing = 32.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    canvas.drawLine(const Offset(72, 0), Offset(72, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _NotebookPaperPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor ||
        marginColor != oldDelegate.marginColor;
  }
}
