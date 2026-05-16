import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/shared/theme/app_theme.dart';

/// Computes a 0–100 completeness score for a resume.
int resumeScore(Resume r) {
  int score = 0;
  // Personal info (40 pts)
  if (r.personalInfo.fullName.isNotEmpty) score += 8;
  if (r.personalInfo.email.isNotEmpty) score += 8;
  if (r.personalInfo.title != null) score += 6;
  if (r.personalInfo.phone != null) score += 4;
  if (r.personalInfo.location != null) score += 4;
  if (r.personalInfo.bio != null) score += 6;
  if (r.personalInfo.linkedIn != null) score += 2;
  if (r.personalInfo.github != null) score += 2;
  // Sections (60 pts)
  if (r.experiences.isNotEmpty) score += 20;
  if (r.education.isNotEmpty) score += 15;
  if (r.skills.isNotEmpty) score += 15;
  if (r.projects.isNotEmpty) score += 7;
  if (r.certifications.isNotEmpty) score += 3;
  return score.clamp(0, 100);
}

Color _scoreColor(int score) {
  if (score >= 80) return const Color(0xFF22C55E);
  if (score >= 50) return AppTheme.accent;
  return const Color(0xFFEF4444);
}

String _scoreLabel(int score) {
  if (score >= 80) return 'Great';
  if (score >= 50) return 'Good';
  return 'Needs work';
}

class ScoreRing extends StatefulWidget {
  final int score;
  final double size;

  const ScoreRing({super.key, required this.score, this.size = 80});

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(
        begin: old.score / 100,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.score);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: _anim.value,
            color: color,
            trackColor: color.withOpacity(0.12),
            strokeWidth: widget.size * 0.1,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.score * _anim.value).round()}',
                  style: TextStyle(
                    fontSize: widget.size * 0.26,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: widget.size * 0.13,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.7),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Compact inline version with label, used inside cards.
class ScoreRingWithLabel extends StatelessWidget {
  final Resume resume;

  const ScoreRingWithLabel({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final score = resumeScore(resume);
    final color = _scoreColor(score);
    final label = _scoreLabel(score);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScoreRing(score: score, size: 56),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
            Text('completeness',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
