import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/website_provider.dart';
import 'package:resumate/screens/website_preview_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';
import 'package:resumate/shared/widgets/error_view.dart';
import 'package:resumate/shared/widgets/loading_view.dart';
// app_theme imported for SlideUpRoute

class GenerationScreen extends ConsumerStatefulWidget {
  final Resume resume;
  final TemplateStyle template;
  final String? colorPreference;

  const GenerationScreen({
    super.key,
    required this.resume,
    required this.template,
    this.colorPreference,
  });

  @override
  ConsumerState<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends ConsumerState<GenerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    await ref.read(websiteProvider.notifier).generate(
          widget.resume,
          widget.template,
          colorPreference: widget.colorPreference,
          streaming: true,
        );
  }

  static const _stages = [
    'Analyzing resume…',
    'Choosing design…',
    'Writing HTML…',
    'Adding styles…',
    'Finalizing…',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(websiteProvider);
    if (state is WebsiteReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          SlideUpRoute(child: WebsitePreviewScreen(website: state.website)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generating Website'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: switch (state) {
          WebsiteGenerating(:final stage, :final progress) => _GeneratingView(
              stage: stage,
              progress: progress,
              stages: _stages,
            ),
          WebsiteError(:final message) => ErrorView(
              message: message,
              actionLabel: 'Retry',
              onAction: _generate,
            ),
          _ => const LoadingView(message: 'Starting…'),
        },
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  final String stage;
  final double progress;
  final List<String> stages;

  const _GeneratingView({
    required this.stage,
    required this.progress,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 32),
        Text('Building your portfolio',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(stage.isEmpty ? 'Starting…' : stage,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 32),
        ...stages.map((s) {
          final idx = stages.indexOf(s);
          final currentIdx = stages.indexWhere((st) =>
              stage.toLowerCase().contains(st.split(' ').first.toLowerCase()));
          final done = idx < currentIdx;
          final active = idx == currentIdx;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(
                done
                    ? Icons.check_circle
                    : active
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                size: 18,
                color: done
                    ? theme.colorScheme.primary
                    : active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Text(s,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: done || active ? null : theme.colorScheme.outline,
                    fontWeight: active ? FontWeight.w600 : null,
                  )),
            ]),
          );
        }),
      ],
    );
  }
}

