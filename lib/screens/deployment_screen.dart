import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/deployment.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/credentials_provider.dart';
import 'package:resumate/providers/deployment_provider.dart';
import 'package:resumate/screens/credentials_screen.dart';
import 'package:resumate/shared/widgets/error_view.dart';
import 'package:resumate/shared/widgets/loading_view.dart';
import 'package:resumate/shared/widgets/platform_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class DeploymentScreen extends ConsumerStatefulWidget {
  final Website website;
  const DeploymentScreen({super.key, required this.website});

  @override
  ConsumerState<DeploymentScreen> createState() => _DeploymentScreenState();
}

class _DeploymentScreenState extends ConsumerState<DeploymentScreen> {
  DeploymentTarget _selected = DeploymentTarget.vercel;

  static const _targets = [
    (DeploymentTarget.vercel,          'Vercel',            'Fast global CDN, instant deploys'),
    (DeploymentTarget.netlify,         'Netlify',           'Free tier, auto HTTPS'),
    (DeploymentTarget.githubPages,     'GitHub Pages',      'Free hosting via GitHub'),
    (DeploymentTarget.cloudflarePages, 'Cloudflare Pages',  'Edge network, very fast'),
  ];

  Future<void> _deploy() =>
      ref.read(deploymentProvider.notifier).deploy(widget.website, _selected);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deploymentProvider);
    final credsState = ref.watch(credentialsProvider);
    final theme = Theme.of(context);
    final hasCredentials = credsState.platforms.contains(_selected.name);

    return Scaffold(
      appBar: AppBar(title: const Text('Deploy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (state) {
          DeploymentSuccess(:final result) => _SuccessView(result: result),
          DeploymentFailed(:final message) => ErrorView(
              title: 'Deployment failed',
              message: message,
              actionLabel: 'Try Again',
              onAction: () => ref.read(deploymentProvider.notifier).reset(),
            ),
          DeploymentInProgress(:final message) => LoadingView(message: message),
          _ => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose platform',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._targets.map((t) {
                  final (target, name, desc) = t;
                  return PlatformSelectorTile<DeploymentTarget>(
                    value: target,
                    selected: _selected,
                    title: name,
                    subtitle: desc,
                    onTap: (v) => setState(() => _selected = v),
                  );
                }),
                const SizedBox(height: 8),
                if (!hasCredentials)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.key, size: 16),
                    label: Text('Add ${_selected.name} credentials'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CredentialsScreen(platform: _selected.name),
                      ),
                    ).then((_) =>
                        ref.read(credentialsProvider.notifier).load()),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text('Deploy Now'),
                    onPressed: hasCredentials ? _deploy : null,
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final DeploymentResult result;
  const _SuccessView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = result.url;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Deployed!', style: theme.textTheme.headlineSmall),
          if (url != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(url)),
              child: Text(url,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  )),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy URL'),
              onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            ),
          ],
        ],
      ),
    );
  }
}
