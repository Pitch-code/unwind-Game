import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../monetization/ad_gateway.dart';
import '../monetization/ad_policy.dart';
import 'model/crossings.dart';
import 'model/level_generator.dart';
import 'unwind_game.dart';

/// Hosts the board and the light chrome around it: level number, crossings
/// remaining, and the "solved" panel. Advancing a level rebuilds a fresh game,
/// showing an interstitial first when the ad policy says so.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.ads = const NoAdsGateway(),
    this.adsRemoved = false,
  });

  /// How ads are shown. Defaults to a no-op; slice 4b injects the AdMob one.
  final AdGateway ads;

  /// Whether the player has bought "Remove Ads". Wired to the purchase in 4b.
  final bool adsRemoved;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _generator = LevelGenerator();
  static const _policy = AdPolicy();

  int _level = 1;
  int _crossings = 0;
  bool _solved = false;
  late UnwindGame _game;

  @override
  void initState() {
    super.initState();
    _load(_level);
    unawaited(widget.ads.preload());
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

  void _next() {
    final nextLevel = _level + 1;
    if (_policy.shouldShowInterstitial(
      level: nextLevel,
      adsRemoved: widget.adsRemoved,
    )) {
      unawaited(_showAdThenAdvance(nextLevel));
    } else {
      setState(() {
        _level = nextLevel;
        _load(_level);
      });
    }
  }

  Future<void> _showAdThenAdvance(int nextLevel) async {
    // The ad shows first; the level begins once it is dismissed. The gateway
    // never throws, so a missing ad simply advances.
    await widget.ads.showInterstitial();
    if (!mounted) return;
    setState(() {
      _level = nextLevel;
      _load(_level);
    });
    unawaited(widget.ads.preload());
  }

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
