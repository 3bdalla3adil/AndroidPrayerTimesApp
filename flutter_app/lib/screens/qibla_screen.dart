import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../services/locale_controller.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? qiblaBearing;
  String status = LocaleController.isArabic ? 'حدّد اتجاه القبلة باستخدام بوصلة الهاتف.' : 'Find your Qibla direction using the phone compass.';

  Future<void> calculate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(LocaleController.isArabic ? 'خدمات الموقع معطّلة.' : 'Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(LocaleController.isArabic ? 'لم يتم منح إذن الموقع.' : 'Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final qibla = Qibla.qibla(
        Coordinates(position.latitude, position.longitude),
      );

      if (!mounted) return;
      setState(() {
        qiblaBearing = qibla;
        status = LocaleController.isArabic ? 'اتجاه القبلة ${qibla.toStringAsFixed(1)}° من الشمال.' : 'Qibla is ${qibla.toStringAsFixed(1)}° from North.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  double relativeHeading(double deviceHeading) {
    final target = qiblaBearing ?? 0;
    var value = target - deviceHeading;
    while (value < -180) {
      value += 360;
    }
    while (value > 180) {
      value -= 360;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoColors.activeGreen.resolveFrom(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(LocaleController.isArabic ? 'اتجاه القبلة' : 'Qibla direction'),
      ),
      child: SafeArea(
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(LocaleController.isArabic ? 'خطأ في البوصلة: ${snapshot.error}' : 'Compass error: ${snapshot.error}'));
            }

            final heading = snapshot.data?.heading;
            final relative =
                heading == null ? 0.0 : relativeHeading(heading);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
              child: Column(
                children: [
                  const Text(
                    'القبلة',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    heading == null
                        ? (LocaleController.isArabic ? 'بانتظار مستشعر البوصلة…' : 'Waiting for compass sensor…')
                        : (LocaleController.isArabic ? 'وجّه السهم نحو القبلة' : 'Turn the arrow toward the Qibla'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.systemGroupedBackground
                          .resolveFrom(context),
                      border: Border.all(color: accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey
                              .resolveFrom(context)
                              .withValues(alpha: .2),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                          top: 16,
                          child: Text(
                            'N',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Transform.rotate(
                          angle: relative * math.pi / 180,
                          child: Icon(
                            CupertinoIcons.arrow_up_circle_fill,
                            size: 150,
                            color: accent,
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          child: Text(
                            qiblaBearing == null
                                ? '—'
                                : '${qiblaBearing!.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(status, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  CupertinoButton.filled(
                    onPressed: calculate,
                    child: Text(LocaleController.isArabic ? 'حساب اتجاه القبلة' : 'Calculate Qibla'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    (LocaleController.isArabic ? 'أبقِ الهاتف مستويًا. إذا كان الاتجاه غير ثابت، فعاير البوصلة.' : 'Keep the phone flat. If the heading is unstable, calibrate the compass.'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
