import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/providers/incident_provider.dart';
import 'package:crisissync/providers/staff_provider.dart';
import 'package:crisissync/services/analytics_service.dart';
import 'package:crisissync/services/gemini_service.dart';
import 'package:crisissync/services/seed_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:fl_chart/fl_chart.dart';

/// Admin overview dashboard with stat cards, incident table, and donut chart.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  String? _briefing;
  bool _loadingBriefing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().startListening();
      context.read<StaffProvider>().startListening();
      _loadBriefing();
      _seedGimmickDataIfNeeded();
    });
  }

  Future<void> _seedGimmickDataIfNeeded() async {
    try {
      await SeedService.seedGimmickData();
    } catch (e) {
      debugPrint('Failed to seed gimmick data: $e');
    }
  }

  Future<void> _loadBriefing() async {
    setState(() => _loadingBriefing = true);
    try {
      final incidents = context.read<IncidentProvider>().activeIncidents;
      final data = incidents.map((i) => {
        'roomNumber': i.roomNumber,
        'crisisType': i.crisisType,
        'severity': i.severity,
        'status': i.status,
      }).toList();
      _briefing = await GeminiService.generateBriefing(data);
    } catch (_) {
      _briefing = 'Unable to generate briefing at this time.';
    }
    if (mounted) setState(() => _loadingBriefing = false);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Overview', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 24),

            // Stat cards
            Row(
              children: [
                _StatCard(label: 'Active Incidents', value: '${incidents.activeCount}', color: AppColors.crisisRed),
                const SizedBox(width: 16),
                _StatCard(label: 'Avg Response Time', value: '—', color: AppColors.amberAlert),
                const SizedBox(width: 16),
                _StatCard(label: 'Resolved Today', value: '—', color: AppColors.signalTeal, useAnalytics: true),
                const SizedBox(width: 16),
                _StatCard(label: 'On-Duty Staff', value: '${staff.onDutyStaff.length}', color: AppColors.geminiPurple),
              ],
            ),
            const SizedBox(height: 24),

            // 60/40 layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildIncidentTable(incidents.activeIncidents, context)),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildDonutChart(incidents.activeIncidents)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildIncidentTable(incidents.activeIncidents, context),
                    const SizedBox(height: 24),
                    _buildDonutChart(incidents.activeIncidents),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Gemini briefing
            _buildBriefing(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTable(List<IncidentModel> incidents, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Active Incidents', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('No active incidents', style: AppTextStyles.dmSans(color: AppColors.textMuted))),
            )
          else
            ...incidents.take(10).map((i) {
              return InkWell(
                onTap: () => context.go('/admin/incidents'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 0.5))),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(i.roomNumber, style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary)),
                      ),
                      CrisisTypeIcon(type: i.crisisType, size: 16),
                      const SizedBox(width: 6),
                      SizedBox(width: 70, child: Text(i.crisisType, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted))),
                      SeverityBadge(level: i.severity),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          i.acceptedBy != null ? i.acceptedBy!['staffName'] ?? '' : 'Unassigned',
                          style: AppTextStyles.dmSans(
                            fontSize: 12,
                            color: i.acceptedBy != null ? AppColors.textPrimary : AppColors.crisisRed,
                          ),
                        ),
                      ),
                      Text(i.elapsedFormatted, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 12),
                      StatusIndicator(status: i.status, showLabel: false),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<IncidentModel> incidents) {
    final typeCount = <String, int>{};
    for (final i in incidents) {
      typeCount[i.crisisType] = (typeCount[i.crisisType] ?? 0) + 1;
    }

    final colors = {
      'fire': const Color(0xFFFF8C00),
      'medical': const Color(0xFF3B82F6),
      'security': const Color(0xFF6B7280),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text('Incidents by Type', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: incidents.isEmpty
                ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 50,
                      sections: typeCount.entries.map((e) {
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: colors[e.key] ?? AppColors.textMuted,
                          radius: 40,
                          title: '${e.value}',
                          titleStyle: AppTextStyles.jetBrainsMono(fontSize: 12, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            children: typeCount.entries.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key] ?? AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text('${e.key}: ${e.value}', style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefing() {
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
              Text('AI Executive Briefing', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              const GeminiTag(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadBriefing,
                icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 18),
                tooltip: 'Regenerate',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingBriefing)
            const LoadingSkeleton(rows: 4, height: 16)
          else
            Text(_briefing ?? 'Click refresh to generate a briefing.', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool useAnalytics;

  const _StatCard({required this.label, required this.value, required this.color, this.useAnalytics = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: useAnalytics
          ? StreamBuilder<Map<String, dynamic>>(
              stream: AnalyticsService.streamTodayAnalytics(),
              builder: (context, snap) {
                final data = snap.data ?? {};
                final displayValue = label.contains('Resolved')
                    ? '${data['resolvedIncidents'] ?? 0}'
                    : label.contains('Response')
                        ? '${(data['avgResponseTime'] as num?)?.toStringAsFixed(1) ?? '—'}m'
                        : value;
                return _buildCard(displayValue);
              },
            )
          : _buildCard(value),
    );
  }

  Widget _buildCard(String displayValue) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayValue, style: AppTextStyles.clashDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(height: 3, width: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}
