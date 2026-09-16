import 'vec2.dart';

/// An undirected rope between two pins, identified by their indices in a
/// level's node list. Stored with [a] < [b] so the same pair is never
/// represented two ways and duplicates compare equal.
class Edge {
  final int a;
  final int b;

  Edge(int first, int second)
      : assert(first != second, 'a rope cannot join a pin to itself'),
        a = first < second ? first : second,
        b = first < second ? second : first;

  @override
  bool operator ==(Object other) =>
      other is Edge && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => 'Edge($a, $b)';
}

/// One puzzle.
///
/// [edges] never change — the player only ever moves pins. So a level carries
/// two layouts of the same pins: [solved], a proof that a crossing-free
/// arrangement exists, and [start], the tangled layout the player begins from.
class Level {
  /// 1-based level number. The same number always yields the same puzzle.
  final int index;
  final int nodeCount;
  final List<Edge> edges;
  final List<Vec2> solved;
  final List<Vec2> start;

  const Level({
    required this.index,
    required this.nodeCount,
    required this.edges,
    required this.solved,
    required this.start,
  });
}
