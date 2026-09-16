import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'board_transform.dart';
import 'model/crossings.dart';
import 'model/level.dart';
import 'model/vec2.dart';

/// The playable board. Pins are draggable; ropes redraw from the pins every
/// frame. All the puzzle logic lives in the pure model — this class only
/// renders it and turns drags into pin moves.
class UnwindGame extends FlameGame {
  UnwindGame({
    required this.level,
    this.onCrossingsChanged,
    this.onSolved,
  });

  final Level level;
  final void Function(int crossings)? onCrossingsChanged;
  final void Function()? onSolved;

  /// Source of truth for where the pins are, in unit space (0..1).
  late final List<Vec2> unitPositions;

  /// Edges currently tangled — recomputed on every move, used only for tint.
  Set<int> crossedEdges = <int>{};

  bool _solvedReported = false;

  BoardTransform get transform =>
      BoardTransform(width: size.x, height: size.y);

  @override
  Color backgroundColor() => const Color(0xFF12211B);

  @override
  Future<void> onLoad() async {
    unitPositions =
        level.start.map((p) => Vec2(p.x, p.y)).toList(growable: false);
    _recompute();

    add(RopeLayer()..priority = 0);
    for (var i = 0; i < level.nodeCount; i++) {
      add(PinComponent(i)..priority = 1);
    }
  }

  /// Move pin [index] to [unit] (already clamped to 0..1) and re-evaluate.
  void moveNode(int index, Vec2 unit) {
    unitPositions[index] = unit;
    _recompute();
  }

  void _recompute() {
    crossedEdges = crossingEdgeIndices(unitPositions, level.edges);
    final pairs = countCrossings(unitPositions, level.edges);
    onCrossingsChanged?.call(pairs);
    if (pairs == 0 && !_solvedReported) {
      _solvedReported = true;
      onSolved?.call();
    }
  }
}

/// Draws every rope from the current pin positions. Sits behind the pins.
class RopeLayer extends PositionComponent with HasGameReference<UnwindGame> {
  @override
  void render(Canvas canvas) {
    final t = game.transform;
    final strokeWidth = (t.side * 0.006).clamp(2.0, 6.0);

    final calm = Paint()
      ..color = const Color(0xFF5E8577)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final warn = Paint()
      ..color = const Color(0xFFE0A15E)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final edges = game.level.edges;
    for (var i = 0; i < edges.length; i++) {
      final e = edges[i];
      final a = game.unitPositions[e.a];
      final b = game.unitPositions[e.b];
      final (ax, ay) = t.toPixel(a.x, a.y);
      final (bx, by) = t.toPixel(b.x, b.y);
      canvas.drawLine(
        Offset(ax, ay),
        Offset(bx, by),
        game.crossedEdges.contains(i) ? warn : calm,
      );
    }
  }
}

/// A draggable pin. Its screen position is derived from the shared unit
/// positions each frame, so it always agrees with the ropes.
class PinComponent extends CircleComponent
    with DragCallbacks, HasGameReference<UnwindGame> {
  PinComponent(this.index) : super(anchor: Anchor.center);

  final int index;

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = const Color(0xFF8FE0C0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = game.transform;
    radius = (t.side * 0.03).clamp(9.0, 26.0);
    final p = game.unitPositions[index];
    final (px, py) = t.toPixel(p.x, p.y);
    position = Vector2(px, py);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final t = game.transform;
    final p = game.unitPositions[index];
    final (cx, cy) = t.toPixel(p.x, p.y);
    final (ux, uy) = t.toUnit(
      cx + event.canvasDelta.x,
      cy + event.canvasDelta.y,
    );
    game.moveNode(index, Vec2(ux.clamp(0.0, 1.0), uy.clamp(0.0, 1.0)));
  }
}
