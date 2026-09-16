/// A 2D point in the puzzle's unit space. Coordinates run 0..1 on both axes,
/// so a level is resolution-independent — the renderer scales it to whatever
/// screen it lands on, and the game logic never needs to know about pixels.
class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      'Vec2(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})';
}
