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
    final t = ((level - 1) / _rampLevels).clamp(0.0, 1.0);
    final n = _minNodes + (t * (_maxNodes - _minNodes)).round();
    return n.clamp(_minNodes, _maxNodes);
  }

  static const int _minNodes = 4;
  static const int _maxNodes = 22;
  static const int _rampLevels = 500;

  /// How many pins start away from their solved spot.
  ///
  /// This is the real early-game difficulty dial. Level 1 displaces a single
  /// pin — the board is already almost solved and the player just tucks one
  /// pin into place — and it grows by one pin every few levels until the whole
  /// board is scrambled. Higher pin-count boards therefore also get a longer,
  /// gentler on-ramp before they become a full tangle.
  static int displacedCountFor(int level, int nodeCount) {
    if (nodeCount <= 1) return nodeCount;
    final displaced = 1 + ((level - 1) ~/ _displaceStep);
    return displaced.clamp(1, nodeCount);
  }

  /// Add one more displaced pin every this many levels.
  static const int _displaceStep = 3;

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

    final start = _scramble(rng, solved, edges, level);

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
    if (maxPlanar <= spanning) return spanning;

    final progress = ((level - 1) / 1000.0).clamp(0.0, 1.0);
    // Sparser early (fewer ropes, fewer possible crossings), denser late.
    final density = 0.20 + 0.65 * progress;
    // Always at least one chord beyond the spanning tree, so two non-adjacent
    // ropes always exist and the board can actually be tangled.
    final rawExtra = ((maxPlanar - spanning) * density).round();
    final extra = rawExtra < 1 ? 1 : rawExtra;
    final target = spanning + extra;
    return target.clamp(spanning, maxPlanar);
  }

  /// Build the tangled start by displacing only some pins from [solved].
  ///
  /// The number of pins moved is [displacedCountFor], and we move the
  /// highest-degree pins first: they carry the most ropes, so moving them
  /// reliably creates a crossing and gives the player the most meaningful pins
  /// to fix. Every other pin stays exactly where it belongs, which is what
  /// makes the early levels read as "nearly solved".
  ///
  /// Positions of the moved pins are retried until the layout actually has a
  /// crossing (an untangled start is not a puzzle); if a given displacement
  /// somehow can't produce one, we move one more pin, and finally fall back to
  /// the reversed layout. For n >= 4 with at least one chord this never has to.
  List<Vec2> _scramble(
    Random rng,
    List<Vec2> solved,
    List<Edge> edges,
    int level,
  ) {
    final n = solved.length;
    final want = displacedCountFor(level, n);
    final byDegree = _pinsByDegreeDesc(n, edges);

    for (var disp = want; disp <= n; disp++) {
      final moving = byDegree.take(disp).toSet();
      for (var attempt = 0; attempt < 300; attempt++) {
        final s = <Vec2>[
          for (var i = 0; i < n; i++)
            if (moving.contains(i))
              _randPoint(rng)
            else
              Vec2(solved[i].x, solved[i].y),
        ];
        if (countCrossings(s, edges) > 0) return s;
      }
    }
    return List<Vec2>.from(solved.reversed);
  }

  /// Pin indices ordered by descending degree, ties broken by index, so the
  /// choice of which pins to displace is deterministic.
  List<int> _pinsByDegreeDesc(int n, List<Edge> edges) {
    final degree = List<int>.filled(n, 0);
    for (final e in edges) {
      degree[e.a]++;
      degree[e.b]++;
    }
    final order = List<int>.generate(n, (i) => i);
    order.sort((i, j) {
      final byDeg = degree[j].compareTo(degree[i]);
      return byDeg != 0 ? byDeg : i.compareTo(j);
    });
    return order;
  }

  Vec2 _randPoint(Random rng) {
    const margin = 0.08;
    return Vec2(
      margin + rng.nextDouble() * (1 - 2 * margin),
      margin + rng.nextDouble() * (1 - 2 * margin),
    );
  }
}

double _dist2(Vec2 a, Vec2 b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}
