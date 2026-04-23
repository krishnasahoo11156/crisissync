import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/services/fcm_service.dart';

/// Staff layout with sidebar navigation.
class StaffLayout extends StatelessWidget {
  final Widget child;
  const StaffLayout({super.key, required this.child});

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
              border: Border(
                right: BorderSide(color: AppColors.borderDark, width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'CrisisSync',
                        style: AppTextStyles.clashDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // LIVE indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _PulsingDot(),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTextStyles.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.signalTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Nav items
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isActive: currentPath == '/staff/dashboard',
                  onTap: () => context.go('/staff/dashboard'),
                ),
                _NavItem(
                  icon: Icons.map_outlined,
                  label: 'Map View',
                  isActive: currentPath == '/staff/map',
                  onTap: () => context.go('/staff/map'),
                ),
                _NavItem(
                  icon: Icons.history,
                  label: 'Resolved Incidents',
                  isActive: currentPath == '/staff/history',
                  onTap: () => context.go('/staff/history'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Divider(color: AppColors.borderDark, height: 1),
                ),
                // Notifications
                if (user != null)
                  StreamBuilder<int>(
                    stream: FcmService.streamUnreadCount(user.uid),
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      return _NavItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        badge: count > 0 ? count : null,
                        isActive: false,
                        onTap: () => _showNotifications(context, user.uid),
                      );
                    },
                  ),
                const Spacer(),
                // Sign out
                _NavItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  isActive: false,
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) context.go('/');
                  },
                ),
                const SizedBox(height: 16),
                // Staff info
                // Staff info card with edit-name support
                if (user != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.crisisRed,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: AppTextStyles.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.staffRole != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.crisisRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.badge),
                                  ),
                                  child: Text(
                                    user.staffRole!,
                                    style: AppTextStyles.jetBrainsMono(
                                      fontSize: 10,
                                      color: AppColors.crisisRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Edit name button — updates AuthProvider → notifyListeners()
                        IconButton(
                          onPressed: () => _showEditNameDialog(context, user.name),
                          icon: const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
                          tooltip: 'Edit name',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Edit name dialog for staff — saves via AuthProvider.updateName().
  /// notifyListeners() is called internally so the sidebar and any other
  /// context.watch<AuthProvider>() widgets rebuild immediately.
  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text(
            'Edit Display Name',
            style: AppTextStyles.clashDisplay(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Your display name',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
              ),
              if (dialogError != null) ...[  
                const SizedBox(height: 8),
                Text(
                  dialogError!,
                  style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.crisisRed),
                ),
              ],
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => dialogError = 'Name cannot be empty.');
                  return;
                }
                await context.read<AuthProvider>().updateName(name);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => FcmService.markAllAsRead(uid),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.dmSans(
                        fontSize: 12,
                        color: AppColors.signalTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FcmService.streamNotifications(uid),
                  builder: (context, snap) {
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No notifications',
                            style: AppTextStyles.dmSans(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isRead = item['read'] == true;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isRead ? AppColors.void_ : AppColors.elevated,
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          child: Text(
                            item['message'] ?? '',
                            style: AppTextStyles.dmSans(
                              fontSize: 13,
                              color: isRead ? AppColors.textMuted : AppColors.textPrimary,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

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
            color: widget.isActive
                ? AppColors.surface
                : (_hovered ? AppColors.surface.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: widget.isActive
                ? const Border(left: BorderSide(color: AppColors.crisisRed, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive ? AppColors.textPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyles.dmSans(
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.w400,
                    color: widget.isActive ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.crisisRed,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: AppTextStyles.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.signalTeal.withValues(alpha: 0.5 + (_c.value * 0.5)),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.signalTeal.withValues(alpha: 0.3 * _c.value),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
