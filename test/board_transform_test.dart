import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/game/board_transform.dart';

void main() {
  test('maps the unit square onto a centred square with a margin', () {
    final t = BoardTransform(width: 400, height: 800, padding: 24);
    expect(t.side, 352); // min(400, 800) - 2*24
    expect(t.originX, 24);
    expect(t.originY, 224); // (800 - 352) / 2

    final (x0, y0) = t.toPixel(0, 0);
    expect(x0, 24);
    expect(y0, 224);

    final (x1, y1) = t.toPixel(1, 1);
    expect(x1, closeTo(376, 1e-9));
    expect(y1, closeTo(576, 1e-9));
  });

  test('toUnit is the exact inverse of toPixel', () {
    final t = BoardTransform(width: 500, height: 300);
    final (px, py) = t.toPixel(0.3, 0.7);
    final (ux, uy) = t.toUnit(px, py);
    expect(ux, closeTo(0.3, 1e-9));
    expect(uy, closeTo(0.7, 1e-9));
  });

  test('a board too small for its padding does not divide by zero', () {
    final t = BoardTransform(width: 10, height: 10, padding: 24);
    expect(t.side, 0);
    final (ux, uy) = t.toUnit(5, 5);
    expect(ux, 0);
    expect(uy, 0);
  });
}
