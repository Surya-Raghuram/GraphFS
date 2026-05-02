import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/graph_model.dart';
import '../services/filey_project.dart';
import '../theme/filey_theme.dart';
import '../widgets/markdown_editor.dart';

class TextEditorScreen extends StatelessWidget {
  final GraphNode node;

  const TextEditorScreen({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final project = context.read<FileyProject>();

    return Scaffold(
      backgroundColor: FileyColors.bg0,
      appBar: AppBar(
        backgroundColor: FileyColors.bg1,
        title: Text(node.label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MarkdownEditor(
        node: node,
        project: project,
        isFullscreen: true,
      ),
    );
  }
}
