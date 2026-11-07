import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/cupertino.dart';
import '../core/adaptive_page_scaffold.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/location_service.dart';

import '../services/locale_controller.dart';
import '../theme/app_theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaBearing;
  bool _isCalculating = false;
  String? _error;

  bool get _isArabic => LocaleController.isArabic;

  Future<void> _calculateQibla() async {
    if (_isCalculating) return;
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final position = await const LocationService().currentPosition();
      final rawBearing = Qibla.qibla(Coordinates(position.latitude, position.longitude));
      final bearing = _normalizeDegrees(rawBearing);

      if (!mounted) return;
      setState(() => _qiblaBearing = bearing);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  double _normalizeDegrees(double value) => (value % 360 + 360) % 360;

  double _relativeHeading(double deviceHeading) {
    final value = _normalizeDegrees((_qiblaBearing ?? 0) - deviceHeading);
    return value > 180 ? value - 360 : value;
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.emerald;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final surface = CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);
    final muted = CupertinoColors.secondaryLabel.resolveFrom(context);

    return AdaptivePageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isArabic ? 'اتجاه القبلة' : 'Qibla'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isCalculating ? null : _calculateQibla,
          child: Icon(CupertinoIcons.refresh, color: accent),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            final rawHeading = snapshot.data?.heading;
            final heading = rawHeading != null && rawHeading.isFinite
                ? _normalizeDegrees(rawHeading)
                : null;
            final compassUnavailable = snapshot.hasError ||
                (snapshot.connectionState == ConnectionState.active && heading == null);
            final relative = heading == null ? 0.0 : _relativeHeading(heading);
            final aligned = heading != null &&
                _qiblaBearing != null &&
                relative.abs() <= 5;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        Color.lerp(accent, const Color(0xFF073D35), .58)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .20),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CupertinoColors.white
                                  .withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              CupertinoIcons.compass_fill,
                              color: CupertinoColors.white,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isArabic ? 'دليلك إلى القبلة' : 'Your Qibla guide',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isArabic
                                      ? 'اتجاه مكة المكرمة من موقعك'
                                      : 'Direction to Makkah from your location',
                                  style: TextStyle(
                                    color: CupertinoColors.white
                                        .withValues(alpha: .82),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isArabic ? 'اتجاه القبلة' : 'QIBLA BEARING',
                                  style: TextStyle(
                                    color: CupertinoColors.white
                                        .withValues(alpha: .78),
                                    fontSize: 11,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _qiblaBearing == null
                                      ? '—'
                                      : '${_qiblaBearing!.round()}°',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 42,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white
                                  .withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  aligned
                                      ? CupertinoIcons.checkmark_circle_fill
                                      : CupertinoIcons.location_north_fill,
                                  size: 16,
                                  color: CupertinoColors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _qiblaBearing == null
                                      ? (_isArabic ? 'بانتظار الموقع' : 'Set location')
                                      : aligned
                                          ? (_isArabic ? 'في الاتجاه' : 'Aligned')
                                          : (_isArabic ? 'حرّك الهاتف' : 'Turn phone'),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: CupertinoColors.separator
                          .resolveFrom(context)
                          .withValues(alpha: .35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: heading == null
                                  ? CupertinoColors.systemOrange
                                  : accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            heading == null
                                ? (_isArabic
                                    ? 'بانتظار مستشعر البوصلة'
                                    : 'Waiting for compass sensor')
                                : (_isArabic
                                    ? 'البوصلة نشطة'
                                    : 'Compass is active'),
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SizedBox(
                          width: 286,
                          height: 286,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accent.withValues(alpha: .06),
                                      accent.withValues(alpha: .015),
                                      surface,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: accent.withValues(alpha: .25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: CustomPaint(
                                  size: const Size(266, 266),
                                  painter: _CompassDialPainter(
                                    accent: accent,
                                    muted: muted,
                                    isDark: isDark,
                                    heading: heading ?? 0,
                                  ),
                                ),
                              ),
                              if (_qiblaBearing != null && heading != null)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.rotate(
                                      angle: relative * math.pi / 180,
                                      child: CustomPaint(
                                        size: const Size(68, 112),
                                        painter: _QiblaArrowPainter(
                                          color: accent,
                                          outline: isDark
                                              ? CupertinoColors.white
                                                  .withValues(alpha: .9)
                                              : const Color(0xFF164A3A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _isArabic ? 'القبلة' : 'QIBLA',
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accent.withValues(alpha: .35),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.compass,
                                    color: accent,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        heading == null
                            ? (_isArabic
                                ? 'فعّل البوصلة واحتفظ بالهاتف بعيدًا عن المعادن.'
                                : 'Enable the compass and keep your phone away from metal.')
                            : _qiblaBearing == null
                                ? (_isArabic
                                    ? 'احسب الاتجاه لعرض سهم القبلة.'
                                    : 'Calculate your bearing to show the Qibla arrow.')
                                : aligned
                                    ? (_isArabic
                                        ? 'أحسنت، أنت تواجه اتجاه القبلة.'
                                        : 'You are facing the Qibla direction.')
                                    : relative > 0
                                        ? (_isArabic ? 'أدر الهاتف إلى اليمين بمقدار ${relative.abs().round()}° حتى يتجه السهم إلى الأعلى.' : 'Turn right ${relative.abs().round()}° until the arrow points up.')
                                        : (_isArabic ? 'أدر الهاتف إلى اليسار بمقدار ${relative.abs().round()}° حتى يتجه السهم إلى الأعلى.' : 'Turn left ${relative.abs().round()}° until the arrow points up.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (heading != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _isArabic
                              ? 'اتجاه الهاتف: ${heading.round()}°'
                              : 'Phone heading: ${heading.round()}°',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null || compassUnavailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed
                          .resolveFrom(context)
                          .withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error ??
                                (_isArabic
                                    ? 'مستشعر البوصلة غير متاح على هذا الجهاز.'
                                    : 'The compass sensor is unavailable on this device.'),
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                CupertinoButton.filled(
                  onPressed: _isCalculating ? null : _calculateQibla,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isCalculating
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.location_fill, size: 17),
                            const SizedBox(width: 9),
                            Text(
                              _qiblaBearing == null
                                  ? (_isArabic
                                      ? 'تحديد اتجاه القبلة'
                                      : 'Find Qibla direction')
                                  : (_isArabic
                                      ? 'تحديث الموقع والاتجاه'
                                      : 'Refresh location and bearing'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      size: 18,
                      color: muted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _isArabic
                            ? 'لأفضل دقة، أمسك الهاتف أفقيًا، وأبعده عن الأغطية المغناطيسية والمعادن. قد تحتاج إلى معايرة البوصلة.'
                            : 'For best accuracy, hold your phone flat and away from magnets or metal. Calibrate the compass if the direction seems unstable.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A high-contrast directional needle with a pointed tip and split tail.
class _QiblaArrowPainter extends CustomPainter {
  const _QiblaArrowPainter({required this.color, required this.outline});

  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .5, h * .025)
      ..lineTo(w * .94, h * .88)
      ..lineTo(w * .5, h * .69)
      ..lineTo(w * .06, h * .88)
      ..close();

    canvas.drawShadow(path, const Color(0x66000000), 5, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // A contrasting center seam makes the arrow's forward tip unmistakable.
    final seam = Path()
      ..moveTo(w * .5, h * .20)
      ..lineTo(w * .5, h * .66)
      ..lineTo(w * .16, h * .82);
    canvas.drawPath(
      seam,
      Paint()
        ..color = CupertinoColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final rightSeam = Path()
      ..moveTo(w * .5, h * .66)
      ..lineTo(w * .84, h * .82);
    canvas.drawPath(
      rightSeam,
      Paint()
        ..color = CupertinoColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.outline != outline;
}

class _CompassDialPainter extends CustomPainter {
  const _CompassDialPainter({
    required this.accent,
    required this.muted,
    required this.isDark,
    required this.heading,
  });

  final Color accent;
  final Color muted;
  final bool isDark;
  final double heading;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = muted.withValues(alpha: .42);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);

    for (var degree = 0; degree < 360; degree += 5) {
      final major = degree % 30 == 0;
      final medium = degree % 10 == 0;
      final outer = radius - 8;
      final inner = outer - (major ? 15 : medium ? 9 : 5);
      tickPaint
        ..strokeWidth = major ? 2 : 1
        ..color = major
            ? accent.withValues(alpha: .9)
            : muted.withValues(alpha: .35);
      final angle = degree * math.pi / 180;
      canvas.drawLine(
        Offset(math.sin(angle) * inner, -math.cos(angle) * inner),
        Offset(math.sin(angle) * outer, -math.cos(angle) * outer),
        tickPaint,
      );
    }

    final labels = <int, String>{0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    for (final entry in labels.entries) {
      final angle = entry.key * math.pi / 180;
      final position = Offset(
        math.sin(angle) * (radius - 31),
        -math.cos(angle) * (radius - 31),
      );
      final isNorth = entry.key == 0;
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            color: isNorth ? accent : muted,
            fontSize: isNorth ? 14 : 11,
            fontWeight: isNorth ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    canvas.restore();

    final centerPaint = Paint()
      ..color = isDark
          ? CupertinoColors.white.withValues(alpha: .06)
          : accent.withValues(alpha: .04);
    canvas.drawCircle(center, radius * .42, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.muted != muted ||
      oldDelegate.isDark != isDark ||
      oldDelegate.heading != heading;
}
