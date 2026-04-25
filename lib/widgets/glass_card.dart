import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Premium Glassmorphism card — "The Orchestrated Pulse" design system.
///
/// Combines translucent surfaces with backdrop blur and optional accent glow
/// to create depth without heavy shadows. Supports ambient glow colors for
/// contextual emphasis (e.g., teal for guest, coral for staff, purple for admin).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? accentGlow;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.card,
    this.accentGlow,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Ambient glow — felt, not seen
          BoxShadow(
            color: (accentGlow ?? AppColors.textPrimary).withValues(alpha: 0.04),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              // 60% opacity surface variant for glass effect
              color: AppColors.surfaceHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                // Ghost border — barely visible structural hint
                color: AppColors.borderGhost,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated glass card with hover effects — lifts and glows on hover.
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? accentGlow;
  final VoidCallback? onTap;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.card,
    this.accentGlow,
    this.onTap,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.accentGlow ?? AppColors.primaryPurple;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: _hovered ? 0.15 : 0.04),
                blurRadius: _hovered ? 32 : 16,
                spreadRadius: _hovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: AppAnimation.normal,
                padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.elevated.withValues(alpha: 0.8)
                      : AppColors.surfaceHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _hovered
                        ? glowColor.withValues(alpha: 0.3)
                        : AppColors.borderGhost,
                    width: 1,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
