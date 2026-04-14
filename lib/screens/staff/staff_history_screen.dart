import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:intl/intl.dart';

/// Staff resolved incidents history.
class StaffHistoryScreen extends StatelessWidget {
  const StaffHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resolved Incidents',
              style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<IncidentModel>>(
                stream: IncidentService.streamResolvedIncidents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
                  }
                  final incidents = snapshot.data ?? [];
                  if (incidents.isEmpty) {
                    return Center(
                      child: Text('No resolved incidents yet', style: AppTextStyles.dmSans(fontSize: 16, color: AppColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final i = incidents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: InkWell(
                          onTap: () => context.go('/staff/incident/${i.id}'),
                          child: Row(
                            children: [
                              CrisisTypeIcon(type: i.crisisType, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Room ${i.roomNumber}', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text(
                                      i.resolvedAt != null ? DateFormat('MMM dd, yyyy – hh:mm a').format(i.resolvedAt!) : '',
                                      style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              SeverityBadge(level: i.severity),
                              const SizedBox(width: 8),
                              StatusIndicator(status: i.status, showLabel: false),
                            ],
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
    );
  }
}
