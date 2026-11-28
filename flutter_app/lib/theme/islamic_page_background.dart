import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// A restrained Islamic geometric texture for app-level page backgrounds.
/// It stays behind content, uses low-opacity strokes, and never intercepts taps.
class IslamicPageBackground extends StatelessWidget {
  const IslamicPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final ornament = isDark
        ? const Color(0xFFD8C18A).withValues(alpha: 0.075)
        : const Color(0xFF176B52).withValues(alpha: 0.055);

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _IslamicGeometryPainter(color: ornament),
          child: const SizedBox.expand(),
        ),
        child,
      ],
    );
  }
}

class _IslamicGeometryPainter extends CustomPainter {
  const _IslamicGeometryPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 92.0;
    for (double y = 24; y < size.height + spacing; y += spacing) {
      for (double x = 24; x < size.width + spacing; x += spacing) {
        final star = Path();
        for (var point = 0; point < 16; point++) {
          final angle = -math.pi / 2 + point * math.pi / 8;
          final radius = point.isEven ? 18.0 : 9.0;
          final position = Offset(
            x + math.cos(angle) * radius,
            y + math.sin(angle) * radius,
          );
          if (point == 0) {
            star.moveTo(position.dx, position.dy);
          } else {
            star.lineTo(position.dx, position.dy);
          }
        }
        star.close();
        canvas.drawPath(star, paint);
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGeometryPainter oldDelegate) =>
      oldDelegate.color != color;
}
