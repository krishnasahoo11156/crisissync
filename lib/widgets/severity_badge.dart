import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Severity badge — Aegis Protocol with gradient glow for critical levels.
class SeverityBadge extends StatelessWidget {
  final int level;
  final bool large;

  const SeverityBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.severityBg[level] ?? AppColors.surfaceContainer;
    final fg = AppColors.severityText[level] ?? AppColors.textMuted;
    final fontSize = large ? 13.0 : 11.0;
    final pad = large
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 3);

    Widget badge = Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        'SEV $level',
        style: AppTextStyles.jetBrainsMono(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
      ),
    );

    if (level == 5) return _PulsingSev5Badge(child: badge);
    return badge;
  }
}

class _PulsingSev5Badge extends StatefulWidget {
  final Widget child;
  const _PulsingSev5Badge({required this.child});
  @override
  State<_PulsingSev5Badge> createState() => _PulsingSev5BadgeState();
}

class _PulsingSev5BadgeState extends State<_PulsingSev5Badge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.badge),
          boxShadow: [
            BoxShadow(
              color: AppColors.crisisRed.withValues(alpha: 0.35 * _animation.value),
              blurRadius: 14 * _animation.value,
              spreadRadius: 1 * _animation.value,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
