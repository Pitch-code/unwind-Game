import 'dart:math';

import 'crossings.dart';
import 'geometry.dart';
import 'level.dart';
import 'vec2.dart';

/// Turns a level number into a concrete, always-solvable puzzle.
///
/// Two guarantees, and they are the whole point of this class:
///
/// 1. **Deterministic.** The same level number always produces the exact same
///    puzzle, because the only randomness comes from a seed derived from the
///    number. "Level 348" is identical on every phone, needs no server, and
///    nothing has to be stored — 1000 levels is a pure function, not data.
///
/// 2. **Always solvable.** Solvability is guaranteed by construction, not by
///    hoping. We first build a layout with zero crossings (a rope is only
///    accepted if it crosses nothing already placed), and only then scramble
///    the pins for the start. Because a crossing-free arrangement provably
///    exists — we just built one and kept it as [Level.solved] — the player
///    can always reach one. A test asserts this for a spread of levels.
class LevelGenerator {
  const LevelGenerator();

  /// The difficulty curve: pins grow with the level number.
  ///
  /// Level 1 is four pins; it eases up to [_maxNodes] by [_rampLevels] and then
  /// holds there, so the back half of the game gets harder through denser rope
  /// layouts (see [_targetEdgeCount]) rather than an unreadable pin count.
  static int nodeCountFor(int level) {
    if (level <= 1) return _minNodes;
    final t = (level - 1) / _rampLevels;
    final n = _minNodes + (t * (_maxNodes - _minNodes)).floor();
    return n.clamp(_minNodes, _maxNodes);
  }

  static const int _minNodes = 4;
  static const int _maxNodes = 22;
  static const int _rampLevels = 600;

  /// Build the puzzle for [level] (1-based).
  Level generate(int level) {
    final rng = Random(_seedFor(level));
    final n = nodeCountFor(level);

    final solved = _pointsInGeneralPosition(rng, n);
    final edges = _planarEdges(rng, solved, level);

    // Guaranteed by construction; the assert simply keeps us honest in debug
    // builds and tests if the construction is ever broken by a future change.
    assert(
      isSolved(solved, edges),
      'level $level: the "solved" layout somehow has crossings',
    );

    final start = _scramble(rng, solved, edges);

    return Level(
      index: level,
      nodeCount: n,
      edges: edges,
      solved: solved,
      start: start,
    );
  }

  /// A stable, non-negative seed within Random's accepted range.
  int _seedFor(int level) => (level * 2654435761) & 0x7fffffff;

  /// Scatter [n] pins so that no two are too close and no three are nearly
  /// collinear — "general position" keeps the crossing maths well-behaved and
  /// the board readable.
  List<Vec2> _pointsInGeneralPosition(Random rng, int n) {
    const margin = 0.08; // keep pins off the very edge
    const minDist = 0.06;
    const collinearEps = 1e-4;

    final pts = <Vec2>[];
    var attempts = 0;
    while (pts.length < n && attempts < 100000) {
      attempts++;
      final p = Vec2(
        margin + rng.nextDouble() * (1 - 2 * margin),
        margin + rng.nextDouble() * (1 - 2 * margin),
      );

      var ok = true;
      for (final q in pts) {
        if (_dist2(p, q) < minDist * minDist) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;

      var collinear = false;
      for (var i = 0; i < pts.length && !collinear; i++) {
        for (var j = i + 1; j < pts.length; j++) {
          if (orientation(pts[i], pts[j], p).abs() < collinearEps) {
            collinear = true;
            break;
          }
        }
      }
      if (collinear) continue;

      pts.add(p);
    }
    return pts;
  }

  /// Build a crossing-free set of ropes on [nodes].
  ///
  /// Two phases, and every accepted rope is checked against everything already
  /// placed, so the whole set stays planar:
  ///   * spanning — connect each pin to the nearest earlier pin it can reach
  ///     without a crossing, which keeps the board mostly connected;
  ///   * chords — add extra ropes to raise difficulty, still crossing-free.
  List<Edge> _planarEdges(Random rng, List<Vec2> nodes, int level) {
    final n = nodes.length;
    final accepted = <Edge>[];

    bool crossesAccepted(int a, int b) {
      for (final e in accepted) {
        if (e.a == a || e.a == b || e.b == a || e.b == b) continue;
        if (segmentsCross(nodes[a], nodes[b], nodes[e.a], nodes[e.b])) {
          return true;
        }
      }
      return false;
    }

    for (var k = 1; k < n; k++) {
      final order = List<int>.generate(k, (i) => i)
        ..sort((i, j) => _dist2(nodes[k], nodes[i])
            .compareTo(_dist2(nodes[k], nodes[j])));
      for (final j in order) {
        if (!crossesAccepted(k, j)) {
          accepted.add(Edge(k, j));
          break;
        }
      }
    }

    final target = _targetEdgeCount(n, level);
    final maxGuard = n * n * 4;
    var guard = 0;
    while (accepted.length < target && guard < maxGuard) {
      guard++;
      final a = rng.nextInt(n);
      final b = rng.nextInt(n);
      if (a == b) continue;
      final e = Edge(a, b);
      if (accepted.contains(e)) continue;
      if (!crossesAccepted(a, b)) accepted.add(e);
    }

    return accepted;
  }

  /// How many ropes to aim for. More ropes means more possible crossings to
  /// untangle, so this rises with the level. Capped at 3n-6, the most any
  /// straight-line planar graph can have.
  int _targetEdgeCount(int n, int level) {
    final spanning = n - 1;
    final maxPlanar = (3 * n - 6) < spanning ? spanning : (3 * n - 6);
    final progress = (level / 1000.0).clamp(0.0, 1.0);
    final extra = ((maxPlanar - spanning) * (0.30 + 0.50 * progress)).round();
    final target = spanning + extra;
    return target.clamp(spanning, maxPlanar);
  }

  /// Random start positions for the pins, retried until the layout actually
  /// has a crossing — otherwise it would open already solved, which is not a
  /// puzzle. The fallback only triggers for a level with too few ropes to ever
  /// cross, which for n >= 4 does not happen in practice.
  List<Vec2> _scramble(Random rng, List<Vec2> solved, List<Edge> edges) {
    const margin = 0.08;
    for (var attempt = 0; attempt < 200; attempt++) {
      final s = List<Vec2>.generate(
        solved.length,
        (_) => Vec2(
          margin + rng.nextDouble() * (1 - 2 * margin),
          margin + rng.nextDouble() * (1 - 2 * margin),
        ),
      );
      if (countCrossings(s, edges) > 0) return s;
    }
    return List<Vec2>.from(solved.reversed);
  }
}

double _dist2(Vec2 a, Vec2 b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}
