import 'dart:math';

import 'package:flutter/material.dart';

import 'garden.dart';
import 'garden_theme.dart';

/// Renders the zen garden: a soil line with a row of plants — one fully grown
/// for each matured plant, plus the one currently growing at its live height —
/// all painted in the selected [theme]'s palette.
///
/// This is presentation only; every value it draws comes from the pure
/// [GardenState]. Visual feel is confirmed on device.
class GardenView extends StatelessWidget {
  const GardenView({super.key, required this.state, required this.theme});

  final GardenState state;
  final GardenTheme theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GardenPainter(state: state, theme: theme),
      child: const SizedBox.expand(),
    );
  }
}

class _GardenPainter extends CustomPainter {
  _GardenPainter({required this.state, required this.theme});

  final GardenState state;
  final GardenTheme theme;

  /// How many matured plants to draw before collapsing the rest into a count.
  static const int _maxVisible = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final soilTop = size.height * 0.82;
    canvas.drawRect(
      Rect.fromLTRB(0, soilTop, size.width, size.height),
      Paint()..color = theme.soil,
    );

    final mature = state.maturePlants;
    final visibleMature = mature > _maxVisible ? _maxVisible : mature;
    final plantsToDraw = visibleMature + 1; // + the one still growing
    final slot = size.width / (plantsToDraw + 1);
    final plantSize = _clampD(size.height * 0.55, 60, 260);

    for (var i = 0; i < visibleMature; i++) {
      _drawPlant(canvas, Offset(slot * (i + 1), soilTop), plantSize, 1);
    }
    _drawPlant(
      canvas,
      Offset(slot * (visibleMature + 1), soilTop),
      plantSize,
      state.currentGrowth,
    );

    if (mature > _maxVisible) {
      _drawOverflow(canvas, size, mature - _maxVisible);
    }
  }

  void _drawPlant(Canvas canvas, Offset base, double s, double growth) {
    final g = _clampD(growth, 0, 1);
    final stemHeight = s * (0.15 + 0.85 * g); // always at least a small sprout
    final top = Offset(base.dx, base.dy - stemHeight);

    // A gently curved stem reads softer than a straight stick.
    final bend = s * 0.06;
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + bend,
        base.dy - stemHeight * 0.55,
        top.dx,
        top.dy,
      );
    canvas.drawPath(
      stem,
      Paint()
        ..color = theme.stem
        ..strokeWidth = _clampD(s * 0.045, 2, 9)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (g > 0.25) {
      final leafPaint = Paint()..color = theme.leaf;
      final leafOrigin = Offset(base.dx + bend * 0.6, base.dy - stemHeight * 0.45);
      _drawLeaf(canvas, leafOrigin, s * 0.22, -1, leafPaint);
      _drawLeaf(canvas, leafOrigin, s * 0.22, 1, leafPaint);
    }

    if (g >= 0.6) {
      final openness = _clampD((g - 0.6) / 0.4, 0.35, 1);
      _drawBloom(canvas, top, s * 0.14 * openness);
    } else {
      canvas.drawCircle(top, s * 0.05, Paint()..color = theme.leaf);
    }
  }

  /// A single leaf sweeping out from [origin] toward [dir] (-1 left, +1 right).
  void _drawLeaf(Canvas canvas, Offset origin, double len, int dir, Paint paint) {
    final tip = Offset(origin.dx + dir * len, origin.dy - len * 0.5);
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        origin.dx + dir * len * 0.2,
        origin.dy - len * 0.6,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        origin.dx + dir * len * 0.9,
        origin.dy - len * 0.05,
        origin.dx,
        origin.dy,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  /// A ring of petals with a lighter centre.
  void _drawBloom(Canvas canvas, Offset center, double r) {
    final petal = Paint()..color = theme.bloom;
    const petals = 5;
    for (var i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * pi;
      final c = Offset(
        center.dx + cos(angle) * r * 0.7,
        center.dy + sin(angle) * r * 0.7,
      );
      canvas.drawCircle(c, r * 0.55, petal);
    }
    canvas.drawCircle(center, r * 0.5, Paint()..color = theme.leaf);
  }

  void _drawOverflow(Canvas canvas, Size size, int hidden) {
    final tp = TextPainter(
      text: TextSpan(
        text: '+$hidden more',
        style: TextStyle(color: theme.leaf, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 12, size.height * 0.84));
  }

  static double _clampD(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  @override
  bool shouldRepaint(covariant _GardenPainter old) =>
      old.state.levelsSolved != state.levelsSolved || old.theme.id != theme.id;
}
