import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sudoku_app1/login.dart';

void main() async {
  await Hive.initFlutter('sudokuApp');
  // Box => sql database
  await Hive.openBox('settings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(keys: ['dark_theme', 'language']),
      builder: (context, box, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: box.get('dark_theme', defaultValue: false) ? ThemeData.dark() : ThemeData.light(),
          home: const LoginPage(),
        );
      },
    );
  }
}
