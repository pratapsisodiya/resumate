import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/models/website.dart';
import 'package:resumate/providers/credentials_provider.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:resumate/providers/website_provider.dart';
import 'package:resumate/screens/credentials_screen.dart';
import 'package:resumate/screens/deployment_screen.dart';
import 'package:resumate/screens/ide_screen.dart';
import 'package:resumate/screens/resume_input_screen.dart';
import 'package:resumate/screens/support_chat_screen.dart';
import 'package:resumate/screens/template_selection_screen.dart';
import 'package:resumate/screens/website_preview_screen.dart';
import 'package:resumate/shared/theme/app_theme.dart';
import 'package:resumate/shared/utils/formatters.dart';
import 'package:resumate/shared/widgets/score_ring.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHELL
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _navAnim;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description_rounded),
      label: 'Resume',
    ),
    NavigationDestination(
      icon: Icon(Icons.language_outlined),
      selectedIcon: Icon(Icons.language_rounded),
      label: 'Website',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_rounded),
      selectedIcon: Icon(Icons.tune_rounded),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: IndexedStack(
          index: _tab,
          children: [
            _DashboardTab(onSwitchTab: _switchTab),
            const _ResumeTab(),
            const _WebsiteTab(),
            const _MoreTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _switchTab,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            indicatorColor: AppTheme.primary.withOpacity(0.12),
            destinations: _destinations,
            animationDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  final void Function(int) onSwitchTab;
  const _DashboardTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState  = ref.watch(resumeProvider);
    final websiteState = ref.watch(websiteProvider);
    final resume  = resumeState  is ResumeLoaded  ? resumeState.resume   : null;
    final website = websiteState is WebsiteReady  ? websiteState.website : null;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        ref.invalidate(resumeProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _HeroBanner(resume: resume),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Score card
                if (resume != null) ...[
                  _ScoreHeadline(resume: resume)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 28),
                ],

                // Tips if no resume
                if (resume == null) ...[
                  _TipsBanner()
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 400.ms),
                  const SizedBox(height: 28),
                ],

                // Quick actions
                _sectionLabel(context, 'QUICK ACTIONS'),
                const SizedBox(height: 12),
                _QuickGrid(resume: resume, website: website)
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 28),

                // Status cards
                _sectionLabel(context, 'STATUS'),
                const SizedBox(height: 12),
                _StatusRow(resumeState: resumeState, websiteState: websiteState)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                // Activity feed
                if (resume != null || website != null) ...[
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'RECENT ACTIVITY'),
                  const SizedBox(height: 12),
                  _ActivityFeed(resume: resume, website: website)
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String t) => Text(
      t,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.3,
            color: const Color(0xFF9CA3AF),
          ),
    );

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final Resume? resume;
  const _HeroBanner({this.resume});

  @override
  Widget build(BuildContext context) {
    final firstName = resume?.personalInfo.fullName.split(' ').first;
    final initials  = resume != null
        ? resume!.personalInfo.fullName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0] : '')
            .join()
        : '?';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 18,
        left: 24,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6D28D9), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blob top-right
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 2),
                    Text(
                      firstName != null ? '$firstName 👋' : 'Welcome back',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ).animate().fadeIn(delay: 60.ms, duration: 400.ms)
                        .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 6),
                    Text(
                      'Your AI portfolio builder',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  // Chat shortcut
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(ctx,
                            SlideUpRoute(child: const SupportChatScreen()));
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
                  ),
                  const SizedBox(height: 8),
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                  ).animate()
                      .fadeIn(delay: 140.ms, duration: 400.ms)
                      .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tips banner (shown when no resume) ───────────────────────────────────────

class _TipsBanner extends StatefulWidget {
  @override
  State<_TipsBanner> createState() => _TipsBannerState();
}

class _TipsBannerState extends State<_TipsBanner> {
  static const _tips = [
    (
      icon: Icons.upload_file_rounded,
      color: Color(0xFF6366F1),
      title: 'Import your PDF',
      body: 'Drop a PDF resume and AI extracts every detail automatically.',
    ),
    (
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF8B5CF6),
      title: 'AI-powered generation',
      body: 'Claude 3.5 Sonnet builds a production-ready portfolio site.',
    ),
    (
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF0EA5E9),
      title: 'One-tap deploy',
      body: 'Push to Vercel, Netlify, or GitHub Pages in seconds.',
    ),
  ];

  final _page = PageController();
  int _current = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _page,
            itemCount: _tips.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final tip = _tips[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: tip.color.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tip.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tip.icon, color: tip.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tip.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(tip.body,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _tips.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current
                    ? AppTheme.primary
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Score headline ────────────────────────────────────────────────────────────

class _ScoreHeadline extends StatelessWidget {
  final Resume resume;
  const _ScoreHeadline({required this.resume});

  @override
  Widget build(BuildContext context) {
    final score = resumeScore(resume);
    final color = score >= 80
        ? const Color(0xFF22C55E)
        : score >= 50
            ? AppTheme.accent
            : const Color(0xFFEF4444);
    final msg = score >= 80
        ? 'Great resume! Ready to generate.'
        : score >= 50
            ? 'Looking good — add more sections.'
            : 'Keep filling in your resume.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(score: score, size: 72),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resume completeness',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 0.5,
                        )),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$score%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -1,
                        )),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _ScoreBadge(score: score),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(msg, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final (label, color) = score >= 80
        ? ('Excellent', const Color(0xFF22C55E))
        : score >= 50
            ? ('Good', AppTheme.accent)
            : ('Incomplete', const Color(0xFFEF4444));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ── Quick grid ────────────────────────────────────────────────────────────────

class _QuickGrid extends StatelessWidget {
  final Resume? resume;
  final Website? website;
  const _QuickGrid({this.resume, this.website});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _GridTile(
        icon: Icons.auto_awesome_rounded,
        label: 'Generate',
        sub: 'Build your site',
        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        enabled: resume != null,
        onTap: () => Navigator.push(
            context, SlideUpRoute(child: const TemplateSelectionScreen())),
      ),
      _GridTile(
        icon: Icons.rocket_launch_rounded,
        label: 'Deploy',
        sub: 'Go live now',
        gradient: const [Color(0xFF0EA5E9), Color(0xFF6366F1)],
        enabled: website != null,
        onTap: website != null
            ? () => Navigator.push(context,
                SlideUpRoute(child: DeploymentScreen(website: website!)))
            : null,
      ),
      _GridTile(
        icon: Icons.preview_rounded,
        label: 'Preview',
        sub: 'See your site',
        gradient: const [Color(0xFF10B981), Color(0xFF0EA5E9)],
        enabled: website != null,
        onTap: website != null
            ? () => Navigator.push(context,
                SlideUpRoute(child: WebsitePreviewScreen(website: website!)))
            : null,
      ),
      _GridTile(
        icon: Icons.chat_bubble_rounded,
        label: 'AI Chat',
        sub: 'Ask anything',
        gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
        enabled: true,
        onTap: () => Navigator.push(
            context, SlideUpRoute(child: const SupportChatScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: tiles
          .asMap()
          .entries
          .map((e) => e.value
              .animate(delay: (e.key * 50).ms)
              .fadeIn(duration: 280.ms)
              .scale(
                  begin: const Offset(0.92, 0.92),
                  curve: Curves.easeOutBack))
          .toList(),
    );
  }
}

class _GridTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sub;
  final List<Color> gradient;
  final bool enabled;
  final VoidCallback? onTap;

  const _GridTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.gradient,
    required this.enabled,
    this.onTap,
  });

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.enabled ? 1.0 : 0.42,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.enabled
                    ? widget.gradient
                    : [const Color(0xFFE5E7EB), const Color(0xFFD1D5DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: widget.gradient.first.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text(widget.sub,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status cards ──────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final ResumeState resumeState;
  final WebsiteState websiteState;
  const _StatusRow({required this.resumeState, required this.websiteState});

  @override
  Widget build(BuildContext context) {
    final resumeDone  = resumeState  is ResumeLoaded;
    final websiteDone = websiteState is WebsiteReady;
    final webGenAt = websiteDone
        ? (websiteState as WebsiteReady).website.generatedAt
        : null;

    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: Icons.description_rounded,
            title: resumeDone ? 'Resume' : 'No resume',
            subtitle: resumeDone
                ? (resumeState as ResumeLoaded).resume.personalInfo.title ??
                    'Ready'
                : 'Add one to start',
            color: resumeDone
                ? const Color(0xFF22C55E)
                : const Color(0xFF9CA3AF),
            dot: resumeDone,
            onTap: () => Navigator.push(
                context, SlideUpRoute(child: const ResumeInputScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusCard(
            icon: Icons.language_rounded,
            title: websiteDone ? 'Site ready' : 'No website',
            subtitle: webGenAt != null
                ? 'Updated ${timeAgo(webGenAt)}'
                : 'Generate one',
            color: websiteDone ? AppTheme.primary : const Color(0xFF9CA3AF),
            dot: websiteDone,
            onTap: () => Navigator.push(
                context, SlideUpRoute(child: const TemplateSelectionScreen())),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool dot;
  final VoidCallback onTap;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.dot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (dot)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Activity feed ─────────────────────────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  final Resume? resume;
  final Website? website;
  const _ActivityFeed({this.resume, this.website});

  @override
  Widget build(BuildContext context) {
    final events = <({IconData icon, Color color, String title, DateTime at})>[];

    if (resume != null) {
      events.add((
        icon: Icons.description_rounded,
        color: const Color(0xFF22C55E),
        title: 'Resume parsed · ${resume!.personalInfo.fullName}',
        at: resume!.lastUpdated,
      ));
    }
    if (website != null) {
      events.add((
        icon: Icons.auto_awesome_rounded,
        color: AppTheme.primary,
        title: 'Website generated · ${website!.name}',
        at: website!.generatedAt,
      ));
      events.add((
        icon: Icons.code_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'Template: ${website!.template.name}',
        at: website!.generatedAt,
      ));
    }

    events.sort((a, b) => b.at.compareTo(a.at));
    final shown = events.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: shown.asMap().entries.map((e) {
          final ev = e.value;
          final isLast = e.key == shown.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ev.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ev.icon, size: 14, color: ev.color),
                    ),
                    if (!isLast)
                      Container(
                        width: 1,
                        height: 24,
                        color: AppTheme.border,
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: 13, bottom: isLast ? 12 : 0, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(timeAgo(ev.at),
                          style: Theme.of(context).textTheme.bodySmall),
                      if (!isLast) const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — RESUME
// ══════════════════════════════════════════════════════════════════════════════

class _ResumeTab extends ConsumerWidget {
  const _ResumeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resumeProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: switch (state) {
        ResumeLoaded(:final resume) => _ResumeDetailView(resume: resume),
        ResumeLoading() =>
          const Center(child: CircularProgressIndicator()),
        _ => _EmptyTabView(
            icon: Icons.description_outlined,
            title: 'No resume yet',
            body: 'Add your resume and let AI parse your experience, skills and more.',
            buttonLabel: 'Add Resume',
            onTap: () => Navigator.push(
                context, SlideUpRoute(child: const ResumeInputScreen())),
          ),
      },
      floatingActionButton: state is ResumeLoaded
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context, SlideUpRoute(child: const ResumeInputScreen()));
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Resume'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _ResumeDetailView extends StatelessWidget {
  final Resume resume;
  const _ResumeDetailView({required this.resume});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _ResumeHeader(resume: resume)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // Bio card
              if (resume.personalInfo.bio != null &&
                  resume.personalInfo.bio!.isNotEmpty) ...[
                _BioBanner(bio: resume.personalInfo.bio!)
                    .animate()
                    .fadeIn(delay: 40.ms, duration: 300.ms),
                const SizedBox(height: 12),
              ],

              _SectionTile(
                icon: Icons.work_rounded,
                color: const Color(0xFF6366F1),
                title: 'Experience',
                count: resume.experiences.length,
                children: resume.experiences
                    .map((e) => _BulletItem(
                          primary: '${e.role} at ${e.company}',
                          secondary: e.isCurrent
                              ? 'Present'
                              : '${e.startDate.year} – ${e.endDate?.year ?? ''}',
                        ))
                    .toList(),
              ).animate().fadeIn(delay: 60.ms, duration: 300.ms),

              _SectionTile(
                icon: Icons.school_rounded,
                color: const Color(0xFF0EA5E9),
                title: 'Education',
                count: resume.education.length,
                children: resume.education
                    .map((e) => _BulletItem(
                          primary: e.degree,
                          secondary: e.institution,
                        ))
                    .toList(),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              // Skills with level bars
              if (resume.skills.isNotEmpty)
                _SkillBarsCard(skills: resume.skills)
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 300.ms),

              _SectionTile(
                icon: Icons.rocket_launch_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Projects',
                count: resume.projects.length,
                children: resume.projects
                    .map((p) => _BulletItem(
                          primary: p.name,
                          secondary: p.description,
                          maxLines: 2,
                        ))
                    .toList(),
              ).animate().fadeIn(delay: 180.ms, duration: 300.ms),

              if (resume.certifications.isNotEmpty)
                _SectionTile(
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'Certifications',
                  count: resume.certifications.length,
                  children: resume.certifications
                      .map((c) => _BulletItem(
                            primary: c.name,
                            secondary: c.issuer,
                          ))
                      .toList(),
                ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Bio banner ────────────────────────────────────────────────────────────────

class _BioBanner extends StatelessWidget {
  final String bio;
  const _BioBanner({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.06),
            AppTheme.secondary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              color: AppTheme.primary.withOpacity(0.5), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(bio,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    )),
          ),
        ],
      ),
    );
  }
}

// ── Skill bars card ───────────────────────────────────────────────────────────

class _SkillBarsCard extends StatefulWidget {
  final List<Skill> skills;
  const _SkillBarsCard({required this.skills});

  @override
  State<_SkillBarsCard> createState() => _SkillBarsCardState();
}

class _SkillBarsCardState extends State<_SkillBarsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _expanded = false;

  static double _levelValue(String? level) => switch (level?.toLowerCase()) {
        'expert'        => 1.0,
        'advanced'      => 0.83,
        'intermediate'  => 0.58,
        'beginner'      => 0.33,
        _               => 0.55,
      };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _expanded
        ? widget.skills
        : widget.skills.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code_rounded,
                        color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('Skills',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${widget.skills.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981))),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...visible.asMap().entries.map((e) {
                    final sk = e.value;
                    final val = _levelValue(sk.level);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(sk.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                              ),
                              if (sk.level != null)
                                Text(sk.level!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                        fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          AnimatedBuilder(
                            animation: _ctrl,
                            builder: (_, __) {
                              final animated = Curves.easeOutCubic
                                  .transform(_ctrl.value);
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: animated * val,
                                  minHeight: 5,
                                  backgroundColor:
                                      const Color(0xFFF3F4F6),
                                  color: Color.lerp(
                                    AppTheme.primary,
                                    const Color(0xFF10B981),
                                    e.key / (visible.length - 1).clamp(1, 99),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  if (widget.skills.length > 5) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded
                            ? 'Show less'
                            : '+ ${widget.skills.length - 5} more',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _ResumeHeader extends StatelessWidget {
  final Resume resume;
  const _ResumeHeader({required this.resume});

  @override
  Widget build(BuildContext context) {
    final initials = resume.personalInfo.fullName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();
    final score = resumeScore(resume);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resume.personalInfo.fullName,
                        style: Theme.of(context).textTheme.titleLarge),
                    if (resume.personalInfo.title != null)
                      Text(resume.personalInfo.title!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: const Color(0xFF6B7280))),
                    if (resume.personalInfo.location != null)
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 2),
                        Text(resume.personalInfo.location!,
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                  ],
                ),
              ),
              // Mini score
              ScoreRing(score: score, size: 46),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF3F4F6),
                    color: score >= 80
                        ? const Color(0xFF22C55E)
                        : score >= 50
                            ? AppTheme.accent
                            : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$score% complete',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (resume.personalInfo.email.isNotEmpty)
                _ContactChip(Icons.email_outlined, resume.personalInfo.email),
              if (resume.personalInfo.phone != null)
                _ContactChip(
                    Icons.phone_outlined, resume.personalInfo.phone!),
              if (resume.personalInfo.linkedIn != null)
                _ContactChip(Icons.link_rounded, 'LinkedIn'),
              if (resume.personalInfo.github != null)
                _ContactChip(Icons.code_rounded, 'GitHub'),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Updated ${timeAgo(resume.lastUpdated)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11, color: const Color(0xFFB0B7C3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _SectionTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final List<Widget> children;
  const _SectionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.children,
  });

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.count > 0
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.count > 0
                          ? widget.color.withOpacity(0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${widget.count}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.count > 0
                                ? widget.color
                                : const Color(0xFF9CA3AF))),
                  ),
                  if (widget.count > 0) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: widget.children.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        ...widget.children,
                      ],
                    ),
                  ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String primary;
  final String secondary;
  final int maxLines;
  const _BulletItem({
    required this.primary,
    required this.secondary,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primary,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(secondary,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — WEBSITE
// ══════════════════════════════════════════════════════════════════════════════

class _WebsiteTab extends ConsumerWidget {
  const _WebsiteTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state       = ref.watch(websiteProvider);
    final resumeState = ref.watch(resumeProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: switch (state) {
        WebsiteReady(:final website) => _WebsiteDetailView(website: website),
        WebsiteGenerating(:final stage, :final progress) =>
          _WebsiteGeneratingView(stage: stage, progress: progress),
        _ => _EmptyTabView(
            icon: Icons.language_outlined,
            title: 'No website yet',
            body: resumeState is ResumeLoaded
                ? 'Your resume is ready — generate a portfolio now.'
                : 'Add a resume first, then generate your site.',
            buttonLabel: 'Generate Website',
            enabled: resumeState is ResumeLoaded,
            onTap: () => Navigator.push(
                context,
                SlideUpRoute(child: const TemplateSelectionScreen())),
          ),
      },
    );
  }
}

class _WebsiteDetailView extends StatelessWidget {
  final Website website;
  const _WebsiteDetailView({required this.website});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _WebsiteHero(website: website)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WebsiteActions(website: website)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 20),
              _WebsiteStatsRow(website: website)
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 300.ms),
              const SizedBox(height: 20),
              _WebsiteDetails(website: website)
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 20),
              _WebsiteFiles(website: website)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ]),
          ),
        ),
      ],
    );
  }
}

class _WebsiteHero extends StatelessWidget {
  final Website website;
  const _WebsiteHero({required this.website});

  static const _templateColors = {
    TemplateStyle.modern:       [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    TemplateStyle.minimal:      [Color(0xFF1F2937), Color(0xFF374151)],
    TemplateStyle.creative:     [Color(0xFFEC4899), Color(0xFFF59E0B)],
    TemplateStyle.professional: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    TemplateStyle.developer:    [Color(0xFF10B981), Color(0xFF0EA5E9)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _templateColors[website.template] ??
        [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            SlideUpRoute(child: WebsitePreviewScreen(website: website)));
      },
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -20, left: 40,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Browser chrome mockup at bottom
            Positioned(
              bottom: 16, left: 20, right: 20,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    ...List.generate(3, (i) => Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${nameSlug(website.name)}.vercel.app',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
            // Center content
            Positioned(
              top: 0, left: 0, right: 0, bottom: 52,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text(website.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TemplateBadge(template: website.template),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Tap to preview',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Safe-area top bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Website',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(timeAgo(website.generatedAt),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateBadge extends StatelessWidget {
  final TemplateStyle template;
  const _TemplateBadge({required this.template});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(template.name[0].toUpperCase() + template.name.substring(1),
            style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
}

// ── Website stats row ─────────────────────────────────────────────────────────

class _WebsiteStatsRow extends StatelessWidget {
  final Website website;
  const _WebsiteStatsRow({required this.website});

  @override
  Widget build(BuildContext context) {
    final fileCount = 1 +
        (website.cssContent != null ? 1 : 0) +
        (website.jsContent != null ? 1 : 0);
    final totalKb =
        ((website.htmlContent.length +
                (website.cssContent?.length ?? 0) +
                (website.jsContent?.length ?? 0)) /
            1024)
            .toStringAsFixed(1);

    return Row(
      children: [
        _StatTile(
          icon: Icons.insert_drive_file_rounded,
          value: '$fileCount',
          label: 'Files',
          color: AppTheme.primary,
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.data_usage_rounded,
          value: '$totalKb KB',
          label: 'Total size',
          color: const Color(0xFF0EA5E9),
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.memory_rounded,
          value: '${website.tokensUsed}',
          label: 'Tokens',
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _WebsiteActions extends StatelessWidget {
  final Website website;
  const _WebsiteActions({required this.website});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionPill(
          icon: Icons.preview_rounded,
          label: 'Preview',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context,
                SlideUpRoute(child: WebsitePreviewScreen(website: website)));
          },
        ),
        const SizedBox(width: 8),
        _ActionPill(
          icon: Icons.code_rounded,
          label: 'IDE',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context,
                SlideRightRoute(child: IdeScreen(website: website)));
          },
        ),
        const SizedBox(width: 8),
        _ActionPill(
          icon: Icons.refresh_rounded,
          label: 'Rebuild',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context,
                SlideUpRoute(child: const TemplateSelectionScreen()));
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded, size: 15),
            label: const Text('Deploy'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(context,
                  SlideUpRoute(child: DeploymentScreen(website: website)));
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionPill(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      );
}

class _WebsiteDetails extends StatelessWidget {
  final Website website;
  const _WebsiteDetails({required this.website});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Details',
      rows: [
        _InfoRow('Template', website.template.name),
        _InfoRow('Generated', timeAgo(website.generatedAt)),
        _InfoRow('Model', website.modelUsed),
        _InfoRow('Tokens used', '${website.tokensUsed}'),
      ],
    );
  }
}

class _WebsiteFiles extends StatelessWidget {
  final Website website;
  const _WebsiteFiles({required this.website});

  @override
  Widget build(BuildContext context) {
    final files = [
      ('index.html', Icons.html_rounded, website.htmlContent.length),
      if (website.cssContent != null)
        ('styles.css', Icons.css_rounded, website.cssContent!.length),
      if (website.jsContent != null)
        ('script.js', Icons.javascript_rounded, website.jsContent!.length),
    ];

    return _InfoCard(
      title: 'Files',
      child: Column(
        children: files
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Icon(f.$2, size: 16, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(f.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13))),
                      Text('${(f.$3 / 1024).toStringAsFixed(1)} KB',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow>? rows;
  final Widget? child;
  const _InfoCard({required this.title, this.rows, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (rows != null) ...rows! else if (child != null) child!,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF9CA3AF))),
            ),
            Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _WebsiteGeneratingView extends StatelessWidget {
  final String stage;
  final double progress;
  const _WebsiteGeneratingView(
      {required this.stage, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.secondary.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primary, size: 34),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 900.ms,
                      curve: Curves.easeInOut),
              const SizedBox(height: 24),
              Text('Building your portfolio',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(stage.isEmpty ? 'Starting…' : stage,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 4 — MORE / SETTINGS
// ══════════════════════════════════════════════════════════════════════════════

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeState = ref.watch(resumeProvider);
    final resume = resumeState is ResumeLoaded ? resumeState.resume : null;
    final credState = ref.watch(credentialsProvider);

    bool connected(String p) => credState.platforms.contains(p);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _MoreHeader(resume: resume)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                _MenuSection(
                  title: 'AI Features',
                  items: [
                    _MenuItem(
                      icon: Icons.chat_bubble_rounded,
                      color: AppTheme.secondary,
                      title: 'AI Assistant',
                      subtitle: 'Ask about your resume or website',
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(child: const SupportChatScreen())),
                    ),
                    _MenuItem(
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primary,
                      title: 'Generate Website',
                      subtitle: 'Create from resume with AI',
                      enabled: resumeState is ResumeLoaded,
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(
                              child: const TemplateSelectionScreen())),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 300.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 16),

                _MenuSection(
                  title: 'Deployment Credentials',
                  items: [
                    _MenuItem(
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Vercel',
                      subtitle: connected('vercel')
                          ? 'Token configured'
                          : 'Add API token',
                      trailing: connected('vercel') ? _ConnectedBadge() : null,
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(
                              child: const CredentialsScreen(
                                  platform: 'vercel'))),
                    ),
                    _MenuItem(
                      icon: Icons.cloud_rounded,
                      color: const Color(0xFF0EA5E9),
                      title: 'Netlify',
                      subtitle: connected('netlify')
                          ? 'Token configured'
                          : 'Add personal token',
                      trailing:
                          connected('netlify') ? _ConnectedBadge() : null,
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(
                              child: const CredentialsScreen(
                                  platform: 'netlify'))),
                    ),
                    _MenuItem(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'Cloudflare Pages',
                      subtitle: connected('cloudflarePages')
                          ? 'Token configured'
                          : 'Add API token',
                      trailing: connected('cloudflarePages')
                          ? _ConnectedBadge()
                          : null,
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(
                              child: const CredentialsScreen(
                                  platform: 'cloudflarePages'))),
                    ),
                    _MenuItem(
                      icon: Icons.code_rounded,
                      color: const Color(0xFF374151),
                      title: 'GitHub Pages',
                      subtitle: connected('githubPages')
                          ? 'PAT configured'
                          : 'Add personal access token',
                      trailing: connected('githubPages')
                          ? _ConnectedBadge()
                          : null,
                      onTap: () => Navigator.push(context,
                          SlideUpRoute(
                              child: const CredentialsScreen(
                                  platform: 'githubPages'))),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 300.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 16),

                _MenuSection(
                  title: 'App',
                  items: [
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF9CA3AF),
                      title: 'About Resumate',
                      subtitle: 'v1.0.0 · AI-powered portfolio builder',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 300.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                if (resume != null) ...[
                  const SizedBox(height: 16),
                  _DangerZone(ref: ref)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 300.ms),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AboutSheet(),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 16),
          const Text('Resumate',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('v1.0.0',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          Text('AI-powered portfolio builder. Turn your resume\ninto a deployed website in minutes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  )),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text('Powered by Claude 3.5 Sonnet',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ── Danger zone ───────────────────────────────────────────────────────────────

class _DangerZone extends StatelessWidget {
  final WidgetRef ref;
  const _DangerZone({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('DANGER ZONE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: const Color(0xFFEF4444),
                  )),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: InkWell(
            onTap: () => _confirmDelete(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444), size: 19),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delete Resume',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFFEF4444))),
                        Text('Remove all resume data permanently',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Resume?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently remove your resume data. This action cannot be undone.',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(resumeProvider.notifier).delete();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MoreHeader extends StatelessWidget {
  final Resume? resume;
  const _MoreHeader({this.resume});

  @override
  Widget build(BuildContext context) {
    final initials = resume?.personalInfo.fullName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: initials != null
                  ? Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20))
                  : const Icon(Icons.person_rounded,
                      color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume?.personalInfo.fullName ?? 'Your profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  resume?.personalInfo.email ?? 'No resume added yet',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: const Color(0xFF9CA3AF),
                  )),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < items.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: enabled
                    ? color.withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: enabled ? color : const Color(0xFFD1D5DB),
                  size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: enabled
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      )),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: enabled
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

class _ConnectedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('● Connected',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A))),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyTabView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _EmptyTabView({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.12),
                      AppTheme.secondary.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 38),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ))
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 350.ms),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(buttonLabel),
                  onPressed: enabled
                      ? () {
                          HapticFeedback.lightImpact();
                          onTap();
                        }
                      : null,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 350.ms)
                  .slideY(
                      begin: 0.06,
                      end: 0,
                      curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}
