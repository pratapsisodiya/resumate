import 'package:resumate/models/resume.dart';

enum TemplateStyle { modern, minimal, creative, professional, developer }

class ColorScheme {
  final String primary;
  final String secondary;
  final String accent;

  const ColorScheme({
    this.primary = '#3B82F6',
    this.secondary = '#1E293B',
    this.accent = '#F59E0B',
  });

  factory ColorScheme.fromJson(Map<String, dynamic> j) => ColorScheme(
        primary: j['primary'] as String? ?? '#3B82F6',
        secondary: j['secondary'] as String? ?? '#1E293B',
        accent: j['accent'] as String? ?? '#F59E0B',
      );
}

class Website {
  final String id;
  final String name;
  final Resume sourceResume;
  final TemplateStyle template;
  final ColorScheme colorScheme;
  final String htmlContent;
  final String? cssContent;
  final String? jsContent;
  final String modelUsed;
  final int tokensUsed;
  final DateTime generatedAt;

  const Website({
    required this.id,
    required this.name,
    required this.sourceResume,
    required this.template,
    required this.colorScheme,
    required this.htmlContent,
    this.cssContent,
    this.jsContent,
    this.modelUsed = 'claude-3.5-sonnet',
    this.tokensUsed = 0,
    required this.generatedAt,
  });

  Website copyWith({
    String? htmlContent,
    String? cssContent,
    String? jsContent,
  }) =>
      Website(
        id: id,
        name: name,
        sourceResume: sourceResume,
        template: template,
        colorScheme: colorScheme,
        htmlContent: htmlContent ?? this.htmlContent,
        cssContent: cssContent ?? this.cssContent,
        jsContent: jsContent ?? this.jsContent,
        modelUsed: modelUsed,
        tokensUsed: tokensUsed,
        generatedAt: generatedAt,
      );
}

// Files shown in IDE
enum FileLanguage { html, css, javascript, json, unknown }

class WebsiteFile {
  final String path;
  String content;
  final FileLanguage language;
  bool isModified;

  WebsiteFile({
    required this.path,
    required this.content,
    required this.language,
    this.isModified = false,
  });

  String get filename => path.split('/').last;

  static FileLanguage langFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'html' || 'htm' => FileLanguage.html,
      'css'           => FileLanguage.css,
      'js'            => FileLanguage.javascript,
      'json'          => FileLanguage.json,
      _               => FileLanguage.unknown,
    };
  }
}
