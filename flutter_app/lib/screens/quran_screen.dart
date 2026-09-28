import 'package:flutter/material.dart';
import 'package:quran_data_dart/quran_data_dart.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      await QuranService.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load Quran data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quran')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    load();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- Success state: render your Quran UI here ---
    // This is where your existing surah list / reader goes.
    return Scaffold(
      appBar: AppBar(title: const Text('Quran')),
      body: ListView(
        children: const [
          // Replace with your actual Quran UI, e.g.:
          // ...surahs.map((s) => ListTile(title: Text(s.name), ...)),
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Quran data loaded'),
            ),
          ),
        ],
      ),
    );
  }
}
