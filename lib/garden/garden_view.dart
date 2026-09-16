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

    canvas.drawLine(
      base,
      top,
      Paint()
        ..color = theme.stem
        ..strokeWidth = _clampD(s * 0.045, 2, 9)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (g > 0.25) {
      final leaf = Paint()..color = theme.leaf;
      final midY = base.dy - stemHeight * 0.5;
      final leafR = s * 0.10;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx - leafR, midY),
          width: leafR * 2,
          height: leafR,
        ),
        leaf,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx + leafR, midY),
          width: leafR * 2,
          height: leafR,
        ),
        leaf,
      );
    }

    if (g >= 0.6) {
      final openness = _clampD((g - 0.6) / 0.4, 0.4, 1);
      canvas.drawCircle(top, s * 0.13 * openness, Paint()..color = theme.bloom);
    } else {
      canvas.drawCircle(top, s * 0.045, Paint()..color = theme.leaf);
    }
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
