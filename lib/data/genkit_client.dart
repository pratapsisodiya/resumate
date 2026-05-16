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

// Renamed internally to Azure OpenAI but keeps class name GenKitClient
// so all providers/imports remain unchanged.
class GenKitClient {
  final String _endpoint;
  final String _apiKey;
  final String _apiVersion;
  final String _deployment;
  late final Dio _dio;

  GenKitClient({
    required String endpoint,
    required String apiKey,
    required String apiVersion,
    required String deploymentName,
  })  : _endpoint = endpoint.endsWith('/') ? endpoint : '$endpoint/',
        _apiKey = apiKey,
        _apiVersion = apiVersion,
        _deployment = deploymentName {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 3),
      headers: {
        'api-key': _apiKey,
        'Content-Type': 'application/json',
      },
    ));
  }

  // ── URL builder ──────────────────────────────────────────────────────────────

  String get _chatUrl =>
      '${_endpoint}openai/deployments/$_deployment/chat/completions?api-version=$_apiVersion';

  // ── Shared chat completion ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _chatCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 8000,
    bool jsonMode = false,
  }) async {
    final body = <String, dynamic>{
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    if (jsonMode) body['response_format'] = {'type': 'json_object'};

    final res = await _dio.post(_chatUrl, data: body);
    return res.data as Map<String, dynamic>;
  }

  // ── Parse resume ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> parseResume(
      String rawText, String fileType) async {
    const systemPrompt = '''You are a professional resume parser. Extract all structured information from the resume text.

Return ONLY a valid JSON object with this exact schema (no markdown, no explanation):
{
  "personalInfo": {
    "fullName": "string",
    "title": "string or null",
    "email": "string",
    "phone": "string or null",
    "location": "string or null",
    "linkedIn": "string or null",
    "github": "string or null",
    "portfolio": "string or null",
    "bio": "string or null"
  },
  "experiences": [
    {
      "company": "string",
      "role": "string",
      "startDate": "ISO date string",
      "endDate": "ISO date string or null",
      "isCurrent": false,
      "description": "string",
      "achievements": ["string"],
      "technologies": ["string"]
    }
  ],
  "education": [
    {
      "institution": "string",
      "degree": "string",
      "field": "string or null",
      "startDate": "ISO date string",
      "endDate": "ISO date string or null",
      "grade": "string or null"
    }
  ],
  "skills": [
    {
      "name": "string",
      "level": "expert|advanced|intermediate|beginner",
      "category": "string or null"
    }
  ],
  "projects": [
    {
      "name": "string",
      "description": "string",
      "url": "string or null",
      "githubUrl": "string or null",
      "technologies": ["string"]
    }
  ],
  "certifications": [
    {
      "name": "string",
      "issuer": "string",
      "issueDate": "ISO date string or null"
    }
  ]
}

Infer dates as YYYY-01-01T00:00:00.000Z if only year is given.
If a section has no data, return an empty array [].''';

    final result = await _chatCompletion(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': 'Parse this resume:\n\n$rawText'},
      ],
      temperature: 0,
      maxTokens: 4000,
      jsonMode: true,
    );

    final content =
        result['choices'][0]['message']['content'] as String;
    return jsonDecode(content) as Map<String, dynamic>;
  }

  // ── Generate website (single call) ───────────────────────────────────────────

  Future<Map<String, dynamic>> generateWebsite(
    Resume resume,
    TemplateStyle template, {
    String? colorPreference,
  }) async {
    final templateDesc = _templateDescription(template);
    final colorHint = colorPreference != null
        ? 'Use $colorPreference as the primary color family.'
        : 'Choose a professional color palette.';

    final systemPrompt =
        '''You are an expert front-end developer specializing in portfolio websites.

Generate a complete, polished, single-page portfolio website for the given resume.

Template style: $templateDesc
Color guidance: $colorHint

Requirements:
- Fully self-contained HTML (inline all CSS in <style> tags, inline JS in <script> tags)
- Mobile-first responsive design with clean breakpoints
- Smooth scroll behavior, subtle entrance animations (CSS keyframes)
- Professional typography using system font stack: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
- Hero section with name, title, bio
- All resume sections: Experience, Education, Skills (with visual indicators), Projects, Certifications
- Contact section with email/phone/social links
- NO placeholder text — use only the real resume data
- Clean, modern aesthetic with good whitespace

Return ONLY a valid JSON object (no markdown fences) with these exact keys:
{
  "htmlContent": "<full HTML document string>",
  "cssContent": "<same CSS extracted as standalone string>",
  "jsContent": "<same JS extracted as standalone string, or null>",
  "colorScheme": {"primary": "#hexcode", "secondary": "#hexcode", "accent": "#hexcode"},
  "modelUsed": "$_deployment",
  "tokensUsed": 0
}''';

    final resumeSummary = _resumeSummary(resume);

    final result = await _chatCompletion(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': 'Generate a portfolio website for:\n\n$resumeSummary'},
      ],
      temperature: 0.7,
      maxTokens: 14000,
      jsonMode: true,
    );

    final content = result['choices'][0]['message']['content'] as String;
    final tokensUsed =
        (result['usage']?['total_tokens'] as num?)?.toInt() ?? 0;

    final json = jsonDecode(content) as Map<String, dynamic>;
    // Inject real token count
    json['tokensUsed'] = tokensUsed;
    json['modelUsed'] = _deployment;
    return json;
  }

  // ── Simulated progress stream (runs alongside the real API call) ──────────────

  Stream<GenerationProgress> generateWebsiteStream(
      Resume resume, TemplateStyle template) async* {
    const stages = [
      (stage: 'Analyzing resume…',  progress: 0.10),
      (stage: 'Choosing design…',   progress: 0.30),
      (stage: 'Writing HTML…',      progress: 0.55),
      (stage: 'Adding styles…',     progress: 0.80),
      (stage: 'Finalizing…',        progress: 0.95),
    ];

    for (final s in stages) {
      yield GenerationProgress(stage: s.stage, progress: s.progress);
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }
  }

  // ── Support chat ──────────────────────────────────────────────────────────────

  Future<String> sendChatMessage(
    String message,
    List<Map<String, String>> history, {
    Map<String, dynamic>? resumeContext,
  }) async {
    final systemContent = resumeContext != null
        ? '''You are a helpful AI assistant for Resumate, an AI portfolio builder app.
The user's resume context: ${jsonEncode(resumeContext)}

Help the user with questions about their resume, portfolio website generation, deployment, or career advice.
Be concise, friendly, and practical.'''
        : '''You are a helpful AI assistant for Resumate, an AI portfolio builder app.
Help users with their resume, portfolio websites, deployment, and career questions.
Be concise, friendly, and practical.''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': message},
    ];

    final result = await _chatCompletion(
      messages: messages,
      temperature: 0.8,
      maxTokens: 1000,
    );

    return result['choices'][0]['message']['content'] as String;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _templateDescription(TemplateStyle t) => switch (t) {
        TemplateStyle.modern =>
          'Modern — clean grid layout, bold headings, gradient hero, card-based sections',
        TemplateStyle.minimal =>
          'Minimal — lots of whitespace, serif headings, muted tones, timeline layout',
        TemplateStyle.creative =>
          'Creative — asymmetric layout, vibrant colors, overlapping elements, expressive typography',
        TemplateStyle.professional =>
          'Professional — traditional business layout, navy/white palette, structured columns',
        TemplateStyle.developer =>
          'Developer — dark theme, monospace font accents, terminal-inspired elements, GitHub-style contribution vibe',
      };

  String _resumeSummary(Resume resume) {
    final buf = StringBuffer();
    final p = resume.personalInfo;
    buf.writeln('Name: ${p.fullName}');
    if (p.title != null) buf.writeln('Title: ${p.title}');
    if (p.email.isNotEmpty) buf.writeln('Email: ${p.email}');
    if (p.phone != null) buf.writeln('Phone: ${p.phone}');
    if (p.location != null) buf.writeln('Location: ${p.location}');
    if (p.linkedIn != null) buf.writeln('LinkedIn: ${p.linkedIn}');
    if (p.github != null) buf.writeln('GitHub: ${p.github}');
    if (p.portfolio != null) buf.writeln('Portfolio: ${p.portfolio}');
    if (p.bio != null) buf.writeln('Bio: ${p.bio}');

    if (resume.experiences.isNotEmpty) {
      buf.writeln('\nEXPERIENCE:');
      for (final e in resume.experiences) {
        buf.writeln('- ${e.role} at ${e.company} (${e.startDate.year}–${e.isCurrent ? 'Present' : (e.endDate?.year ?? '')})');
        buf.writeln('  ${e.description}');
        if (e.achievements.isNotEmpty) buf.writeln('  Achievements: ${e.achievements.join('; ')}');
        if (e.technologies.isNotEmpty) buf.writeln('  Tech: ${e.technologies.join(', ')}');
      }
    }

    if (resume.education.isNotEmpty) {
      buf.writeln('\nEDUCATION:');
      for (final e in resume.education) {
        buf.writeln('- ${e.degree}${e.field != null ? ' in ${e.field}' : ''}, ${e.institution}');
      }
    }

    if (resume.skills.isNotEmpty) {
      buf.writeln('\nSKILLS:');
      buf.writeln(resume.skills.map((s) => '${s.name}${s.level != null ? ' (${s.level})' : ''}').join(', '));
    }

    if (resume.projects.isNotEmpty) {
      buf.writeln('\nPROJECTS:');
      for (final p in resume.projects) {
        buf.writeln('- ${p.name}: ${p.description}');
        if (p.technologies.isNotEmpty) buf.writeln('  Tech: ${p.technologies.join(', ')}');
        if (p.url != null) buf.writeln('  URL: ${p.url}');
        if (p.githubUrl != null) buf.writeln('  GitHub: ${p.githubUrl}');
      }
    }

    if (resume.certifications.isNotEmpty) {
      buf.writeln('\nCERTIFICATIONS:');
      for (final c in resume.certifications) {
        buf.writeln('- ${c.name} by ${c.issuer}');
      }
    }

    return buf.toString();
  }
}
