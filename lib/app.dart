import 'package:flutter/material.dart';

import 'features/level_select/level_select_screen.dart';

class PixelGuessApp extends StatelessWidget {
  const PixelGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelGuess',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const LevelSelectScreen(),
    );
  }
}
