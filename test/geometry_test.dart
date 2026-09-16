import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/game/model/crossings.dart';
import 'package:unwind/game/model/geometry.dart';
import 'package:unwind/game/model/level.dart';
import 'package:unwind/game/model/vec2.dart';

void main() {
  group('segmentsCross', () {
    test('a clear X counts as a crossing', () {
      expect(
        segmentsCross(
          const Vec2(0, 0),
          const Vec2(1, 1),
          const Vec2(0, 1),
          const Vec2(1, 0),
        ),
        isTrue,
      );
    });

    test('segments sharing a pin do not count', () {
      // Both start at (0,0) — a shared pin, not a tangle.
      expect(
        segmentsCross(
          const Vec2(0, 0),
          const Vec2(1, 1),
          const Vec2(0, 0),
          const Vec2(1, 0),
        ),
        isFalse,
      );
    });

    test('a T-touch (endpoint landing on a rope) does not count', () {
      // (0.5, 0) sits exactly on segment (0,0)-(1,0): a touch, not a cross.
      expect(
        segmentsCross(
          const Vec2(0, 0),
          const Vec2(1, 0),
          const Vec2(0.5, 0),
          const Vec2(0.5, 1),
        ),
        isFalse,
      );
    });

    test('parallel, separated segments do not count', () {
      expect(
        segmentsCross(
          const Vec2(0, 0),
          const Vec2(1, 0),
          const Vec2(0, 1),
          const Vec2(1, 1),
        ),
        isFalse,
      );
    });
  });

  group('countCrossings', () {
    test('two ropes forming an X give exactly one crossing', () {
      final nodes = [
        const Vec2(0, 0),
        const Vec2(1, 1),
        const Vec2(0, 1),
        const Vec2(1, 0),
      ];
      final edges = [Edge(0, 1), Edge(2, 3)];
      expect(countCrossings(nodes, edges), 1);
      expect(isSolved(nodes, edges), isFalse);
    });

    test('uncrossing the same two ropes solves it', () {
      final nodes = [
        const Vec2(0, 0),
        const Vec2(1, 0),
        const Vec2(0, 1),
        const Vec2(1, 1),
      ];
      final edges = [Edge(0, 1), Edge(2, 3)];
      expect(countCrossings(nodes, edges), 0);
      expect(isSolved(nodes, edges), isTrue);
    });
  });
}
