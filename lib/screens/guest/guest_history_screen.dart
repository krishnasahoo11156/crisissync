import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:intl/intl.dart';

/// Guest incident history screen.
class GuestHistoryScreen extends StatelessWidget {
  const GuestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: AppBar(
        backgroundColor: AppColors.void_,
        leading: IconButton(
          onPressed: () => context.go('/guest'),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Text(
          'Past Incidents',
          style: AppTextStyles.clashDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<List<IncidentModel>>(
        stream: IncidentService.streamGuestIncidents(auth.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
          }

          final incidents = snapshot.data ?? [];
          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No past incidents',
                    style: AppTextStyles.dmSans(fontSize: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          final recentCutoff = DateTime.now().subtract(const Duration(days: 7));
          final recentIncidents = incidents.where((i) => i.createdAt.isAfter(recentCutoff)).take(3).toList();
          final allIncidents = incidents;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Recent section header
              if (recentIncidents.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.crisisRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RECENT — LAST 7 DAYS',
                      style: AppTextStyles.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentIncidents.map((i) => _buildIncidentTile(context, i, isRecent: true)),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: 12),
              ],

              // All incidents header
              Row(
                children: [
                  Text(
                    'ALL INCIDENTS',
                    style: AppTextStyles.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      '${allIncidents.length}',
                      style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...allIncidents.map((i) => _buildIncidentTile(context, i)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncidentTile(BuildContext context, IncidentModel i, {bool isRecent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecent ? AppColors.surface.withOpacity(0.8) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isRecent && (i.status == 'active' || i.status == 'accepted')
              ? AppColors.crisisRed.withOpacity(0.4)
              : AppColors.borderDark,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (i.status == 'resolved') {
            context.go('/guest/resolved/${i.id}');
          } else {
            context.go('/guest/status/${i.id}');
          }
        },
        child: Row(
          children: [
            CrisisTypeIcon(type: i.crisisType, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(i.createdAt),
                    style: AppTextStyles.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${i.crisisType.toUpperCase()} — Room ${i.roomNumber}',
                    style: AppTextStyles.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SeverityBadge(level: i.severity),
            const SizedBox(width: 8),
            StatusIndicator(status: i.status, showLabel: false),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

