import 'geometry.dart';
import 'level.dart';
import 'vec2.dart';

/// How many pairs of ropes properly cross in [nodes] laid out this way.
///
/// Ropes sharing a pin are skipped: they meet at that pin but can never
/// "cross" in the sense the player has to fix. This is the number the game
/// shows tending toward zero, and zero is the win.
int countCrossings(List<Vec2> nodes, List<Edge> edges) {
  var crossings = 0;
  for (var i = 0; i < edges.length; i++) {
    final e = edges[i];
    for (var j = i + 1; j < edges.length; j++) {
      final f = edges[j];
      if (e.a == f.a || e.a == f.b || e.b == f.a || e.b == f.b) {
        continue; // share a pin
      }
      if (segmentsCross(nodes[e.a], nodes[e.b], nodes[f.a], nodes[f.b])) {
        crossings++;
      }
    }
  }
  return crossings;
}

/// The win condition: no rope crosses any other.
bool isSolved(List<Vec2> nodes, List<Edge> edges) =>
    countCrossings(nodes, edges) == 0;
