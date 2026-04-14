import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/services/fcm_service.dart';

/// Admin layout with sidebar navigation (geminiPurple accents).
class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.void_,
              border: Border(right: BorderSide(color: AppColors.borderDark, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('CrisisSync', style: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.geminiPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text('ADMIN', style: AppTextStyles.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.geminiPurple)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _NavItem(icon: Icons.dashboard_outlined, label: 'Overview', isActive: currentPath == '/admin', onTap: () => context.go('/admin'), accentColor: AppColors.geminiPurple),
                _NavItem(icon: Icons.list_alt, label: 'Incident Log', isActive: currentPath == '/admin/incidents', onTap: () => context.go('/admin/incidents'), accentColor: AppColors.geminiPurple),
                _NavItem(icon: Icons.people_outline, label: 'Staff Management', isActive: currentPath == '/admin/staff', onTap: () => context.go('/admin/staff'), accentColor: AppColors.geminiPurple),
                _NavItem(icon: Icons.bar_chart, label: 'Analytics', isActive: currentPath == '/admin/analytics', onTap: () => context.go('/admin/analytics'), accentColor: AppColors.geminiPurple),
                _NavItem(icon: Icons.business, label: 'Venue Config', isActive: currentPath == '/admin/venue', onTap: () => context.go('/admin/venue'), accentColor: AppColors.geminiPurple),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Divider(color: AppColors.borderDark, height: 1),
                ),
                const Spacer(),
                _NavItem(icon: Icons.logout, label: 'Sign Out', isActive: false, onTap: () async {
                  await auth.signOut();
                  if (context.mounted) context.go('/');
                }, accentColor: AppColors.geminiPurple),
                const SizedBox(height: 16),
                if (user != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.button)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18, backgroundColor: AppColors.geminiPurple,
                          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                              Text('Administrator', style: AppTextStyles.jetBrainsMono(fontSize: 10, color: AppColors.geminiPurple)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap, required this.accentColor});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.surface : (_hovered ? AppColors.surface.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: widget.isActive ? Border(left: BorderSide(color: widget.accentColor, width: 2)) : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: widget.isActive ? AppColors.textPrimary : AppColors.textMuted),
              const SizedBox(width: 12),
              Text(widget.label, style: AppTextStyles.dmSans(fontSize: 14, fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.w400, color: widget.isActive ? AppColors.textPrimary : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
