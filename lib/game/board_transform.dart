import 'dart:math';

/// Maps the puzzle's unit space (0..1 on both axes) onto a centred square on
/// the screen, with a margin around it.
///
/// Deliberately pure and dependency-free — no Flame, no Flutter — so the
/// coordinate maths can be unit tested. The Flame layer only ever calls into
/// this; it never does arithmetic of its own.
class BoardTransform {
  factory BoardTransform({
    required double width,
    required double height,
    double padding = 24,
  }) {
    final side = _sideFor(width, height, padding);
    return BoardTransform._(
      width,
      height,
      padding,
      side,
      (width - side) / 2,
      (height - side) / 2,
    );
  }

  const BoardTransform._(
    this.width,
    this.height,
    this.padding,
    this.side,
    this.originX,
    this.originY,
  );

  final double width;
  final double height;
  final double padding;

  /// Side length of the centred square the board is drawn in.
  final double side;
  final double originX;
  final double originY;

  static double _sideFor(double w, double h, double pad) {
    final avail = min(w, h) - 2 * pad;
    return avail < 0 ? 0 : avail;
  }

  /// Unit coordinate (0..1) -> pixel on screen.
  (double, double) toPixel(double ux, double uy) =>
      (originX + ux * side, originY + uy * side);

  /// Pixel on screen -> unit coordinate (0..1). Guards a zero-size board.
  (double, double) toUnit(double px, double py) => side == 0
      ? (0.0, 0.0)
      : ((px - originX) / side, (py - originY) / side);
}
