import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/config/router.dart';
import 'package:crisissync/providers/auth_provider.dart';

/// Landing page — redesigned.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _goToPortal(String portal) {
    final auth = context.read<AuthProvider>();

    if (auth.isLoggedIn) {
      final role = auth.userRole ?? 'guest';
      if (role == 'admin') {
        context.go(AppRouter.homeForRole(portal == 'admin' ? 'admin' : portal == 'staff' ? 'staff' : 'guest'));
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Colors specific to the new design
    const lightPurple = Color(0xFFC6C2FF);

    return Scaffold(
      backgroundColor: const Color(0xFF111111), // Dark background matching image
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Text(
                    'CrisisSync',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Nav Links (Hidden on small mobile for simplicity, but we can keep it if space allows)
                  if (!isMobile)
                    Row(
                      children: [
                        _NavLink('SOLUTIONS', isActive: true),
                        const SizedBox(width: 32),
                        _NavLink('INFRASTRUCTURE'),
                        const SizedBox(width: 32),
                        _NavLink('INTELLIGENCE'),
                      ],
                    ),
                  // Deploy System Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: lightPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Deploy System',
                      style: AppTextStyles.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Section
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48, vertical: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Content
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System Online Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2E26), // Dark green bg
                            borderRadius: BorderRadius.circular(100),
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
                                'SYSTEM ONLINE',
                                style: AppTextStyles.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.signalTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Headline
                        Text(
                          'CrisisSync: From\ncrisis to resolved\n— under 5\nminutes.',
                          style: AppTextStyles.clashDisplay(
                            fontSize: isMobile ? 48 : 72,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ).copyWith(height: 1.1),
                        ),
                        const SizedBox(height: 24),
                        // Subheadline
                        Padding(
                          padding: const EdgeInsets.only(right: 48.0),
                          child: Text(
                            'The intelligence framework\nengineered for high-stakes\nenvironments where clarity saves\nlives.',
                            style: AppTextStyles.dmSans(
                              fontSize: isMobile ? 18 : 24,
                              color: const Color(0xFFAAAAAA),
                            ).copyWith(height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // CTA and Stats
                        Row(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  // Just jump to portals or act as generic CTA
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: lightPurple,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Initialize Protocol',
                                        style: AppTextStyles.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward,
                                          color: Colors.black, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '2,491',
                                  style: AppTextStyles.clashDisplay(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'INCIDENTS RESOLVED TODAY',
                                  style: AppTextStyles.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 48),
                  // Right Image
                  if (!isMobile)
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 500,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Access Portals Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access Portals',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your operational clearance level to access\nspecialized command interfaces.',
                    style: AppTextStyles.dmSans(
                      fontSize: 16,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Portal Cards
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _NewPortalCard(
                        clearanceLevel: 'CLEARANCE LEVEL 1',
                        title: 'Guest Portal',
                        description:
                            'Limited access to public incident boards and\nstatus reporting tools.',
                        icon: Icons.badge_outlined,
                        accentColor: AppColors.signalTeal,
                        onTap: () => _goToPortal('guest'),
                        width: isMobile ? screenWidth - 48 : 350,
                      ),
                      _NewPortalCard(
                        clearanceLevel: 'CLEARANCE LEVEL 2',
                        title: 'Staff Portal',
                        description:
                            'Full access to active incident management,\ncomms arrays, and logging.',
                        icon: Icons.security_outlined,
                        accentColor: const Color(0xFFF18E7F), // Soft orange/red
                        onTap: () => _goToPortal('staff'),
                        width: isMobile ? screenWidth - 48 : 350,
                      ),
                      _NewPortalCard(
                        clearanceLevel: 'CLEARANCE LEVEL 3',
                        title: 'Admin Portal',
                        description:
                            'System overrides, protocol configuration, and\ncomprehensive analytics.',
                        icon: Icons.shield_outlined,
                        accentColor: const Color(0xFFB4A0FF), // Soft purple
                        onTap: () => _goToPortal('admin'),
                        width: isMobile ? screenWidth - 48 : 350,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 48, vertical: 48),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF222222)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CrisisSync',
                          style: AppTextStyles.clashDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '© 2024 CrisisSync Intelligence. Operational Protocol\nAlpha-6.',
                          style: AppTextStyles.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPERATIONS',
                          style: AppTextStyles.clashDisplay(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
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
                        Text(
                          'LEGAL',
                          style: AppTextStyles.clashDisplay(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final bool isActive;

  const _NavLink(this.text, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: AppTextStyles.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF6A98F0) : const Color(0xFFAAAAAA),
            letterSpacing: 1,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 32,
            color: const Color(0xFF6A98F0),
          )
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;

  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.dmSans(
        fontSize: 12,
        color: const Color(0xFF888888),
      ),
    );
  }
}

class _NewPortalCard extends StatefulWidget {
  final String clearanceLevel;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final double width;

  const _NewPortalCard({
    required this.clearanceLevel,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    required this.width,
  });

  @override
  State<_NewPortalCard> createState() => _NewPortalCardState();
}

class _NewPortalCardState extends State<_NewPortalCard> {
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
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF222222) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? widget.accentColor.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 24),
              ),
              const SizedBox(height: 48),
              Text(
                widget.clearanceLevel,
                style: AppTextStyles.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: AppTextStyles.clashDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: AppTextStyles.dmSans(
                  fontSize: 14,
                  color: const Color(0xFFAAAAAA),
                ).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

