import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/game/model/crossings.dart';
import 'package:unwind/game/model/level_generator.dart';

void main() {
  const gen = LevelGenerator();

  // A spread across the whole 1..1000 range, including the boundaries.
  const sample = [1, 2, 3, 10, 50, 200, 500, 600, 601, 999, 1000];

  group('every generated level', () {
    for (final n in sample) {
      test('level $n opens tangled and can be solved', () {
        final level = gen.generate(n);

        // The promise: a crossing-free arrangement exists.
        expect(
          isSolved(level.solved, level.edges),
          isTrue,
          reason: 'level $n solved layout should have no crossings',
        );

        // And it is a real puzzle, not one that opens already solved.
        expect(
          countCrossings(level.start, level.edges),
          greaterThan(0),
          reason: 'level $n should start with at least one crossing',
        );
      });

      test('level $n is structurally sound', () {
        final level = gen.generate(n);

        expect(level.solved.length, level.nodeCount);
        expect(level.start.length, level.nodeCount);
        expect(level.nodeCount, LevelGenerator.nodeCountFor(n));

        for (final e in level.edges) {
          expect(e.a, inInclusiveRange(0, level.nodeCount - 1));
          expect(e.b, inInclusiveRange(0, level.nodeCount - 1));
          expect(e.a == e.b, isFalse);
        }

        // No duplicate ropes.
        expect(level.edges.toSet().length, level.edges.length);
      });
    }
  });

  test('generation is deterministic — same number, same puzzle', () {
    for (final n in [1, 42, 777, 1000]) {
      final a = gen.generate(n);
      final b = gen.generate(n);
      expect(a.edges, b.edges);
      expect(a.solved, b.solved);
      expect(a.start, b.start);
    }
  });

  test('difficulty curve stays within its declared bounds', () {
    var previous = 0;
    for (var n = 1; n <= 1000; n++) {
      final count = LevelGenerator.nodeCountFor(n);
      expect(count, inInclusiveRange(4, 22));
      expect(count, greaterThanOrEqualTo(previous)); // never decreases
      previous = count;
    }
  });
}
