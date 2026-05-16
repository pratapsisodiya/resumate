import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:resumate/screens/generation_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';
import 'package:resumate/shared/widgets/platform_selector.dart';

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  TemplateStyle _selected = TemplateStyle.modern;
  int _colorIndex = 0;

  static const _templates = [
    (TemplateStyle.modern,       'Modern',       Icons.view_quilt_rounded,   'Clean layout with bold typography'),
    (TemplateStyle.minimal,      'Minimal',      Icons.minimize_rounded,     'Simple, whitespace-first design'),
    (TemplateStyle.creative,     'Creative',     Icons.brush_rounded,        'Unique visuals and color gradients'),
    (TemplateStyle.professional, 'Professional', Icons.business_center_rounded, 'Corporate-ready polished look'),
    (TemplateStyle.developer,    'Developer',    Icons.terminal_rounded,     'Dark theme, code-inspired aesthetic'),
  ];

  static const _palettes = [
    _Palette('Indigo',  Color(0xFF6366F1), 'indigo'),
    _Palette('Violet',  Color(0xFF8B5CF6), 'violet'),
    _Palette('Blue',    Color(0xFF3B82F6), 'blue'),
    _Palette('Teal',    Color(0xFF14B8A6), 'teal'),
    _Palette('Rose',    Color(0xFFF43F5E), 'rose'),
    _Palette('Amber',   Color(0xFFF59E0B), 'amber'),
    _Palette('Emerald', Color(0xFF10B981), 'emerald'),
    _Palette('Slate',   Color(0xFF64748B), 'slate'),
  ];

  void _generate() {
    final resumeState = ref.read(resumeProvider);
    if (resumeState is! ResumeLoaded) return;
    Navigator.pushReplacement(
      context,
      SlideUpRoute(
        child: GenerationScreen(
          resume: resumeState.resume,
          template: _selected,
          colorPreference: _palettes[_colorIndex].hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = ref.watch(resumeProvider) is ResumeLoaded;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Template')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              children: [
                // Template tiles
                ..._templates.asMap().entries.map((e) {
                  final (style, name, icon, desc) = e.value;
                  return PlatformSelectorTile<TemplateStyle>(
                    value: style,
                    selected: _selected,
                    title: name,
                    subtitle: desc,
                    onTap: (v) => setState(() => _selected = v),
                    leading: Icon(icon, size: 20),
                  )
                      .animate(delay: (e.key * 40).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
                }),

                const SizedBox(height: 24),

                // Colour palette
                Text('Colour Scheme',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: const Color(0xFF9CA3AF),
                    )),
                const SizedBox(height: 10),
                _ColorPicker(
                  palettes: _palettes,
                  selectedIndex: _colorIndex,
                  onSelect: (i) => setState(() => _colorIndex = i),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Generate button
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Generate Website'),
                onPressed: hasResume ? _generate : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Palette model ─────────────────────────────────────────────────────────────

class _Palette {
  final String name;
  final Color color;
  final String hint; // sent to GenKit as colorPreference
  const _Palette(this.name, this.color, this.hint);
}

// ── Colour picker strip ───────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final List<_Palette> palettes;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _ColorPicker({
    required this.palettes,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: palettes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = palettes[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: selected ? 80 : 48,
              decoration: BoxDecoration(
                color: p.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: p.color.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
                border: selected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
              ),
              child: selected
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
