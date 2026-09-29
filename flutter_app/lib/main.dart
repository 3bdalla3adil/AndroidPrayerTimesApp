import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up SharedPreferences so screens can read it synchronously later.
  await SharedPreferences.getInstance();

  runApp(const SalawatQuranApp());
}
