import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/ide_provider.dart';
import 'package:resumate/providers/website_provider.dart';
import 'package:resumate/screens/deployment_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IdeScreen extends ConsumerStatefulWidget {
  final Website website;
  const IdeScreen({super.key, required this.website});

  @override
  ConsumerState<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends ConsumerState<IdeScreen> {
  late final WebViewController _webCtrl;
  Timer? _debounce;
  final Map<String, TextEditingController> _editors = {};
  final Map<String, ScrollController> _scrolls = {};

  static const _bg = Color(0xFF1E1E1E);
  static const _lineNum = Color(0xFF858585);

  @override
  void initState() {
    super.initState();
    highlight.registerLanguage('xml', xml);
    highlight.registerLanguage('css', css);
    highlight.registerLanguage('javascript', javascript);

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _editors.values) { c.dispose(); }
    for (final c in _scrolls.values) { c.dispose(); }
    super.dispose();
  }

  TextEditingController _editorFor(String path, String initialContent) {
    return _editors.putIfAbsent(path, () {
      final ctrl = TextEditingController(text: initialContent);
      ctrl.addListener(() {
        ref.read(ideProvider(widget.website).notifier).updateContent(path, ctrl.text);
        _schedulePreviewUpdate();
      });
      return ctrl;
    });
  }

  ScrollController _scrollFor(String path) =>
      _scrolls.putIfAbsent(path, () => ScrollController());

  void _schedulePreviewUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _updatePreview);
  }

  void _updatePreview() {
    final state = ref.read(ideProvider(widget.website));
    final html = state.previewHtml;
    if (html.isEmpty) return;
    _webCtrl.loadRequest(
      Uri.parse('data:text/html;base64,${base64Encode(utf8.encode(html))}'),
    );
  }

  void _deployFromIde() {
    final notifier = ref.read(ideProvider(widget.website).notifier);
    final updated = notifier.toWebsite(widget.website);
    ref.read(websiteProvider.notifier).updateFromIde(updated);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeploymentScreen(website: updated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ideState = ref.watch(ideProvider(widget.website));
    final notifier = ref.read(ideProvider(widget.website).notifier);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _TitleBar(
            filename: ideState.activeFile?.filename ?? '',
            showExplorer: ideState.showExplorer,
            showPreview: ideState.showPreview,
            onToggleExplorer: notifier.toggleExplorer,
            onTogglePreview: notifier.togglePreview,
            onDeploy: _deployFromIde,
          ),
          _TabRow(
            files: ideState.files.values.toList(),
            activeFile: ideState.activeFile,
            onSelect: notifier.selectFile,
          ),
          Expanded(
            child: Row(
              children: [
                if (ideState.showExplorer)
                  _FileExplorer(
                    files: ideState.files.values.toList(),
                    activeFile: ideState.activeFile,
                    onSelect: notifier.selectFile,
                  ),
                Expanded(
                  child: ideState.activeFile == null
                      ? const Center(
                          child: Text('No file selected',
                              style: TextStyle(color: _lineNum)))
                      : _EditorPanel(
                          file: ideState.activeFile!,
                          editorCtrl: _editorFor(
                              ideState.activeFilePath,
                              ideState.activeFile!.content),
                          scrollCtrl: _scrollFor(ideState.activeFilePath),
                        ),
                ),
                if (ideState.showPreview)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: _PreviewPanel(controller: _webCtrl),
                  ),
              ],
            ),
          ),
          _StatusBar(file: ideState.activeFile),
        ],
      ),
    );
  }
}

// ── Title bar ─────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  final String filename;
  final bool showExplorer, showPreview;
  final VoidCallback onToggleExplorer, onTogglePreview, onDeploy;

  const _TitleBar({
    required this.filename,
    required this.showExplorer,
    required this.showPreview,
    required this.onToggleExplorer,
    required this.onTogglePreview,
    required this.onDeploy,
  });

  static const _bg = Color(0xFF323233);
  static const _text = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _btn(Icons.menu, 'Explorer', onToggleExplorer,
              active: showExplorer),
          _btn(Icons.preview, 'Preview', onTogglePreview,
              active: showPreview),
          const Spacer(),
          Text('Resumate IDE',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _text, fontWeight: FontWeight.w500)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.rocket_launch, size: 14, color: Colors.white),
            label: const Text('Deploy',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onDeploy,
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String tip, VoidCallback onTap, {bool active = false}) =>
      Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF858585)),
          ),
        ),
      );
}

// ── Tab row ───────────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  final List<WebsiteFile> files;
  final WebsiteFile? activeFile;
  final void Function(String) onSelect;

  const _TabRow({required this.files, required this.activeFile, required this.onSelect});

  static const _bg = Color(0xFF2D2D2D);
  static const _active = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      color: _bg,
      child: Row(
        children: files.map((f) {
          final isActive = f.path == activeFile?.path;
          return GestureDetector(
            onTap: () => onSelect(f.path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? _active : Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: isActive
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f.filename,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isActive
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF969696))),
                  if (f.isModified) ...[
                    const SizedBox(width: 4),
                    const CircleAvatar(
                        radius: 3, backgroundColor: Color(0xFFE2C08D)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── File explorer ─────────────────────────────────────────────────────────────

class _FileExplorer extends StatelessWidget {
  final List<WebsiteFile> files;
  final WebsiteFile? activeFile;
  final void Function(String) onSelect;

  const _FileExplorer(
      {required this.files, required this.activeFile, required this.onSelect});

  static const _bg = Color(0xFF252526);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Text('EXPLORER',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
          ),
          ...files.map((f) {
            final active = f.path == activeFile?.path;
            return InkWell(
              onTap: () => onSelect(f.path),
              child: Container(
                color: active
                    ? const Color(0xFF37373D)
                    : Colors.transparent,
                padding: const EdgeInsets.fromLTRB(24, 4, 8, 4),
                child: Row(
                  children: [
                    Icon(_iconFor(f.language), size: 14, color: _colorFor(f.language)),
                    const SizedBox(width: 6),
                    Text(
                      f.filename,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: active
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC)),
                    ),
                    if (f.isModified) ...[
                      const Spacer(),
                      const CircleAvatar(
                          radius: 3, backgroundColor: Color(0xFFE2C08D)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconFor(FileLanguage lang) => switch (lang) {
        FileLanguage.html => Icons.html,
        FileLanguage.css => Icons.css,
        FileLanguage.javascript => Icons.javascript,
        _ => Icons.insert_drive_file_outlined,
      };

  Color _colorFor(FileLanguage lang) => switch (lang) {
        FileLanguage.html => const Color(0xFFE44D26),
        FileLanguage.css => const Color(0xFF264DE4),
        FileLanguage.javascript => const Color(0xFFF0DB4F),
        _ => const Color(0xFF969696),
      };
}

// ── Editor panel ──────────────────────────────────────────────────────────────

class _EditorPanel extends StatelessWidget {
  final WebsiteFile file;
  final TextEditingController editorCtrl;
  final ScrollController scrollCtrl;

  const _EditorPanel({
    required this.file,
    required this.editorCtrl,
    required this.scrollCtrl,
  });

  static const _bg = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Row(
        children: [
          _LineGutter(ctrl: editorCtrl, scrollCtrl: scrollCtrl),
          Expanded(
            child: Stack(
              children: [
                // Syntax highlight layer
                SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
                    child: _SyntaxHighlightView(
                      source: editorCtrl.text,
                      language: file.language,
                    ),
                  ),
                ),
                // Transparent input layer
                TextField(
                  controller: editorCtrl,
                  scrollController: scrollCtrl,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: Colors.transparent,
                    height: 1.5,
                  ),
                  cursorColor: const Color(0xFFAEAFAD),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(4, 10, 8, 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineGutter extends StatefulWidget {
  final TextEditingController ctrl;
  final ScrollController scrollCtrl;

  const _LineGutter({required this.ctrl, required this.scrollCtrl});

  @override
  State<_LineGutter> createState() => _LineGutterState();
}

class _LineGutterState extends State<_LineGutter> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final lines = (widget.ctrl.text.split('\n').length).clamp(1, 9999);
    return Container(
      width: 42,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          lines,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
            child: Text(
              '${i + 1}',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  height: 1.5,
                  color: const Color(0xFF858585)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Syntax highlight ──────────────────────────────────────────────────────────

class _SyntaxHighlightView extends StatelessWidget {
  final String source;
  final FileLanguage language;

  const _SyntaxHighlightView({required this.source, required this.language});

  static const _colors = <String, Color>{
    'keyword': Color(0xFF569CD6),
    'built_in': Color(0xFF4EC9B0),
    'type': Color(0xFF4EC9B0),
    'literal': Color(0xFF569CD6),
    'number': Color(0xFFB5CEA8),
    'string': Color(0xFFCE9178),
    'comment': Color(0xFF6A9955),
    'tag': Color(0xFF569CD6),
    'attr': Color(0xFF9CDCFE),
    'name': Color(0xFF4EC9B0),
    'selector-tag': Color(0xFFD7BA7D),
    'selector-class': Color(0xFFD7BA7D),
    'selector-id': Color(0xFFD7BA7D),
    'property': Color(0xFF9CDCFE),
    'variable': Color(0xFF9CDCFE),
    'function': Color(0xFFDCDCAA),
    'title': Color(0xFFDCDCAA),
    'params': Color(0xFFD4D4D4),
    'deletion': Color(0xFFF44747),
    'addition': Color(0xFFB5CEA8),
  };

  static const _defaultColor = Color(0xFFD4D4D4);

  @override
  Widget build(BuildContext context) {
    final lang = switch (language) {
      FileLanguage.html => 'xml',
      FileLanguage.css => 'css',
      FileLanguage.javascript => 'javascript',
      _ => null,
    };

    if (lang == null) {
      return Text(source,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13, height: 1.5, color: _defaultColor));
    }

    final result = highlight.parse(source, language: lang);
    final spans = _buildSpans(result.nodes ?? []);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.jetBrainsMono(
            fontSize: 13, height: 1.5, color: _defaultColor),
        children: spans,
      ),
    );
  }

  List<TextSpan> _buildSpans(List<Node> nodes) {
    final spans = <TextSpan>[];
    for (final node in nodes) {
      if (node.value != null) {
        final color = node.className != null
            ? _colors[node.className!] ?? _defaultColor
            : _defaultColor;
        spans.add(TextSpan(text: node.value, style: TextStyle(color: color)));
      } else if (node.children != null) {
        final childColor =
            node.className != null ? _colors[node.className!] : null;
        final childSpans = _buildSpans(node.children!);
        spans.add(TextSpan(
          style: childColor != null ? TextStyle(color: childColor) : null,
          children: childSpans,
        ));
      }
    }
    return spans;
  }
}

// ── Preview panel ─────────────────────────────────────────────────────────────

class _PreviewPanel extends StatelessWidget {
  final WebViewController controller;

  const _PreviewPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: WebViewWidget(controller: controller),
    );
  }
}

// ── Status bar ────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final WebsiteFile? file;

  const _StatusBar({this.file});

  @override
  Widget build(BuildContext context) {
    final lang = file == null
        ? ''
        : switch (file!.language) {
            FileLanguage.html => 'HTML',
            FileLanguage.css => 'CSS',
            FileLanguage.javascript => 'JavaScript',
            _ => 'Plain Text',
          };

    return Container(
      height: 22,
      color: const Color(0xFF007ACC),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.code, size: 12, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Resumate IDE',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
          ),
          const Spacer(),
          if (file != null) ...[
            Text(
              '${file!.content.split('\n').length} lines',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(lang,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
            const SizedBox(width: 16),
            Text('UTF-8',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
            if (file!.isModified) ...[
              const SizedBox(width: 16),
              Text('● Modified',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFE2C08D))),
            ],
          ],
        ],
      ),
    );
  }
}
