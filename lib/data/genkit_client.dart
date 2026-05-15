import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/models/website.dart';

class GenerationProgress {
  final String stage;
  final double progress;
  const GenerationProgress({required this.stage, required this.progress});
}

class GenKitClient {
  final Dio _dio;

  GenKitClient({required String baseUrl, required String apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': 'Bearer $apiKey'},
          connectTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 3),
        ));

  Future<Map<String, dynamic>> parseResume(String rawText, String fileType) async {
    final res = await _dio.post('/parseResume', data: {'rawText': rawText, 'fileType': fileType});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateWebsite(
    Resume resume,
    TemplateStyle template, {
    String? colorPreference,
  }) async {
    final res = await _dio.post('/generateWebsite', data: {
      'resume': resume.toJson(),
      'template': template.name,
      'options': {
        'language': 'en',
        if (colorPreference != null) 'colorPreference': colorPreference,
        'includeContactForm': true,
        'darkMode': true,
        'animations': 'subtle',
      },
    });
    return res.data as Map<String, dynamic>;
  }

  Stream<GenerationProgress> generateWebsiteStream(Resume resume, TemplateStyle template) async* {
    final res = await _dio.post(
      '/generateWebsiteStream',
      data: {'resume': resume.toJson(), 'template': template.name},
      options: Options(responseType: ResponseType.stream),
    );
    final stream = res.data.stream as Stream<List<int>>;
    await for (final chunk in stream) {
      for (final line in utf8.decode(chunk).split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final raw = line.substring(6).trim();
        if (raw.isEmpty || raw == '[DONE]') continue;
        try {
          final d = jsonDecode(raw) as Map<String, dynamic>;
          yield GenerationProgress(
            stage: d['stage'] as String? ?? '',
            progress: (d['progress'] as num?)?.toDouble() ?? 0,
          );
        } catch (_) {}
      }
    }
  }

  Future<String> sendChatMessage(
    String message,
    List<Map<String, String>> history, {
    Map<String, dynamic>? resumeContext,
  }) async {
    final res = await _dio.post('/supportChat', data: {
      'message': message,
      'history': history,
      if (resumeContext != null) 'resumeContext': resumeContext,
    });
    return res.data['text'] as String;
  }
}
