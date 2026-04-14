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

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final i = incidents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderDark),
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
            },
          );
        },
      ),
    );
  }
}
