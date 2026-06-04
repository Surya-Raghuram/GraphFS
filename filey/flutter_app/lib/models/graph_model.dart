import 'dart:ui';

// ─────────────────────────────────────────────────────────────────
//  GraphNode
// ─────────────────────────────────────────────────────────────────
class GraphNode {
  final String id;
  final String label;
  final String contentFile;
  double x;
  double y;
  final int colorTag; // RGBA packed int

  GraphNode({
    required this.id,
    required this.label,
    required this.contentFile,
    required this.x,
    required this.y,
    this.colorTag = 0,
  });

  factory GraphNode.fromJson(Map<String, dynamic> j) => GraphNode(
        id: j['id'] as String,
        label: j['label'] as String,
        contentFile: j['content_file'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        colorTag: (j['color'] as num?)?.toInt() ?? 0,
      );

  /// Returns the node's accent color.
  /// Falls back to null so callers can apply a default palette.
  Color? get accentColor {
    if (colorTag == 0) return null;
    return Color(colorTag);
  }

  GraphNode copyWith({
    String? label,
    double? x,
    double? y,
    int? colorTag,
  }) =>
      GraphNode(
        id: id,
        label: label ?? this.label,
        contentFile: contentFile,
        x: x ?? this.x,
        y: y ?? this.y,
        colorTag: colorTag ?? this.colorTag,
      );
}

// ─────────────────────────────────────────────────────────────────
//  GraphEdge
// ─────────────────────────────────────────────────────────────────
class GraphEdge {
  final String fromId;
  final String toId;
  final String label;
  final bool bidirectional;

  const GraphEdge({
    required this.fromId,
    required this.toId,
    this.label = '',
    this.bidirectional = true,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> j) => GraphEdge(
        fromId: j['from'] as String,
        toId: j['to'] as String,
        label: (j['label'] as String?) ?? '',
        bidirectional: (j['bidirectional'] as bool?) ?? true,
      );
}

// ─────────────────────────────────────────────────────────────────
//  GraphModel  –  immutable snapshot from C++ via JSON
// ─────────────────────────────────────────────────────────────────
class GraphModel {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const GraphModel({required this.nodes, required this.edges});

  factory GraphModel.fromJson(Map<String, dynamic> j) => GraphModel(
        nodes: ((j['nodes'] as List?) ?? [])
            .map((n) => GraphNode.fromJson(n as Map<String, dynamic>))
            .toList(),
        edges: ((j['edges'] as List?) ?? [])
            .map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  GraphNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<GraphEdge> edgesFor(String nodeId) =>
      edges.where((e) => e.fromId == nodeId || e.toId == nodeId).toList();
}
