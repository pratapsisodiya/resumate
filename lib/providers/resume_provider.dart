import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/data/genkit_client.dart';
import 'package:resumate/data/local_storage.dart';
import 'package:resumate/models/resume.dart';
import 'package:uuid/uuid.dart';

final localStorageProvider = Provider<LocalStorage>((_) => LocalStorage());

final genKitClientProvider = Provider<GenKitClient>((_) => GenKitClient(
      endpoint: const String.fromEnvironment(
        'AZURE_OPENAI_ENDPOINT',
        defaultValue: 'https://your-endpoint.openai.azure.com/',
      ),
      apiKey: const String.fromEnvironment(
        'AZURE_OPENAI_API_KEY',
        defaultValue: 'your-api-key-here',
      ),
      apiVersion: const String.fromEnvironment(
        'AZURE_OPENAI_API_VERSION',
        defaultValue: '2024-12-01-preview',
      ),
      deploymentName: const String.fromEnvironment(
        'AZURE_DEPLOYMENT_NAME',
        defaultValue: 'gpt-4-turbo',
      ),
    ));

// ── Resume state ──────────────────────────────────────────────────────────────

sealed class ResumeState {
  const ResumeState();
}

class ResumeInitial extends ResumeState {
  const ResumeInitial();
}

class ResumeLoading extends ResumeState {
  const ResumeLoading();
}

class ResumeLoaded extends ResumeState {
  final Resume resume;
  const ResumeLoaded(this.resume);
}

class ResumeError extends ResumeState {
  final String message;
  const ResumeError(this.message);
}

// ── ResumeNotifier ────────────────────────────────────────────────────────────

class ResumeNotifier extends StateNotifier<ResumeState> {
  final LocalStorage _storage;
  final GenKitClient _genKit;

  ResumeNotifier(this._storage, this._genKit) : super(const ResumeInitial()) {
    _load();
  }

  Future<void> _load() async {
    state = const ResumeLoading();
    try {
      final raw = await _storage.loadResume();
      if (raw != null) {
        state = ResumeLoaded(
          Resume.fromJson(Map<String, dynamic>.from(raw)),
        );
      } else {
        state = const ResumeInitial();
      }
    } catch (e) {
      state = ResumeError(e.toString());
    }
  }

  Future<void> parseFromText(String rawText, {String fileType = 'text'}) async {
    state = const ResumeLoading();
    try {
      final json = await _genKit.parseResume(rawText, fileType);
      final resume = Resume.fromJson({
        ...json,
        'id': const Uuid().v4(),
        'rawText': rawText,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      await _storage.saveResume(resume.toJson());
      state = ResumeLoaded(resume);
    } catch (e) {
      state = ResumeError(e.toString());
    }
  }

  Future<void> save(Resume resume) async {
    await _storage.saveResume(resume.toJson());
    state = ResumeLoaded(resume);
  }

  Future<void> delete() async {
    await _storage.deleteResume();
    state = const ResumeInitial();
  }

  void update(Resume resume) => state = ResumeLoaded(resume);
}

final resumeProvider = StateNotifierProvider<ResumeNotifier, ResumeState>(
  (ref) => ResumeNotifier(
    ref.watch(localStorageProvider),
    ref.watch(genKitClientProvider),
  ),
);
