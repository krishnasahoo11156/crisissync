import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/providers/incident_provider.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/email_service.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/incident_card.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:intl/intl.dart';

/// Staff dashboard with live incident list.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidents = context.watch<IncidentProvider>();
    final user = auth.user;

    final filtered = _applyFilter(incidents.activeIncidents);
    final criticalIncidents = incidents.activeIncidents.where((i) => i.severity >= 4).toList();

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: SizedBox.expand(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Critical alert banner
          if (criticalIncidents.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2A0A08),
                border: Border(
                  bottom: BorderSide(color: AppColors.crisisRed, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _FlashingBar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${criticalIncidents.length} CRITICAL — Room ${criticalIncidents.first.roomNumber} requires immediate response',
                      style: AppTextStyles.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.crisisRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Active Incidents',
                  style: AppTextStyles.clashDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.crisisRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    '${incidents.activeCount}',
                    style: AppTextStyles.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.crisisRed,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isActive: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Fire', isActive: _filter == 'fire', onTap: () => setState(() => _filter = 'fire')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Medical', isActive: _filter == 'medical', onTap: () => setState(() => _filter = 'medical')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Security', isActive: _filter == 'security', onTap: () => setState(() => _filter = 'security')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Other', isActive: _filter == 'other', onTap: () => setState(() => _filter = 'other')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Incident list
          Expanded(
            child: incidents.isLoading
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ClipRect(child: LoadingSkeleton(rows: 3, height: 100)),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, color: AppColors.signalTeal.withValues(alpha: 0.5), size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'No active incidents',
                              style: AppTextStyles.dmSans(fontSize: 18, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All clear — monitoring for new reports',
                              style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final incident = filtered[index];
                          return IncidentCard(
                            incident: incident,
                            onTap: () => context.go('/staff/incident/${incident.id}'),
                            onAccept: incident.status == 'active' && user != null
                                ? () => _acceptIncident(incident, user)
                                : null,
                          );
                        },
                      ),
          ),

          // Recent Incidents section
          _buildRecentIncidentsSection(context),
        ],
      )),
    );
  }

  Widget _buildRecentIncidentsSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 0.5)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        backgroundColor: const Color(0xFF0D0D0D),
        collapsedBackgroundColor: Colors.transparent,
        leading: const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 20),
        title: Text(
          'Recent Incidents',
          style: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        iconColor: AppColors.textMuted,
        collapsedIconColor: AppColors.textMuted,
        children: [
          StreamBuilder<List<IncidentModel>>(
            stream: IncidentService.streamResolvedIncidents(),
            builder: (context, snapshot) {
              final recent = (snapshot.data ?? []).take(5).toList();
              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No recent resolved incidents', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                );
              }
              return Column(
                children: recent.map((i) => InkWell(
                  onTap: () => context.go('/staff/incident/${i.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        CrisisTypeIcon(type: i.crisisType, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${i.crisisType.toUpperCase()} — Room ${i.roomNumber}',
                                  style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                              if (i.resolvedAt != null)
                                Text(DateFormat('MMM dd, HH:mm').format(i.resolvedAt!),
                                    style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        SeverityBadge(level: i.severity),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                )).toList(),
              );
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/staff/history'),
              child: Text('View all resolved →', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.signalTeal)),
            ),
          ),
        ],
      ),
    );
  }

  List<IncidentModel> _applyFilter(List<IncidentModel> list) {
    if (_filter == 'all') return list;
    return list.where((i) => i.crisisType.toLowerCase() == _filter).toList();
  }

  Future<void> _acceptIncident(IncidentModel incident, user) async {
    try {
      await IncidentService.acceptIncident(
        incidentId: incident.id,
        staffUid: user.uid,
        staffName: user.name,
        staffRole: user.staffRole ?? 'Staff',
      );

      // Send email
      try {
        await EmailService.sendIncidentAccepted(
          guestEmail: incident.guestEmail,
          guestName: incident.guestName,
          incidentId: incident.id,
          staffName: user.name,
          staffRole: user.staffRole ?? 'Staff',
          roomNumber: incident.roomNumber,
          timestamp: DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now()),
        );
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: AppColors.crisisRed),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.crisisRed : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.badge),
          border: Border.all(
            color: isActive ? AppColors.crisisRed : AppColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FlashingBar extends StatefulWidget {
  @override
  State<_FlashingBar> createState() => _FlashingBarState();
}

class _FlashingBarState extends State<_FlashingBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
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
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.crisisRed.withValues(alpha: _c.value),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
