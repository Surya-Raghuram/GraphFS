import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/graph_model.dart';
import '../services/filey_project.dart';
import '../theme/filey_theme.dart';

// ─────────────────────────────────────────────────────────────────
//  MarkdownEditor
//  Shows a split toolbar + either raw editor or rendered preview.
//  Auto-saves 800 ms after the user stops typing.
// ─────────────────────────────────────────────────────────────────
class MarkdownEditor extends StatefulWidget {
  final GraphNode node;
  final FileyProject project;
  final VoidCallback? onClose;
  final void Function(String newLabel)? onRename;

  const MarkdownEditor({
    super.key,
    required this.node,
    required this.project,
    this.onClose,
    this.onRename,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _ctrl;
  late final TextEditingController _labelCtrl;
  bool _preview    = false;
  bool _dirty      = false;
  bool _renaming   = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    final content = widget.project.readContent(widget.node.id);
    _ctrl      = TextEditingController(text: content);
    _labelCtrl = TextEditingController(text: widget.node.label);
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(MarkdownEditor old) {
    super.didUpdateWidget(old);
    if (old.node.id != widget.node.id) {
      _saveNow();
      final content = widget.project.readContent(widget.node.id);
      _ctrl.removeListener(_onTextChanged);
      _ctrl.text = content;
      _ctrl.addListener(_onTextChanged);
      _labelCtrl.text = widget.node.label;
      setState(() { _dirty = false; _preview = false; });
    }
  }

  void _onTextChanged() {
    setState(() => _dirty = true);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  void _saveNow() {
    if (!_dirty) return;
    widget.project.writeContent(widget.node.id, _ctrl.text);
    if (mounted) setState(() => _dirty = false);
  }

  void _commitRename() {
    final newLabel = _labelCtrl.text.trim();
    if (newLabel.isNotEmpty && newLabel != widget.node.label) {
      widget.onRename?.call(newLabel);
    }
    setState(() => _renaming = false);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    _ctrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const Divider(),
        _buildToolbar(),
        const Divider(),
        Expanded(child: _preview ? _buildPreview() : _buildEditor()),
        if (_dirty) _buildSaveIndicator(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: FileyColors.bg1,
      child: Row(
        children: [
          // node dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.node.accentColor ?? FileyColors.accent,
            ),
          ),
          const SizedBox(width: 10),

          // label / rename
          Expanded(
            child: _renaming
                ? TextField(
                    controller: _labelCtrl,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _commitRename(),
                    onEditingComplete: _commitRename,
                  )
                : GestureDetector(
                    onDoubleTap: () => setState(() => _renaming = true),
                    child: Text(
                      widget.node.label,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),

          // rename button
          if (!_renaming)
            _IconBtn(
              icon: Icons.edit_outlined,
              tooltip: 'Rename node (double-click label)',
              onTap: () => setState(() => _renaming = true),
            ),

          if (_renaming) ...[
            _IconBtn(icon: Icons.check, tooltip: 'Confirm', onTap: _commitRename),
            _IconBtn(
              icon: Icons.close,
              tooltip: 'Cancel',
              onTap: () {
                _labelCtrl.text = widget.node.label;
                setState(() => _renaming = false);
              },
            ),
          ],

          // close panel
          if (widget.onClose != null)
            _IconBtn(
              icon: Icons.close,
              tooltip: 'Close editor',
              onTap: widget.onClose!,
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: FileyColors.bg1,
      child: Row(
        children: [
          // edit / preview toggle
          _ToggleBtn(label: 'EDIT',    active: !_preview, onTap: () => setState(() => _preview = false)),
          const SizedBox(width: 4),
          _ToggleBtn(label: 'PREVIEW', active:  _preview, onTap: () => setState(() => _preview = true)),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1),
          const SizedBox(width: 12),

          // markdown shortcuts (only in edit mode)
          if (!_preview) ...[
            _MdBtn(label: 'B',  tooltip: 'Bold',   onTap: () => _wrap('**', '**')),
            _MdBtn(label: 'I',  tooltip: 'Italic', onTap: () => _wrap('_', '_')),
            _MdBtn(label: 'H1', tooltip: 'H1',     onTap: () => _insertLine('# ')),
            _MdBtn(label: 'H2', tooltip: 'H2',     onTap: () => _insertLine('## ')),
            _MdBtn(label: '—',  tooltip: 'HR',     onTap: () => _insertLine('\n---\n')),
            _MdBtn(label: '[ ]', tooltip: 'Todo',  onTap: () => _insertLine('- [ ] ')),
          ],

          const Spacer(),

          // save now
          _IconBtn(
            icon: Icons.save_outlined,
            tooltip: 'Save now  (auto-saves on idle)',
            onTap: _saveNow,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: FileyColors.bg0,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 13.5,
          color: FileyColors.textPrimary,
          height: 1.65,
        ),
        cursorColor: FileyColors.accent,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '# Start writing…',
          hintStyle: TextStyle(color: FileyColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      data: _ctrl.text,
      styleSheet: _mdStyleSheet(context),
      padding: const EdgeInsets.all(20),
    );
  }

  Widget _buildSaveIndicator() {
    return Container(
      height: 24,
      color: FileyColors.bg2,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Text(
        'unsaved changes…',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          color: FileyColors.accentDim,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── markdown helpers ─────────────────────────────────────────
  void _wrap(String before, String after) {
    final sel   = _ctrl.selection;
    final text  = _ctrl.text;
    if (!sel.isValid) return;
    final selectedText = sel.textInside(text);
    final newText = text.replaceRange(sel.start, sel.end, '$before$selectedText$after');
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + before.length + selectedText.length + after.length),
    );
  }

  void _insertLine(String prefix) {
    final pos    = _ctrl.selection.baseOffset;
    final text   = _ctrl.text;
    final newText = '${text.substring(0, pos)}\n$prefix${text.substring(pos)}';
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + prefix.length + 1),
    );
  }

  MarkdownStyleSheet _mdStyleSheet(BuildContext ctx) {
    final tt = Theme.of(ctx).textTheme;
    return MarkdownStyleSheet(
      p:          tt.bodyMedium!.copyWith(height: 1.7),
      h1:         tt.displayMedium!.copyWith(color: FileyColors.accent),
      h2:         tt.titleLarge!.copyWith(color: FileyColors.textPrimary),
      h3:         tt.titleMedium!.copyWith(color: FileyColors.textSecondary),
      code:       const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12,
                    backgroundColor: FileyColors.bg2, color: FileyColors.accent),
      blockquoteDecoration: const BoxDecoration(
        color: FileyColors.bg2,
        border: Border(left: BorderSide(color: FileyColors.accentDim, width: 3)),
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FileyColors.border)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Small reusable widgets
// ─────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: FileyColors.textSecondary),
      ),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? FileyColors.accent.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? FileyColors.accent : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: active ? FileyColors.accent : FileyColors.textMuted,
        ),
      ),
    ),
  );
}

class _MdBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  const _MdBtn({required this.label, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(32, 28),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        foregroundColor: FileyColors.textSecondary,
      ),
      child: Text(label,
        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11)),
    ),
  );
}
