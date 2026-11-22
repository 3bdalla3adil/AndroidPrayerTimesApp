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
        ? const Color(0xFFBFA46A).withValues(alpha: 0.075)
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
        final center = Offset(x, y);
        final outer = Path()
          ..moveTo(x, y - 17)
          ..lineTo(x + 17, y)
          ..lineTo(x, y + 17)
          ..lineTo(x - 17, y)
          ..close();
        final inner = Path()
          ..moveTo(x, y - 9)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 9)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(outer, paint);
        canvas.drawPath(inner, paint);
        canvas.drawCircle(center, 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGeometryPainter oldDelegate) =>
      oldDelegate.color != color;
}
