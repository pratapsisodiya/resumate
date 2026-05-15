import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/data/credential_storage.dart';
import 'package:resumate/data/github_client.dart';
import 'package:resumate/data/netlify_client.dart';
import 'package:resumate/data/vercel_client.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/models/website.dart';

// ── Deployment state ──────────────────────────────────────────────────────────

sealed class DeploymentState {
  const DeploymentState();
}

class DeploymentIdle extends DeploymentState {
  const DeploymentIdle();
}

class DeploymentInProgress extends DeploymentState {
  final String message;
  const DeploymentInProgress(this.message);
}

class DeploymentSuccess extends DeploymentState {
  final DeploymentResult result;
  const DeploymentSuccess(this.result);
}

class DeploymentFailed extends DeploymentState {
  final String message;
  const DeploymentFailed(this.message);
}

// ── DeploymentNotifier ────────────────────────────────────────────────────────

final credentialStorageProvider = Provider<CredentialStorage>((_) => CredentialStorage());

class DeploymentNotifier extends StateNotifier<DeploymentState> {
  final CredentialStorage _creds;

  DeploymentNotifier(this._creds) : super(const DeploymentIdle());

  Future<void> deploy(Website website, DeploymentTarget target) async {
    state = const DeploymentInProgress('Loading credentials…');
    try {
      final creds = await _creds.load(target.name);
      if (creds == null) {
        state = DeploymentFailed('No credentials saved for ${target.name}. '
            'Add them in Settings → Credentials.');
        return;
      }
      state = DeploymentInProgress('Deploying to ${target.name}…');

      final result = await switch (target) {
        DeploymentTarget.vercel => _deployVercel(website, creds),
        DeploymentTarget.netlify => _deployNetlify(website, creds),
        DeploymentTarget.githubPages => _deployGitHub(website, creds),
        DeploymentTarget.cloudflarePages => throw UnimplementedError('Cloudflare Pages coming soon'),
      };

      state = DeploymentSuccess(result);
    } catch (e) {
      state = DeploymentFailed(e.toString());
    }
  }

  Future<DeploymentResult> _deployVercel(Website website, PlatformCredentials creds) async {
    final client = VercelClient(token: creds.token);
    return client.deploy(website, teamId: creds.teamId);
  }

  Future<DeploymentResult> _deployNetlify(Website website, PlatformCredentials creds) async {
    final client = NetlifyClient(token: creds.token);
    return client.deploy(website);
  }

  Future<DeploymentResult> _deployGitHub(Website website, PlatformCredentials creds) async {
    final username = creds.username ?? '';
    final client = GitHubClient(token: creds.token, username: username);
    final result = await client.publish(website);
    return DeploymentResult(
      deployId: result.commitSha,
      url: result.pagesUrl ?? result.repoUrl,
      status: DeploymentStatus.ready,
    );
  }

  void reset() => state = const DeploymentIdle();
}

final deploymentProvider = StateNotifierProvider<DeploymentNotifier, DeploymentState>(
  (ref) => DeploymentNotifier(ref.watch(credentialStorageProvider)),
);
