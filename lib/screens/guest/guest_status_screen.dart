import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// Guest live incident tracking screen.
class GuestStatusScreen extends StatefulWidget {
  final String incidentId;
  const GuestStatusScreen({super.key, required this.incidentId});

  @override
  State<GuestStatusScreen> createState() => _GuestStatusScreenState();
}

class _GuestStatusScreenState extends State<GuestStatusScreen> {
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreamBuilder<IncidentModel?>(
        stream: IncidentService.streamIncident(widget.incidentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
          }

          final incident = snapshot.data;
          if (incident == null) {
            return Center(
              child: Text(
                'Incident not found',
                style: AppTextStyles.dmSans(color: AppColors.textMuted),
              ),
            );
          }

          // Navigate to resolved screen
          if (incident.status == 'resolved') {
            final router = GoRouter.of(context);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) router.go('/guest/resolved/${widget.incidentId}');
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    onPressed: () => context.go('/guest'),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textMuted, size: 18),
                    label: Text(
                      'Back to Home',
                      style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status card
                  _buildStatusCard(incident),
                  const SizedBox(height: 16),

                  // Gemini classification
                  _buildGeminiCard(incident),
                  const SizedBox(height: 16),

                  // Timeline
                  _buildTimeline(incident),
                  const SizedBox(height: 16),

                  // Responders
                  if (incident.responders.isNotEmpty) _buildResponders(incident),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(IncidentModel incident) {
    String statusMessage;
    switch (incident.status) {
      case 'active':
        statusMessage = 'Notifying staff...';
        break;
      case 'accepted':
        final name = incident.acceptedBy?['staffName'] ?? '';
        final role = incident.acceptedBy?['staffRole'] ?? '';
        statusMessage = 'Staff on the way — $name ($role)';
        break;
      case 'responding':
        statusMessage = 'Help is here';
        break;
      case 'resolved':
        statusMessage = 'Incident Resolved';
        break;
      default:
        statusMessage = 'Processing...';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Room ${incident.roomNumber}',
                style: AppTextStyles.clashDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              CrisisTypeIcon(type: incident.crisisType, size: 22),
              const Spacer(),
              SeverityBadge(level: incident.severity, large: true),
            ],
          ),
          const SizedBox(height: 20),
          StatusIndicator(status: incident.status),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: AppTextStyles.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elapsed: ${incident.elapsedFormatted}',
            style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiCard(IncidentModel incident) {
    final gc = incident.geminiClassification;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Analysis',
                style: AppTextStyles.clashDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const GeminiTag(),
            ],
          ),
          const SizedBox(height: 16),
          if (gc == null)
            const LoadingSkeleton(rows: 4, height: 16)
          else ...[
            Text(
              gc.situationBrief,
              style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.void_,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.amberAlert, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gc.suggestedAction,
                      style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            if (gc.emotionalState != null) ...[
              const SizedBox(height: 8),
              Text(
                'Assessed state: ${gc.emotionalState}',
                style: AppTextStyles.jetBrainsMono(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(IncidentModel incident) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: AppTextStyles.clashDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...incident.timeline.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.signalTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.action,
                            style: AppTextStyles.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${event.byName} · ${DateFormat('hh:mm a').format(event.timestamp)}',
                            style: AppTextStyles.jetBrainsMono(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (event.notes != null && event.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                event.notes!,
                                style: AppTextStyles.dmSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildResponders(IncidentModel incident) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responding Staff',
            style: AppTextStyles.clashDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: incident.responders.map((r) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.crisisRed,
                  radius: 14,
                  child: Text(
                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text('${r.name} (${r.role})'),
                labelStyle: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textPrimary),
                backgroundColor: AppColors.elevated,
                side: const BorderSide(color: AppColors.borderDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
