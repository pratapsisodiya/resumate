import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/providers/credentials_provider.dart';

class CredentialsScreen extends ConsumerStatefulWidget {
  final String platform;
  const CredentialsScreen({super.key, required this.platform});

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  final _tokenCtrl = TextEditingController();
  final _teamIdCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _accountIdCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final creds = await ref
        .read(credentialsProvider.notifier)
        .get(widget.platform);
    if (creds != null && mounted) {
      _tokenCtrl.text = creds.token;
      _teamIdCtrl.text = creds.teamId ?? '';
      _usernameCtrl.text = creds.username ?? '';
      _accountIdCtrl.text = creds.accountId ?? '';
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _teamIdCtrl.dispose();
    _usernameCtrl.dispose();
    _accountIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final creds = PlatformCredentials(
      platform: widget.platform,
      token: _tokenCtrl.text.trim(),
      teamId: _teamIdCtrl.text.trim().isEmpty ? null : _teamIdCtrl.text.trim(),
      username:
          _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      accountId: _accountIdCtrl.text.trim().isEmpty
          ? null
          : _accountIdCtrl.text.trim(),
    );
    await ref.read(credentialsProvider.notifier).save(creds);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(credentialsProvider.notifier).delete(widget.platform);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isGitHub = widget.platform == 'githubPages';
    final isVercel = widget.platform == 'vercel';
    final isCF = widget.platform == 'cloudflarePages';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform} Credentials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove credentials',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_tokenCtrl, 'API Token *',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
          if (isVercel)
            _field(_teamIdCtrl, 'Team ID (optional)'),
          if (isGitHub)
            _field(_usernameCtrl, 'GitHub Username *'),
          if (isCF) ...[
            _field(_accountIdCtrl, 'Account ID *'),
          ],
          const SizedBox(height: 8),
          _HelpText(platform: widget.platform),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Credentials'),
              onPressed: _tokenCtrl.text.isNotEmpty ? _save : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool obscure = false,
    Widget? suffix,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: suffix,
          ),
          onChanged: (_) => setState(() {}),
        ),
      );
}

class _HelpText extends StatelessWidget {
  final String platform;
  const _HelpText({required this.platform});

  @override
  Widget build(BuildContext context) {
    final msg = switch (platform) {
      'vercel' =>
        'Create a token at vercel.com/account/tokens. Team ID is optional.',
      'netlify' =>
        'Create a personal access token at app.netlify.com/user/applications.',
      'githubPages' =>
        'Create a token with repo and pages scopes at github.com/settings/tokens.',
      'cloudflarePages' =>
        'Create an API token with Cloudflare Pages:Edit permission.',
      _ => 'Provide your API token for this platform.',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
