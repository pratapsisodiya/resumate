import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/data/credential_storage.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/providers/deployment_provider.dart';

class CredentialsState {
  final List<String> platforms;
  final bool loading;
  const CredentialsState({this.platforms = const [], this.loading = false});
  CredentialsState copyWith({List<String>? platforms, bool? loading}) =>
      CredentialsState(
        platforms: platforms ?? this.platforms,
        loading: loading ?? this.loading,
      );
}

class CredentialsNotifier extends StateNotifier<CredentialsState> {
  final CredentialStorage _storage;

  CredentialsNotifier(this._storage) : super(const CredentialsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final platforms = await _storage.storedPlatforms();
    state = CredentialsState(platforms: platforms);
  }

  Future<void> save(PlatformCredentials creds) async {
    await _storage.save(creds);
    await load();
  }

  Future<void> delete(String platform) async {
    await _storage.delete(platform);
    await load();
  }

  Future<PlatformCredentials?> get(String platform) => _storage.load(platform);
}

final credentialsProvider =
    StateNotifierProvider<CredentialsNotifier, CredentialsState>(
  (ref) => CredentialsNotifier(ref.watch(credentialStorageProvider)),
);
