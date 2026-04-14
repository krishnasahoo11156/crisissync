import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/services/incident_service.dart';

/// Landing page — role selector with live counter.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _resolvedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadResolvedCount();
  }

  Future<void> _loadResolvedCount() async {
    try {
      final count = await IncidentService.getTodayResolvedCount();
      if (mounted) setState(() => _resolvedToday = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              // Logo
              Text(
                'CrisisSync',
                style: AppTextStyles.clashDisplay(
                  fontSize: isMobile ? 48 : 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'From crisis to resolved — under 5 minutes',
                style: AppTextStyles.dmSans(
                  fontSize: isMobile ? 16 : 20,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              // Portal cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _PortalCard(
                    title: 'Guest Portal',
                    description: 'Report emergencies and track response in real time',
                    icon: Icons.person_outline,
                    accentColor: AppColors.signalTeal,
                    cta: "I'm a Guest",
                    onTap: () => context.go('/auth?portal=guest'),
                    width: isMobile ? screenWidth - 48 : 300,
                  ),
                  _PortalCard(
                    title: 'Staff Portal',
                    description: 'Respond to incidents with AI-powered checklists',
                    icon: Icons.shield_outlined,
                    accentColor: AppColors.crisisRed,
                    cta: 'Hotel Staff',
                    onTap: () => context.go('/auth?portal=staff'),
                    width: isMobile ? screenWidth - 48 : 300,
                  ),
                  _PortalCard(
                    title: 'Admin Portal',
                    description: 'Monitor operations with analytics and AI briefings',
                    icon: Icons.analytics_outlined,
                    accentColor: AppColors.geminiPurple,
                    cta: 'Management',
                    onTap: () => context.go('/auth?portal=admin'),
                    width: isMobile ? screenWidth - 48 : 300,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Live counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.signalTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_resolvedToday incidents resolved today',
                      style: AppTextStyles.jetBrainsMono(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Footer
              Text(
                'Powered by Firebase · Gemini · Google Cloud',
                style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String cta;
  final VoidCallback onTap;
  final double width;

  const _PortalCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.cta,
    required this.onTap,
    required this.width,
  });

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.elevated : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: _isHovered ? widget.accentColor : AppColors.borderDark,
            ),
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.accentColor, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: AppTextStyles.clashDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: AppTextStyles.dmSans(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.cta,
                      style: AppTextStyles.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.accentColor,
                      ),
                    ),
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
