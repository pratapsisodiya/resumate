import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/website.dart';

class IdeState {
  final Map<String, WebsiteFile> files;
  final String activeFilePath;
  final bool showExplorer;
  final bool showPreview;

  const IdeState({
    required this.files,
    required this.activeFilePath,
    this.showExplorer = true,
    this.showPreview = true,
  });

  WebsiteFile? get activeFile => files[activeFilePath];

  String get previewHtml {
    final html = files['index.html']?.content ?? '';
    final css = files['styles.css']?.content;
    final js = files['script.js']?.content;
    if (css == null && js == null) return html;
    // Inline CSS/JS if stored separately
    return html
        .replaceFirst(
          RegExp(r'<link[^>]*styles\.css[^>]*>'),
          css != null ? '<style>$css</style>' : '',
        )
        .replaceFirst(
          RegExp(r'<script[^>]*script\.js[^>]*></script>'),
          js != null ? '<script>$js</script>' : '',
        );
  }

  IdeState copyWith({
    Map<String, WebsiteFile>? files,
    String? activeFilePath,
    bool? showExplorer,
    bool? showPreview,
  }) =>
      IdeState(
        files: files ?? this.files,
        activeFilePath: activeFilePath ?? this.activeFilePath,
        showExplorer: showExplorer ?? this.showExplorer,
        showPreview: showPreview ?? this.showPreview,
      );
}

class IdeNotifier extends StateNotifier<IdeState> {
  IdeNotifier(Website website)
      : super(_fromWebsite(website));

  static IdeState _fromWebsite(Website w) {
    final files = <String, WebsiteFile>{
      'index.html': WebsiteFile(
        path: 'index.html',
        content: w.htmlContent,
        language: FileLanguage.html,
      ),
      if (w.cssContent != null)
        'styles.css': WebsiteFile(
          path: 'styles.css',
          content: w.cssContent!,
          language: FileLanguage.css,
        ),
      if (w.jsContent != null)
        'script.js': WebsiteFile(
          path: 'script.js',
          content: w.jsContent!,
          language: FileLanguage.javascript,
        ),
    };
    return IdeState(files: files, activeFilePath: 'index.html');
  }

  void selectFile(String path) {
    if (state.files.containsKey(path)) {
      state = state.copyWith(activeFilePath: path);
    }
  }

  void updateContent(String path, String content) {
    final file = state.files[path];
    if (file == null) return;
    file.content = content;
    file.isModified = true;
    state = state.copyWith(files: Map.from(state.files));
  }

  void toggleExplorer() => state = state.copyWith(showExplorer: !state.showExplorer);
  void togglePreview() => state = state.copyWith(showPreview: !state.showPreview);

  Website toWebsite(Website original) => original.copyWith(
        htmlContent: state.files['index.html']?.content ?? original.htmlContent,
        cssContent: state.files['styles.css']?.content,
        jsContent: state.files['script.js']?.content,
      );
}

// Scoped per IDE session — created with .family
final ideProvider =
    StateNotifierProvider.family<IdeNotifier, IdeState, Website>(
  (ref, website) => IdeNotifier(website),
);
