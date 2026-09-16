import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import 'model/crossings.dart';
import 'model/level_generator.dart';
import 'unwind_game.dart';

/// Hosts the board and the light chrome around it: level number, crossings
/// remaining, and the "solved" panel. Advancing a level rebuilds a fresh game.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _generator = LevelGenerator();

  int _level = 1;
  int _crossings = 0;
  bool _solved = false;
  late UnwindGame _game;

  @override
  void initState() {
    super.initState();
    _load(_level);
  }

  void _load(int n) {
    final level = _generator.generate(n);
    _crossings = countCrossings(level.start, level.edges);
    _solved = false;
    _game = UnwindGame(
      level: level,
      onCrossingsChanged: (c) => setState(() => _crossings = c),
      onSolved: () => setState(() => _solved = true),
    );
  }

  void _next() => setState(() {
        _level += 1;
        _load(_level);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12211B),
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget(key: ValueKey(_level), game: _game),
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $_level', style: _hud),
                  Text(
                    _crossings == 0
                        ? 'untangled'
                        : '$_crossings crossing${_crossings == 1 ? '' : 's'}',
                    style: _hud,
                  ),
                ],
              ),
            ),
            if (_solved) _SolvedPanel(level: _level, onNext: _next),
          ],
        ),
      ),
    );
  }

  static const _hud = TextStyle(
    color: Color(0xFFBFD8CD),
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}

class _SolvedPanel extends StatelessWidget {
  const _SolvedPanel({required this.level, required this.onNext});

  final int level;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xAA0A140F),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Unwound',
              style: TextStyle(
                color: Color(0xFF8FE0C0),
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Level $level',
              style: const TextStyle(color: Color(0xFFBFD8CD), fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onNext,
              child: const Text('Next level'),
            ),
          ],
        ),
      ),
    );
  }
}
