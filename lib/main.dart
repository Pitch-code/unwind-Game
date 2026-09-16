import 'package:flutter/material.dart';

void main() => runApp(const UnwindApp());

/// Placeholder shell. The Flame game board and the garden meta land in the
/// next slices; this exists so the project is a coherent, analyzable app while
/// the puzzle core is proven out under test.
class UnwindApp extends StatelessWidget {
  const UnwindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unwind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6F5B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Unwind'),
        ),
      ),
    );
  }
}
