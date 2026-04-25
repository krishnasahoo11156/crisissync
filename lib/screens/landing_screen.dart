import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/config/router.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'dart:ui';

/// Landing page — Aegis Protocol redesign with atmospheric depth,
/// glassmorphism portals, and micro-animations.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _goToPortal(String portal) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      final role = auth.userRole ?? 'guest';
      if (role == 'admin') {
        context.go(AppRouter.homeForRole(portal));
        return;
      }
      if (role == portal) {
        context.go(AppRouter.homeForRole(role));
        return;
      }
    }
    context.go('/auth?portal=$portal');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E13),
      body: Stack(
        children: [
          // ── Atmospheric gradient orbs ──
          _GradientOrb(
            color: AppColors.primaryPurpleDim,
            size: 600,
            top: -200,
            right: -100,
            opacity: 0.08,
          ),
          _GradientOrb(
            color: AppColors.signalTeal,
            size: 500,
            bottom: 100,
            left: -150,
            opacity: 0.06,
          ),
          _GradientOrb(
            color: AppColors.crisisRed,
            size: 400,
            top: 400,
            right: 200,
            opacity: 0.04,
          ),

          // ── Main content ──
          FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavBar(isMobile),
                  _buildHero(isMobile, w),
                  const SizedBox(height: 100),
                  _buildPortals(isMobile, w),
                  const SizedBox(height: 120),
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation Bar ───────────────────────────────────────────────────────
  Widget _buildNavBar(bool isMobile) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 64,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E13).withValues(alpha: 0.7),
            border: const Border(
              bottom: BorderSide(color: AppColors.borderGhost),
            ),
          ),
          child: Row(
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryPurple, AppColors.primaryPurpleDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.crisis_alert, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'CrisisSync',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!isMobile) ...[
                _NavLink('SOLUTIONS', isActive: true),
                const SizedBox(width: 32),
                _NavLink('INFRASTRUCTURE'),
                const SizedBox(width: 32),
                _NavLink('INTELLIGENCE'),
                const SizedBox(width: 40),
              ],
              // CTA button with gradient
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.primaryPurpleDim],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    'Deploy System',
                    style: AppTextStyles.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────────────
  Widget _buildHero(bool isMobile, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 48 : 80,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System Online badge
                _SystemOnlineBadge(),
                const SizedBox(height: 32),
                // Headline
                Text(
                  'CrisisSync: From\ncrisis to resolved\n— under 5\nminutes.',
                  style: AppTextStyles.clashDisplay(
                    fontSize: isMobile ? 42 : 72,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.5,
                  ).copyWith(height: 1.08),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: Text(
                    'The intelligence framework engineered for\nhigh-stakes environments where clarity\nsaves lives.',
                    style: AppTextStyles.dmSans(
                      fontSize: isMobile ? 16 : 20,
                      color: AppColors.textSecondary,
                    ).copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: 48),
                // CTA row
                Row(
                  children: [
                    _GradientCTAButton(
                      label: 'Initialize Protocol',
                      onTap: () {},
                    ),
                    const SizedBox(width: 40),
                    _StatCounter(value: '2,491', label: 'INCIDENTS RESOLVED TODAY'),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 48),
            Expanded(
              flex: 5,
              child: AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                ),
                child: Container(
                  height: 520,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        blurRadius: 60,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  // Gradient overlay
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0E0E13).withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Portal Cards Section ─────────────────────────────────────────────────
  Widget _buildPortals(bool isMobile, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Access Portals',
            style: AppTextStyles.clashDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your operational clearance level to access\nspecialized command interfaces.',
            style: AppTextStyles.dmSans(
              fontSize: 16,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _PortalCard(
                clearanceLevel: 'CLEARANCE LEVEL 1',
                title: 'Guest Portal',
                description: 'Public incident boards and\nstatus reporting tools.',
                icon: Icons.badge_outlined,
                accentColor: AppColors.signalTeal,
                onTap: () => _goToPortal('guest'),
                width: isMobile ? screenWidth - 48 : 360,
              ),
              _PortalCard(
                clearanceLevel: 'CLEARANCE LEVEL 2',
                title: 'Staff Portal',
                description: 'Active incident management,\ncomms arrays, and logging.',
                icon: Icons.security_outlined,
                accentColor: AppColors.crisisRed,
                onTap: () => _goToPortal('staff'),
                width: isMobile ? screenWidth - 48 : 360,
              ),
              _PortalCard(
                clearanceLevel: 'CLEARANCE LEVEL 3',
                title: 'Admin Portal',
                description: 'System overrides, protocol config,\nand comprehensive analytics.',
                icon: Icons.shield_outlined,
                accentColor: AppColors.primaryPurple,
                onTap: () => _goToPortal('admin'),
                width: isMobile ? screenWidth - 48 : 360,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: 48,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGhost)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CrisisSync', style: AppTextStyles.clashDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Text('© 2024 CrisisSync Intelligence.\nOperational Protocol Alpha-6.',
                    style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPERATIONS', style: AppTextStyles.clashDisplay(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _FooterLink('System Status'),
                const SizedBox(height: 12),
                _FooterLink('Protocol Documentation'),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LEGAL', style: AppTextStyles.clashDisplay(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _FooterLink('Compliance'),
                const SizedBox(height: 12),
                _FooterLink('Security Audit'),
                const SizedBox(height: 12),
                _FooterLink('Terms of Engagement'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _GradientOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double? top, bottom, left, right;
  final double opacity;
  const _GradientOrb({required this.color, required this.size, this.top, this.bottom, this.left, this.right, this.opacity = 0.08});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
        ),
      ),
    );
  }
}

class _SystemOnlineBadge extends StatefulWidget {
  @override
  State<_SystemOnlineBadge> createState() => _SystemOnlineBadgeState();
}

class _SystemOnlineBadgeState extends State<_SystemOnlineBadge> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.signalTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.signalTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppColors.signalTeal.withValues(alpha: 0.5 + _c.value * 0.5),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.signalTeal.withValues(alpha: 0.4 * _c.value), blurRadius: 8, spreadRadius: 1)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('SYSTEM ONLINE', style: AppTextStyles.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.signalTeal)),
        ],
      ),
    );
  }
}

class _GradientCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientCTAButton({required this.label, required this.onTap});
  @override
  State<_GradientCTAButton> createState() => _GradientCTAButtonState();
}

class _GradientCTAButtonState extends State<_GradientCTAButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.primaryPurpleDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: _hovered ? 0.4 : 0.2),
                blurRadius: _hovered ? 24 : 12,
                spreadRadius: _hovered ? 2 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: AppTextStyles.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: AppAnimation.normal,
                transform: Matrix4.identity()..translate(_hovered ? 4.0 : 0.0, 0.0),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final String value, label;
  const _StatCounter({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.clashDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String text;
  final bool isActive;
  const _NavLink(this.text, {this.isActive = false});
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: AppTextStyles.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isActive || _hovered ? AppColors.primaryPurple : AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: AppAnimation.fast,
            height: 2,
            width: widget.isActive ? 32 : (_hovered ? 20 : 0),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  const _FooterLink(this.text);
  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedDefaultTextStyle(
        duration: AppAnimation.fast,
        style: AppTextStyles.dmSans(fontSize: 13, color: _hovered ? AppColors.textSecondary : AppColors.textMuted),
        child: Text(widget.text),
      ),
    );
  }
}

class _PortalCard extends StatefulWidget {
  final String clearanceLevel, title, description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final double width;
  const _PortalCard({required this.clearanceLevel, required this.title, required this.description, required this.icon, required this.accentColor, required this.onTap, required this.width});
  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
          width: widget.width,
          padding: const EdgeInsets.all(32),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.elevated : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? widget.accentColor.withValues(alpha: 0.4) : AppColors.borderGhost,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: _hovered ? 0.15 : 0.0),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              AnimatedContainer(
                duration: AppAnimation.normal,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _hovered
                      ? LinearGradient(colors: [widget.accentColor.withValues(alpha: 0.2), widget.accentColor.withValues(alpha: 0.05)])
                      : null,
                  color: _hovered ? null : widget.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 24),
              ),
              const SizedBox(height: 48),
              Text(widget.clearanceLevel, style: AppTextStyles.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w600, color: widget.accentColor)),
              const SizedBox(height: 10),
              Text(widget.title, style: AppTextStyles.clashDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(widget.description, style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textSecondary).copyWith(height: 1.6)),
              const SizedBox(height: 24),
              // Arrow indicator
              AnimatedContainer(
                duration: AppAnimation.normal,
                transform: Matrix4.identity()..translate(_hovered ? 6.0 : 0.0, 0.0),
                child: Row(
                  children: [
                    Text('Access Portal', style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: _hovered ? widget.accentColor : AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 16, color: _hovered ? widget.accentColor : AppColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
