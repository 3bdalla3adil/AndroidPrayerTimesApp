import 'dart:math' as math;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? bearing;
  String status = 'Tap the button to calculate Qibla from your current location.';

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
        bearing = qibla;
        status = 'Qibla direction is ' + qibla.toStringAsFixed(1) + '° from North.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final angle = (bearing ?? 0) * math.pi / 180;
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla direction')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'القبلة',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              AnimatedRotation(
                turns: bearing == null ? 0 : angle / (2 * math.pi),
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.navigation,
                  size: 190,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: calculate,
                icon: const Icon(Icons.my_location),
                label: const Text('Find Qibla'),
              ),
              const SizedBox(height: 10),
              const Text(
                'For best accuracy, hold the phone flat and calibrate its compass if requested.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
