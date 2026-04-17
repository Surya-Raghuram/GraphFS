import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/filey_project.dart';
import '../theme/filey_theme.dart';
import 'editor_screen.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────
//  HomeScreen  –  landing page with create / open actions
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  Future<void> _createProject() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder for your new project',
    );
    if (dir == null || !mounted) return;

    final name = await _promptName();
    if (name == null || !mounted) return;

    // Clean the path just in case Linux handed us a URI
    final safeDir = dir.replaceFirst('file://', '').trim();
    final path = '$safeDir/$name';

    try {
      // 1. Let Dart handle OS-level folder creation
      final newDir = Directory(path);
      if (!newDir.existsSync()) {
        await newDir.create(recursive: true);
      }

      setState(() => _busy = true);
      final project = context.read<FileyProject>();
      
      // 2. Use C++ open() instead of create(). 
      // Your C++ open() is already programmed to initialize empty folders!
      final ok = await project.open(path);
      setState(() => _busy = false);

      if (!ok && mounted) {
        _showError('Folder created, but C++ core rejected it.');
        return;
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EditorScreen()),
        );
      }
    } catch (e) {
      setState(() => _busy = false);
      // This will instantly show EXACTLY what Linux is complaining about!
      _showError('OS Error creating directory:\n$e'); 
    }
  }

  Future<void> _openProject() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Open a Filey project folder',
    );
    if (dir == null || !mounted) return;

    final safeDir = dir.replaceFirst('file://', '').trim();

    setState(() => _busy = true);
    final project = context.read<FileyProject>();
    final ok = await project.open(safeDir);
    setState(() => _busy = false);

    if (!ok && mounted) {
      _showError('Could not open project at $safeDir.\nMake sure it is a valid Filey project folder.');
      return;
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    }
  }

  Future<String?> _promptName() async {
    final ctrl = TextEditingController(text: 'notes_1');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FileyColors.bg2,
        title: const Text('Project name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. research_2025',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FileyColors.bg2,
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FileyColors.bg0,
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SizedBox(
              width: 460,
              child: _busy
                  ? const Center(child: CircularProgressIndicator(color: FileyColors.accent))
                  : _buildCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    // Subtle grid overlay on the landing page
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo / wordmark
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'FILE',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: FileyColors.textPrimary,
                  letterSpacing: -2,
                ),
              ),
              TextSpan(
                text: 'Y',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: FileyColors.accent,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'markdown mind maps  |  connected thoughts',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: FileyColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 52),

        // Actions
        _ActionCard(
          icon: Icons.add_circle_outline_rounded,
          title: 'New Project',
          subtitle: 'Create a fresh Filey project folder',
          onTap: _createProject,
          highlight: true,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.folder_open_outlined,
          title: 'Open Project',
          subtitle: 'Open an existing .fileydir folder',
          onTap: _openProject,
        ),

        const SizedBox(height: 40),
        const Text(
          'v2.0  ·  C++ core + Flutter frontend',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            color: FileyColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  _ActionCard
// ─────────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _hovered
        ? (widget.highlight ? FileyColors.accent : FileyColors.borderL)
        : FileyColors.border;
    final bgColor = _hovered ? FileyColors.bg2 : FileyColors.bg1;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                size: 28,
                color: widget.highlight ? FileyColors.accent : FileyColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FileyColors.textPrimary,
                      )),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: FileyColors.textMuted,
                      )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                color: _hovered ? FileyColors.accent : FileyColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Background grid painter for landing page
// ─────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FileyColors.border.withOpacity(0.35)
      ..strokeWidth = 0.5;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, FileyColors.bg0.withOpacity(0.85)],
        radius: 0.75,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }
  @override
  bool shouldRepaint(_) => false;
}
