import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/data/genkit_client.dart';
import 'package:resumate/data/local_storage.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:uuid/uuid.dart';

// ── Website generation state ──────────────────────────────────────────────────

sealed class WebsiteState {
  const WebsiteState();
}

class WebsiteInitial extends WebsiteState {
  const WebsiteInitial();
}

class WebsiteGenerating extends WebsiteState {
  final String stage;
  final double progress;
  const WebsiteGenerating({this.stage = '', this.progress = 0});
}

class WebsiteReady extends WebsiteState {
  final Website website;
  const WebsiteReady(this.website);
}

class WebsiteError extends WebsiteState {
  final String message;
  const WebsiteError(this.message);
}

// ── WebsiteNotifier ───────────────────────────────────────────────────────────

class WebsiteNotifier extends StateNotifier<WebsiteState> {
  final LocalStorage _storage;
  final GenKitClient _genKit;

  WebsiteNotifier(this._storage, this._genKit) : super(const WebsiteInitial()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.loadWebsite();
      if (raw != null) {
        final json = Map<String, dynamic>.from(raw);
        state = WebsiteReady(_websiteFromJson(json));
      }
    } catch (_) {}
  }

  Future<void> generate(
    Resume resume,
    TemplateStyle template, {
    String? colorPreference,
    bool streaming = true,
  }) async {
    state = const WebsiteGenerating(stage: 'Analyzing resume…', progress: 0.05);
    try {
      if (streaming) {
        await for (final progress in _genKit.generateWebsiteStream(resume, template)) {
          if (!mounted) return;
          state = WebsiteGenerating(stage: progress.stage, progress: progress.progress);
        }
      }
      final json = await _genKit.generateWebsite(resume, template,
          colorPreference: colorPreference);
      final website = Website(
        id: const Uuid().v4(),
        name: _slug(resume.personalInfo.fullName),
        sourceResume: resume,
        template: template,
        colorScheme: json['colorScheme'] != null
            ? ColorScheme.fromJson(Map<String, dynamic>.from(json['colorScheme'] as Map))
            : const ColorScheme(),
        htmlContent: json['htmlContent'] as String? ?? '',
        cssContent: json['cssContent'] as String?,
        jsContent: json['jsContent'] as String?,
        modelUsed: json['modelUsed'] as String? ?? 'claude-3.5-sonnet',
        tokensUsed: json['tokensUsed'] as int? ?? 0,
        generatedAt: DateTime.now(),
      );
      await _storage.saveWebsite(_websiteToJson(website));
      state = WebsiteReady(website);
    } catch (e) {
      state = WebsiteError(e.toString());
    }
  }

  void updateFromIde(Website website) {
    state = WebsiteReady(website);
    _storage.saveWebsite(_websiteToJson(website));
  }

  void reset() => state = const WebsiteInitial();

  static String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

  static Website _websiteFromJson(Map<String, dynamic> j) => Website(
        id: j['id'] as String? ?? const Uuid().v4(),
        name: j['name'] as String? ?? '',
        sourceResume: Resume.fromJson(j['sourceResume'] as Map<String, dynamic>? ?? {}),
        template: TemplateStyle.values.firstWhere(
          (t) => t.name == (j['template'] as String?),
          orElse: () => TemplateStyle.modern,
        ),
        colorScheme: j['colorScheme'] != null
            ? ColorScheme.fromJson(Map<String, dynamic>.from(j['colorScheme'] as Map))
            : const ColorScheme(),
        htmlContent: j['htmlContent'] as String? ?? '',
        cssContent: j['cssContent'] as String?,
        jsContent: j['jsContent'] as String?,
        modelUsed: j['modelUsed'] as String? ?? '',
        tokensUsed: j['tokensUsed'] as int? ?? 0,
        generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
      );

  static Map<String, dynamic> _websiteToJson(Website w) => {
        'id': w.id,
        'name': w.name,
        'sourceResume': w.sourceResume.toJson(),
        'template': w.template.name,
        'colorScheme': {
          'primary': w.colorScheme.primary,
          'secondary': w.colorScheme.secondary,
          'accent': w.colorScheme.accent,
        },
        'htmlContent': w.htmlContent,
        'cssContent': w.cssContent,
        'jsContent': w.jsContent,
        'modelUsed': w.modelUsed,
        'tokensUsed': w.tokensUsed,
        'generatedAt': w.generatedAt.toIso8601String(),
      };
}

final websiteProvider = StateNotifierProvider<WebsiteNotifier, WebsiteState>(
  (ref) => WebsiteNotifier(
    ref.watch(localStorageProvider),
    ref.watch(genKitClientProvider),
  ),
);
