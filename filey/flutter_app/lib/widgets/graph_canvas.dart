import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/graph_model.dart';
import '../theme/filey_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  GraphCanvas  –  interactive mindmap canvas
//
//  Interaction model:
//    • Pan:            drag background
//    • Zoom:           scroll wheel
//    • Tap node:       select / open editor
//    • Drag node:      reposition
//    • Tap node×2:     start edge; tap another node to complete
//    • Right-click:    context menu (rename / delete / color)
// ─────────────────────────────────────────────────────────────────
class GraphCanvas extends StatefulWidget {
  final GraphModel graph;
  final String? selectedNodeId;
  final String? pendingEdgeFromId; 

  final void Function(String uuid) onNodeTap;
  final void Function(String uuid, double x, double y) onNodeMove;
  final void Function(String uuid) onNodeDoubleTap;
  final void Function(String uuid) onEdgeTargetTap;
  final void Function(String uuid) onNodeRightClick;
  final void Function(Offset canvasPos) onBackgroundTap;

  const GraphCanvas({
    super.key,
    required this.graph,
    required this.onNodeTap,
    required this.onNodeMove,
    required this.onNodeDoubleTap,
    required this.onEdgeTargetTap,
    required this.onNodeRightClick,
    required this.onBackgroundTap,
    this.selectedNodeId,
    this.pendingEdgeFromId,
  });

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with SingleTickerProviderStateMixin {
  // ── for visual drag ────────────────────
  int _paintTick =0;
  // ── view transform ────────────────────────────────────────────
  Offset _pan   = Offset.zero;
  double _scale = 1.0;

  // ── drag state ───────────────────────────────────────────────
  String? _draggingId;
  Offset  _dragNodeStart  = Offset.zero;
  Offset  _dragPointerStart = Offset.zero;
  Size    _canvasSize = Size.zero;

  // ── animation (gentle snap to fit) ───────────────────────────
  late final AnimationController _fitCtrl;

  static const double _nodeR    = 44.0;
  static const double _minScale = 0.2;
  static const double _maxScale = 3.0;

  // screen coords → canvas coords
  Offset _toCanvas(Offset screen) =>
      Offset((screen.dx - _pan.dx) / _scale,
             (screen.dy - _pan.dy) / _scale);

  @override
  void initState() {
    super.initState();
    _fitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _fitCtrl.dispose();
    super.dispose();
  }

  // ── node hit test ─────────────────────────────────────────────
  String? _hitNode(Offset screenPos) {
    final canvasPos = _toCanvas(screenPos);
    // reverse order so topmost node (last drawn) is hit first
    for (final n in widget.graph.nodes.reversed) {
      final dx = canvasPos.dx - n.x;
      final dy = canvasPos.dy - n.y;
      if (dx * dx + dy * dy <= _nodeR * _nodeR) return n.id;
    }
    return null;
  }

  // ── zoom on scroll ───────────────────────────────────────────
  void _onScroll(PointerScrollEvent e) {
    final delta = e.scrollDelta.dy;
    final factor = delta > 0 ? 0.9 : 1.1;
    final focalCanvas = _toCanvas(e.localPosition);
    setState(() {
      _scale = (_scale * factor).clamp(_minScale, _maxScale);
      _pan   = e.localPosition - Offset(focalCanvas.dx * _scale, focalCanvas.dy * _scale);
    });
  }

  // ── gestures ─────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    final hit = _hitNode(d.localPosition);
    if (hit != null) {
      _draggingId = hit;
      final n = widget.graph.nodeById(hit)!;
      _dragNodeStart    = Offset(n.x, n.y);
      _dragPointerStart = d.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_draggingId != null) {
      final delta   = d.localPosition - _dragPointerStart;
      double newX    = _dragNodeStart.dx + delta.dx / _scale;
      double newY    = _dragNodeStart.dy + delta.dy / _scale;

      if (_canvasSize.width > 0 && _canvasSize.height > 0) {
        final minLogicalX = (-_pan.dx + _nodeR * _scale) / _scale;
        final maxLogicalX = (_canvasSize.width - _pan.dx - _nodeR * _scale) / _scale;
        final minLogicalY = (-_pan.dy + _nodeR * _scale) / _scale;
        final maxLogicalY = (_canvasSize.height - _pan.dy - _nodeR * _scale) / _scale;
        
        if (maxLogicalX > minLogicalX && maxLogicalY > minLogicalY) {
          newX = newX.clamp(minLogicalX, maxLogicalX);
          newY = newY.clamp(minLogicalY, maxLogicalY);
        }
      }

      // optimistic local update
      final node = widget.graph.nodeById(_draggingId!);
      if (node != null) {
        node.x = newX;
        node.y = newY;
        setState(() {_paintTick++;});
      }
    } else {
      setState(() => _pan += d.delta);
    }
  }

  void _onPanEnd(DragEndDetails _) {
    if (_draggingId != null) {
      final node = widget.graph.nodeById(_draggingId!);
      if (node != null) {
        widget.onNodeMove(_draggingId!, node.x, node.y);
      }
      _draggingId = null;
    }
  }

  void _onTapUp(TapUpDetails d) {
    final hit = _hitNode(d.localPosition);
    if (hit == null) {
      widget.onBackgroundTap(_toCanvas(d.localPosition));
    } else {
      if (widget.pendingEdgeFromId != null && widget.pendingEdgeFromId != hit) {
        widget.onEdgeTargetTap(hit);
      } else {
        widget.onNodeTap(hit);
      }
    }
  }

  void _onDoubleTapDown(TapDownDetails d) {
    final hit = _hitNode(d.localPosition);
    if (hit != null) widget.onNodeDoubleTap(hit);
  }

  void _onSecondaryTapUp(TapUpDetails d) {
    final hit = _hitNode(d.localPosition);
    if (hit != null) widget.onNodeRightClick(hit);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      return Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) _onScroll(e);
        },
        child: GestureDetector(
          onPanStart:          _onPanStart,
          onPanUpdate:         _onPanUpdate,
          onPanEnd:            _onPanEnd,
          onTapUp:             _onTapUp,
          onDoubleTapDown:     _onDoubleTapDown,
          onSecondaryTapUp:    _onSecondaryTapUp,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GraphPainter(
                graph:             widget.graph,
                pan:               _pan,
                scale:             _scale,
                selectedId:        widget.selectedNodeId,
                pendingEdgeFromId: widget.pendingEdgeFromId,
                nodeR:             _nodeR,
                paintTick:        _paintTick,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────
//  _GraphPainter
// ─────────────────────────────────────────────────────────────────
class _GraphPainter extends CustomPainter {
  final int paintTick;
  final GraphModel graph;
  final Offset     pan;
  final double     scale;
  final String?    selectedId;
  final String?    pendingEdgeFromId;
  final double     nodeR;

  _GraphPainter({
    required this.paintTick,
    required this.graph,
    required this.pan,
    required this.scale,
    required this.selectedId,
    required this.pendingEdgeFromId,
    required this.nodeR,
  });

  Offset _s(double cx, double cy) =>
      Offset(cx * scale + pan.dx, cy * scale + pan.dy);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Grid ────────────────────────────────────────────────────
    _drawGrid(canvas, size);

    // ── Edges ───────────────────────────────────────────────────
    final edgePaint = Paint()
      ..color = FileyColors.border.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final edgeHighPaint = Paint()
      ..color = FileyColors.accentDim.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final e in graph.edges) {
      final n1 = graph.nodeById(e.fromId);
      final n2 = graph.nodeById(e.toId);
      if (n1 == null || n2 == null) continue;

      final p1 = _s(n1.x, n1.y);
      final p2 = _s(n2.x, n2.y);

      final isHighlighted = (e.fromId == selectedId || e.toId == selectedId);
      canvas.drawLine(p1, p2, isHighlighted ? edgeHighPaint : edgePaint);

      // arrowhead for directed edges
      if (!e.bidirectional) {
        _drawArrow(canvas, p1, p2, isHighlighted ? edgeHighPaint : edgePaint);
      }
    }

    // ── Nodes ───────────────────────────────────────────────────
    for (int i = 0; i < graph.nodes.length; i++) {
      _drawNode(canvas, graph.nodes[i], i);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridSpacing = 40.0;
    final paint = Paint()
      ..color = FileyColors.border.withOpacity(0.25)
      ..strokeWidth = 0.5;

    // offset grid with pan
    final offsetX = pan.dx % (gridSpacing * scale);
    final offsetY = pan.dy % (gridSpacing * scale);
    final spacing  = gridSpacing * scale;

    for (double x = offsetX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offsetY; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawNode(Canvas canvas, GraphNode node, int index) {
    final center = _s(node.x, node.y);
    final r = nodeR * scale;
    if (r < 2) return; // too small to draw

    final isSelected = node.id == selectedId;
    final isPending  = node.id == pendingEdgeFromId;

    final baseColor = node.accentColor ?? FileyColors.nodeColor(index);

    // glow / selection ring
    if (isSelected || isPending) {
      final glowColor = isPending ? FileyColors.accent : baseColor;
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(center, r + 8, glowPaint);

      final ringPaint = Paint()
        ..color = glowColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r + 4, ringPaint);
    }

    // fill
    final fillPaint = Paint()
      ..color = FileyColors.bg2
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, fillPaint);

    // accent ring
    final borderPaint = Paint()
      ..color = baseColor.withOpacity(isSelected ? 1.0 : 0.55)
      ..strokeWidth = isSelected ? 2.0 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, borderPaint);

    // label
    if (r > 8) {
      final label  = node.label;
      final fontSize = (13.0 * scale).clamp(9.0, 18.0);
      final textStyle = TextStyle(
        color: isSelected ? baseColor : FileyColors.textPrimary,
        fontSize: fontSize,
        fontFamily: 'IBMPlexMono',
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      );

      var tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(maxWidth: r * 1.7);

      bool doesntFit = tp.height > r * 1.4 || tp.computeLineMetrics().length > 2;

      if (doesntFit) {
        tp.text = TextSpan(
          text: label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '',
          style: textStyle.copyWith(fontSize: fontSize * 1.5, fontWeight: FontWeight.bold)
        );
        tp.layout(maxWidth: r * 1.7);
      }

      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 10.0;
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final p1 = Offset(to.dx - arrowSize * math.cos(angle - 0.4),
                      to.dy - arrowSize * math.sin(angle - 0.4));
    final p2 = Offset(to.dx - arrowSize * math.cos(angle + 0.4),
                      to.dy - arrowSize * math.sin(angle + 0.4));
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.paintTick != paintTick ||
      old.graph  != graph  ||
      old.pan    != pan    ||
      old.scale  != scale  ||
      old.selectedId != selectedId ||
      old.pendingEdgeFromId != pendingEdgeFromId;
}
