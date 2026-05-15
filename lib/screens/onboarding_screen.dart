import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:resumate/screens/home_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      title: 'Your resume,\nreborn.',
      body: 'Paste your resume and watch Resumate turn it into a stunning personal website — in seconds.',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      illustrationKey: 0,
    ),
    _PageData(
      title: 'Edit like a\npro.',
      body: 'A built-in VS Code–style editor lets you tweak every pixel of HTML, CSS and JS before publishing.',
      icon: Icons.code_rounded,
      gradient: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      illustrationKey: 1,
    ),
    _PageData(
      title: 'Deploy\nanywhere.',
      body: 'One tap to Vercel, Netlify or GitHub Pages. Your portfolio goes live with a real URL.',
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      illustrationKey: 2,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // Mark onboarding done via settings
    ref.read(localStorageProvider).setSetting('onboarded', true);
    Navigator.pushReplacement(
      context,
      SlideUpRoute(child: const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full-bleed page view
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _OnboardPage(data: _pages[i]),
          ),

          // Bottom nav area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              pageCount: _pages.length,
              currentPage: _page,
              onNext: _next,
              onSkip: _finish,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single page ───────────────────────────────────────────────────────────────

class _PageData {
  final String title;
  final String body;
  final IconData icon;
  final List<Color> gradient;
  final int illustrationKey;

  const _PageData({
    required this.title,
    required this.body,
    required this.icon,
    required this.gradient,
    required this.illustrationKey,
  });
}

class _OnboardPage extends StatelessWidget {
  final _PageData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Hero illustration area — top 55 %
        SizedBox(
          height: size.height * 0.55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Decorative blobs
              Positioned(
                top: -60,
                right: -60,
                child: _Blob(size: 240, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: _Blob(size: 180, color: Colors.white.withValues(alpha: 0.06)),
              ),
              // Central illustration
              Center(
                child: _Illustration(pageIndex: data.illustrationKey),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut),

        // Text block — bottom 45 %
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineLarge,
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 16),
                Text(
                  data.body,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.6),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Illustrations (custom painted) ───────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final int pageIndex;

  const _Illustration({required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    return switch (pageIndex) {
      0 => const _ResumeIllustration(),
      1 => const _EditorIllustration(),
      _ => const _DeployIllustration(),
    };
  }
}

// Page 1 — floating resume card
class _ResumeIllustration extends StatefulWidget {
  const _ResumeIllustration();

  @override
  State<_ResumeIllustration> createState() => _ResumeIllustrationState();
}

class _ResumeIllustrationState extends State<_ResumeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final offset = math.sin(_ctrl.value * math.pi) * 10;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(height: 14),
                _line(140, 12, Colors.grey.shade800),
                const SizedBox(height: 6),
                _line(90, 8, Colors.grey.shade400),
                const SizedBox(height: 16),
                _line(160, 7, Colors.grey.shade300),
                const SizedBox(height: 5),
                _line(130, 7, Colors.grey.shade300),
                const SizedBox(height: 5),
                _line(150, 7, Colors.grey.shade300),
                const SizedBox(height: 14),
                // Skills chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ['Flutter', 'Dart', 'AI']
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }

  Widget _line(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

// Page 2 — mini code editor
class _EditorIllustration extends StatelessWidget {
  const _EditorIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A3E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFEBC2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF28C840)),
                const Spacer(),
                const Text('index.html',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 10)),
              ],
            ),
          ),
          // Code lines
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _codeLine('<', 'h1', '>', 'Jane Doe', '</h1>'),
                const SizedBox(height: 6),
                _codeLine('<', 'p', '>', 'Flutter Dev', '</p>'),
                const SizedBox(height: 6),
                _codeLine('<', 'section', '>', '', ''),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _codeLine('<', 'ul', '>', '', ''),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }

  Widget _dot(Color c) => CircleAvatar(radius: 5, backgroundColor: c);

  Widget _codeLine(String open, String tag, String close, String text,
      String closeTag) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 10, fontFamily: 'monospace', height: 1.4),
        children: [
          TextSpan(
              text: open + tag + close,
              style: const TextStyle(color: Color(0xFF569CD6))),
          TextSpan(
              text: text, style: const TextStyle(color: Color(0xFFCE9178))),
          if (closeTag.isNotEmpty)
            TextSpan(
                text: closeTag,
                style: const TextStyle(color: Color(0xFF569CD6))),
        ],
      ),
    );
  }
}

// Page 3 — deploy success card
class _DeployIllustration extends StatefulWidget {
  const _DeployIllustration();

  @override
  State<_DeployIllustration> createState() => _DeployIllustrationState();
}

class _DeployIllustrationState extends State<_DeployIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 210,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing success ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72 + _pulse.value * 12,
                  height: 72 + _pulse.value * 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(
                        alpha: 0.08 - _pulse.value * 0.05),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF22C55E),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Live!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'jane.vercel.app',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }
}

// ── Decorative blob ───────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _BottomNav({
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == pageCount - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 48),
      child: Row(
        children: [
          // Dot indicators
          Row(
            children: List.generate(pageCount, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary
                      : AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          // Skip button (hidden on last page)
          if (!isLast)
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          const SizedBox(width: 8),
          // Next / Get started
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? 'Get Started' : 'Next',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 6),
                Icon(
                  isLast ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
