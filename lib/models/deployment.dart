enum DeploymentTarget { vercel, cloudflarePages, netlify, githubPages }

enum DeploymentStatus { pending, building, ready, error }

class PlatformCredentials {
  final String platform;
  final String token;
  final String? teamId;
  final String? accountId;
  final String? username;

  const PlatformCredentials({
    required this.platform,
    required this.token,
    this.teamId,
    this.accountId,
    this.username,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'token': token,
        if (teamId != null) 'teamId': teamId,
        if (accountId != null) 'accountId': accountId,
        if (username != null) 'username': username,
      };

  factory PlatformCredentials.fromJson(Map<String, dynamic> j) => PlatformCredentials(
        platform: j['platform'] as String,
        token: j['token'] as String,
        teamId: j['teamId'] as String?,
        accountId: j['accountId'] as String?,
        username: j['username'] as String?,
      );
}

class DeploymentResult {
  final String? url;
  final String? deployId;
  final DeploymentStatus status;

  const DeploymentResult({this.url, this.deployId, required this.status});
}
