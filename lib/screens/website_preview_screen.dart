import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/screens/deployment_screen.dart';
import 'package:resumate/screens/ide_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebsitePreviewScreen extends ConsumerStatefulWidget {
  final Website website;
  const WebsitePreviewScreen({super.key, required this.website});

  @override
  ConsumerState<WebsitePreviewScreen> createState() =>
      _WebsitePreviewScreenState();
}

class _WebsitePreviewScreenState extends ConsumerState<WebsitePreviewScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _ctrl;
  late final TabController _deviceTab;
  bool _loading = true;

  // Device frames
  static const _devices = ['Desktop', 'Tablet', 'Mobile'];
  static const _deviceWidths = [double.infinity, 768.0, 375.0];

  @override
  void initState() {
    super.initState();
    _deviceTab = TabController(length: _devices.length, vsync: this);
    _deviceTab.addListener(() => setState(() {}));

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(
        'data:text/html;base64,${base64Encode(utf8.encode(_inlinedHtml))}',
      ));
  }

  @override
  void dispose() {
    _deviceTab.dispose();
    super.dispose();
  }

  /// Inline CSS/JS into the HTML for self-contained preview.
  String get _inlinedHtml {
    var html = widget.website.htmlContent;
    final css = widget.website.cssContent;
    final js  = widget.website.jsContent;
    if (css != null) {
      html = html.replaceFirst(
        RegExp(r'<link[^>]*styles\.css[^>]*>'),
        '<style>$css</style>',
      );
      if (!html.contains('<style>$css</style>')) {
        html = html.replaceFirst('</head>', '<style>$css</style></head>');
      }
    }
    if (js != null) {
      html = html.replaceFirst(
        RegExp(r'<script[^>]*script\.js[^>]*></script>'),
        '<script>$js</script>',
      );
      if (!html.contains('<script>$js</script>')) {
        html = html.replaceFirst('</body>', '<script>$js</script></body>');
      }
    }
    return html;
  }

  double get _frameWidth {
    final idx = _deviceTab.index;
    if (_deviceWidths[idx] == double.infinity) return double.infinity;
    final screenW = MediaQuery.of(context).size.width - 32;
    return _deviceWidths[idx] > screenW ? screenW : _deviceWidths[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _PreviewAppBar(
        website: widget.website,
        deviceTab: _deviceTab,
        devices: _devices,
        onEdit: () => Navigator.push(context,
            SlideRightRoute(child: IdeScreen(website: widget.website))),
        onDeploy: () => Navigator.push(context,
            SlideUpRoute(child: DeploymentScreen(website: widget.website))),
      ),
      body: Column(
        children: [
          // Browser chrome
          _BrowserBar(url: '${widget.website.name}.vercel.app'),

          // Device frame + webview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _frameWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      _deviceTab.index == 2 ? 24 : 12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _ctrl),
                      if (_loading)
                        const ColoredBox(
                          color: Colors.white,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(
        onEdit: () => Navigator.push(context,
            SlideRightRoute(child: IdeScreen(website: widget.website))),
        onDeploy: () => Navigator.push(context,
            SlideUpRoute(child: DeploymentScreen(website: widget.website))),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _PreviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Website website;
  final TabController deviceTab;
  final List<String> devices;
  final VoidCallback onEdit;
  final VoidCallback onDeploy;

  const _PreviewAppBar({
    required this.website,
    required this.deviceTab,
    required this.devices,
    required this.onEdit,
    required this.onDeploy,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview'),
          Text(website.name,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF6B7280))),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit in IDE',
          onPressed: onEdit,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded, size: 15),
            label: const Text('Deploy'),
            onPressed: onDeploy,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: deviceTab,
        tabs: devices.map((d) => Tab(text: d)).toList(),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

// ── Browser chrome bar ────────────────────────────────────────────────────────

class _BrowserBar extends StatelessWidget {
  final String url;
  const _BrowserBar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

// ── Bottom actions ────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDeploy;

  const _BottomActions({required this.onEdit, required this.onDeploy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.code_rounded, size: 16),
              label: const Text('Open IDE'),
              onPressed: onEdit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
              label: const Text('Deploy Now'),
              onPressed: onDeploy,
            ),
          ),
        ],
      ),
    );
  }
}
