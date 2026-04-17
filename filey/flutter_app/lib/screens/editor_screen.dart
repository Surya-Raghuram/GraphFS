import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/graph_model.dart';
import '../services/filey_project.dart';
import '../theme/filey_theme.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/markdown_editor.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  EditorScreen  –  the main 2-panel layout
//
//  ┌─────────┬───────────────────┬──────────┐
//  │ sidebar │   graph canvas    │ Md editor│
//  │         │                   │          │
//  │         │                   │          │
//  │         │                   │          │
//  └─────────┴───────────────────┴──────────┘
//
//  The editor panel slides in from the right when a node is selected.
// ─────────────────────────────────────────────────────────────────
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  String? _selectedId;
  String? _pendingEdgeFrom; // uuid waiting for edge target

  // editor panel width (resizable)
  double _editorWidth = 420;
  bool   _editorOpen  = false;

  void _selectNode(String uuid) {
    setState(() {
      _selectedId  = uuid;
      _editorOpen  = true;
      _pendingEdgeFrom = null;
    });
  }

  void _startEdge(String uuid) {
    setState(() {
      _pendingEdgeFrom = uuid;
      _selectedId      = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select another node to connect, or tap background to cancel'),
        duration: Duration(seconds: 3),
        backgroundColor: FileyColors.bg3,
      ),
    );
  }

  void _completeEdge(String toUuid) {
    final from = _pendingEdgeFrom;
    if (from == null) return;
    final project = context.read<FileyProject>();
    project.addEdge(from, toUuid);
    setState(() { _pendingEdgeFrom = null; _selectedId = toUuid; _editorOpen = true; });
  }

  void _onBackgroundTap(Offset canvasPos) {
    if (_pendingEdgeFrom != null) {
      setState(() => _pendingEdgeFrom = null);
      return;
    }
    // Double-tap background is handled by the canvas; single tap deselects
    setState(() { _selectedId = null; _editorOpen = false; });
  }

  void _addNodeAt(Offset canvasPos) {
    final project = context.read<FileyProject>();
    final uuid = project.addNode('New Node', canvasPos.dx, canvasPos.dy);
    if (uuid != null) _selectNode(uuid);
  }

  void _showNodeContextMenu(String uuid) {
    final project = context.read<FileyProject>();
    final node = project.graph.nodeById(uuid);
    if (node == null) return;

    showDialog(
      context: context,
      builder: (ctx) => _NodeContextDialog(
        node: node,
        onDelete: () {
          project.removeNode(uuid);
          setState(() { _selectedId = null; _editorOpen = false; });
        },
        onStartEdge: () => _startEdge(uuid),
        onExport: () {
          // TODO: file picker for export
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export: pick a directory'),
              backgroundColor: FileyColors.bg3),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<FileyProject>();
    final graph   = project.graph;

    return Scaffold(
      backgroundColor: FileyColors.bg0,
      body: Column(
        children: [
          _buildTopBar(project),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(graph, project),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Stack(
                    children: [
                      // ── Graph canvas ──────────────────────────
                      GraphCanvas(
                        graph:             graph,
                        selectedNodeId:    _selectedId,
                        pendingEdgeFromId: _pendingEdgeFrom,
                        onNodeTap:         _selectNode,
                        onNodeDoubleTap:   _startEdge,
                        onEdgeTargetTap:   _completeEdge,
                        onNodeRightClick:  _showNodeContextMenu,
                        onBackgroundTap:   _onBackgroundTap,
                        onNodeMove: (uuid, x, y) =>
                            project.moveNode(uuid, x, y),
                      ),

                      // ── Canvas controls overlay ───────────────
                      Positioned(
                        bottom: 16, right: _editorOpen ? _editorWidth + 16 : 16,
                        child: _buildCanvasControls(project),
                      ),

                      // ── Edge-mode indicator ───────────────────
                      if (_pendingEdgeFrom != null)
                        Positioned(
                          top: 12, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: FileyColors.bg2,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: FileyColors.accent),
                              ),
                              child: const Text(
                                '⚡  TAP A NODE TO CONNECT  ·  ESC TO CANCEL',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono', fontSize: 11,
                                  color: FileyColors.accent, letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Editor panel ──────────────────────────────
                if (_editorOpen && _selectedId != null) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: _editorWidth,
                    child: _buildEditorPanel(project, graph),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(FileyProject project) {
    final parts  = project.rootPath.split('/');
    final folder = parts.isNotEmpty ? parts.last : project.rootPath;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: FileyColors.bg1,
        border: Border(bottom: BorderSide(color: FileyColors.border)),
      ),
      child: Row(
        children: [
          const Text('FILEY',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 15,
              fontWeight: FontWeight.w700, color: FileyColors.accent,
              letterSpacing: -0.5,
            )),
          const SizedBox(width: 12),
          const SizedBox(height: 20, child: VerticalDivider(width: 1)),
          const SizedBox(width: 12),
          Icon(Icons.folder_outlined, size: 14, color: FileyColors.textMuted),
          const SizedBox(width: 6),
          Text(folder,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono', fontSize: 12,
              color: FileyColors.textSecondary,
            )),
          const Spacer(),
          // Save indicator
          Tooltip(
            message: 'Save project (Ctrl+S)',
            child: TextButton.icon(
              onPressed: project.save,
              icon: const Icon(Icons.save_outlined, size: 14),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Close project',
            child: TextButton.icon(
              onPressed: () {
                project.closeProject();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: FileyColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(GraphModel graph, FileyProject project) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: FileyColors.bg1,
            child: Text(
              'NODES  ${graph.nodes.length}',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono', fontSize: 10,
                letterSpacing: 1.2, color: FileyColors.textMuted,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: graph.nodes.length,
              itemBuilder: (ctx, i) {
                final node = graph.nodes[i];
                final isSelected = node.id == _selectedId;
                return _SidebarItem(
                  node: node,
                  index: i,
                  selected: isSelected,
                  onTap: () => _selectNode(node.id),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => _addNodeAt(const Offset(0, 0)),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Node'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel(FileyProject project, GraphModel graph) {
    final node = graph.nodeById(_selectedId!);
    if (node == null) return const SizedBox();

    return MarkdownEditor(
      key: ValueKey(_selectedId),
      node: node,
      project: project,
      onClose: () => setState(() { _editorOpen = false; _selectedId = null; }),
      onRename: (newLabel) => project.renameNode(node.id, newLabel),
    );
  }

  Widget _buildCanvasControls(FileyProject project) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabButton(
          icon: Icons.add,
          tooltip: 'Add node (or double-click canvas)',
          onTap: () => _addNodeAt(const Offset(0, 0)),
        ),
        const SizedBox(height: 8),
        _FabButton(
          icon: Icons.link,
          tooltip: 'Select a node then double-tap to start edge',
          onTap: _selectedId != null ? () => _startEdge(_selectedId!) : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Sidebar item
// ─────────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final GraphNode node;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.node, required this.index,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = node.accentColor ?? FileyColors.nodeColor(index);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? FileyColors.bg3 : Colors.transparent,
          border: selected
              ? const Border(left: BorderSide(color: FileyColors.accent, width: 2))
              : const Border(left: BorderSide(color: Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(node.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 12,
                  color: selected ? FileyColors.textPrimary : FileyColors.textSecondary,
                )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  FAB button
// ─────────────────────────────────────────────────────────────────
class _FabButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _FabButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: FileyColors.bg2,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: FileyColors.border),
          ),
          child: Icon(icon, size: 18,
            color: onTap != null ? FileyColors.accent : FileyColors.textMuted),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
//  Node context dialog
// ─────────────────────────────────────────────────────────────────
class _NodeContextDialog extends StatelessWidget {
  final GraphNode node;
  final VoidCallback onDelete;
  final VoidCallback onStartEdge;
  final VoidCallback onExport;

  const _NodeContextDialog({
    required this.node,
    required this.onDelete,
    required this.onStartEdge,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FileyColors.bg2,
      title: Text(node.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogAction(
            icon: Icons.link, label: 'Connect to another node',
            onTap: () { Navigator.pop(context); onStartEdge(); },
          ),
          _DialogAction(
            icon: Icons.download_outlined, label: 'Export as .md',
            onTap: () { Navigator.pop(context); onExport(); },
          ),
          const Divider(),
          _DialogAction(
            icon: Icons.delete_outline, label: 'Delete node',
            color: FileyColors.danger,
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
        ],
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DialogAction({
    required this.icon, required this.label, required this.onTap,
    this.color = FileyColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 18, color: color),
    title: Text(label, style: TextStyle(
      fontFamily: 'IBMPlexMono', fontSize: 13, color: color,
    )),
    onTap: onTap,
    dense: true,
  );
}
