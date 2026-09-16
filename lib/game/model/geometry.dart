import 'vec2.dart';

/// Twice the signed area of triangle (o, a, b).
///
/// Positive when o->a->b turns counter-clockwise, negative for clockwise,
/// zero when the three points are collinear. This is the single primitive
/// every crossing decision is built on.
double orientation(Vec2 o, Vec2 a, Vec2 b) =>
    (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

/// Whether segments p1-p2 and p3-p4 cross at a single interior point.
///
/// This is deliberately a *proper* crossing test: segments that merely share
/// an endpoint, or only touch/overlap while collinear, do NOT count. That is
/// exactly the game's rule — two ropes tied to the same pin are not "crossed",
/// and a rope whose end lands on another rope is a touch, not a tangle.
bool segmentsCross(Vec2 p1, Vec2 p2, Vec2 p3, Vec2 p4) {
  final d1 = orientation(p3, p4, p1);
  final d2 = orientation(p3, p4, p2);
  final d3 = orientation(p1, p2, p3);
  final d4 = orientation(p1, p2, p4);

  // p1 and p2 must sit on strictly opposite sides of line 3-4, and vice versa.
  // Strict signs are what excludes shared endpoints and collinear touching.
  final opposite34 = (d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0);
  final opposite12 = (d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0);
  return opposite34 && opposite12;
}
