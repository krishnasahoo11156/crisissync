import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/services/fcm_service.dart';

/// Notification bell with animated unread badge.
class NotificationBell extends StatelessWidget {
  final String uid;
  final VoidCallback? onTap;

  const NotificationBell({super.key, required this.uid, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: FcmService.streamUnreadCount(uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return IconButton(
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.crisisRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: AppTextStyles.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
