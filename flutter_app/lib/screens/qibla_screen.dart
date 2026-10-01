import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? qiblaBearing;
  String status = 'Find your Qibla direction using the phone compass.';

  Future<void> calculate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition();
      final qibla = Qibla.qibla(
        Coordinates(position.latitude, position.longitude),
      );

      if (!mounted) return;
      setState(() {
        qiblaBearing = qibla;
        status = 'Qibla is ${qibla.toStringAsFixed(1)}° from North.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla direction')),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final relative = heading == null ? 0.0 : relativeHeading(heading);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'القبلة',
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: relative / 360,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.navigation,
                        size: 170,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    heading == null
                        ? 'Waiting for compass sensor…'
                        : 'Turn the arrow toward the Qibla',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(status, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: calculate,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Calculate Qibla'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Keep the phone flat. If the heading is unstable, calibrate the compass.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
