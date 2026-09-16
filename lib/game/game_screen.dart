import 'dart:async';

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../garden/garden.dart';
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
    this.onRemoveAds,
    this.onRestore,
    this.garden = const GardenState(levelsSolved: 0),
    this.onLevelSolved,
    this.onOpenGarden,
  });

  /// How ads are shown. Defaults to a no-op; slice 4b injects the AdMob one.
  final AdGateway ads;

  /// Whether the player has bought "Remove Ads". Wired to the purchase in 4b.
  final bool adsRemoved;

  /// Starts the "Remove Ads + unlock themes" purchase. Null when already owned.
  final Future<void> Function()? onRemoveAds;

  /// Restores a previously bought entitlement. Null hides the restore action.
  final Future<void> Function()? onRestore;

  /// The garden snapshot, shown as growth feedback on the solved panel.
  final GardenState garden;

  /// Called once when a level is solved, to grow the garden. Null in tests.
  final Future<void> Function()? onLevelSolved;

  /// Opens the full garden screen. Null hides the garden entry point.
  final VoidCallback? onOpenGarden;

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
      onSolved: () {
        setState(() => _solved = true);
        // Fires once per level instance (the engine reports solve once), so
        // this grows the garden by exactly one step per solved level.
        widget.onLevelSolved?.call();
      },
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
                children: [
                  Text('Level $_level', style: _hud),
                  const Spacer(),
                  Text(
                    _crossings == 0
                        ? 'untangled'
                        : '$_crossings crossing${_crossings == 1 ? '' : 's'}',
                    style: _hud,
                  ),
                  if (widget.onOpenGarden != null) ...[
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: widget.onOpenGarden,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.local_florist,
                        color: Color(0xFF8FE0C0),
                        size: 22,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.onRemoveAds != null)
              Positioned(
                bottom: 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => widget.onRemoveAds?.call(),
                      child: const Text('Remove ads'),
                    ),
                    if (widget.onRestore != null)
                      TextButton(
                        onPressed: () => widget.onRestore?.call(),
                        child: const Text('Restore'),
                      ),
                  ],
                ),
              ),
            if (_solved)
              _SolvedPanel(
                level: _level,
                garden: widget.garden,
                onNext: _next,
                onOpenGarden: widget.onOpenGarden,
              ),
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
  const _SolvedPanel({
    required this.level,
    required this.garden,
    required this.onNext,
    this.onOpenGarden,
  });

  final int level;
  final GardenState garden;
  final VoidCallback onNext;
  final VoidCallback? onOpenGarden;

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
            const SizedBox(height: 20),
            Text(
              _gardenLine(garden),
              style: const TextStyle(color: Color(0xFF8FE0C0), fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onNext,
              child: const Text('Next level'),
            ),
            if (onOpenGarden != null)
              TextButton(
                onPressed: onOpenGarden,
                child: const Text('View garden'),
              ),
          ],
        ),
      ),
    );
  }

  static String _gardenLine(GardenState g) {
    final plants = g.maturePlants;
    final grown = plants == 1 ? '1 plant grown' : '$plants plants grown';
    if (g.currentStage == GrowthStage.bloom) {
      return '$grown · a bloom is opening';
    }
    return '$grown · your ${_stageWord(g.currentStage)} is growing';
  }

  static String _stageWord(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seed:
        return 'seed';
      case GrowthStage.sprout:
        return 'sprout';
      case GrowthStage.growing:
        return 'seedling';
      case GrowthStage.budding:
        return 'bud';
      case GrowthStage.bloom:
        return 'bloom';
    }
  }
}
