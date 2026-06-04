import re

with open("flutter_app/lib/widgets/markdown_editor.dart", "r") as f:
    code = f.read()

code = code.replace("import 'package:flutter_markdown/flutter_markdown.dart';", "import 'package:flutter_markdown/flutter_markdown.dart';\nimport 'dart:io';\nimport 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';")

build_method = """  Widget build(BuildContext context) {
    bool isPdf = widget.node.contentFile.toLowerCase().endsWith('.pdf');
    bool isImage = widget.node.contentFile.toLowerCase().endsWith('.png') || widget.node.contentFile.toLowerCase().endsWith('.jpg') || widget.node.contentFile.toLowerCase().endsWith('.jpeg') || widget.node.contentFile.toLowerCase().endsWith('.gif');
    bool isTxt = widget.node.contentFile.toLowerCase().endsWith('.txt');
    bool isMd = widget.node.contentFile.toLowerCase().endsWith('.md');
    bool isEditable = isMd || isTxt;

    return Container(
      color: FileyColors.bg0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(),
          if (isEditable) _buildToolbar(),
          if (isEditable) const Divider(),
          Expanded(child: widget.isFullscreen ? (_showPreview ? _buildPreview() : _buildEditor()) : _buildPreview()),
        ],
      ),
    );
  }"""

code = re.sub(r"  Widget build\(BuildContext context\) \{.*?    \);\n  \}", build_method, code, flags=re.DOTALL)

build_preview = """  Widget _buildPreview() {
    bool isPdf = widget.node.contentFile.toLowerCase().endsWith('.pdf');
    bool isImage = widget.node.contentFile.toLowerCase().endsWith('.png') || widget.node.contentFile.toLowerCase().endsWith('.jpg') || widget.node.contentFile.toLowerCase().endsWith('.jpeg') || widget.node.contentFile.toLowerCase().endsWith('.gif');
    bool isTxt = widget.node.contentFile.toLowerCase().endsWith('.txt');

    if (isPdf) {
      String path = widget.project.nodeFilePath(widget.node.id);
      return SfPdfViewer.file(File(path));
    } else if (isImage) {
      String path = widget.project.nodeFilePath(widget.node.id);
      return InteractiveViewer(child: Image.file(File(path)));
    } else if (isTxt) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(_ctrl.text, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: FileyColors.textPrimary)),
      );
    }

    return Markdown(
      data: _ctrl.text,
      styleSheet: _mdStyleSheet(context),
      padding: const EdgeInsets.all(20),
    );
  }"""
code = re.sub(r"  Widget _buildPreview\(\) \{.*?    \);\n  \}", build_preview, code, flags=re.DOTALL)

with open("flutter_app/lib/widgets/markdown_editor.dart", "w") as f:
    f.write(code)

