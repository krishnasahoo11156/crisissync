import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/providers/incident_provider.dart';
import 'package:crisissync/providers/staff_provider.dart';
import 'package:crisissync/services/analytics_service.dart';
import 'package:crisissync/services/gemini_service.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/seed_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Admin overview — Aegis Protocol dashboard with stat cards, charts, AI briefing.
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
    try { await SeedService.seedGimmickData(); } catch (e) { debugPrint('Failed to seed gimmick data: $e'); }
  }

  Future<void> _loadBriefing() async {
    setState(() => _loadingBriefing = true);
    try {
      final incidents = context.read<IncidentProvider>().activeIncidents;
      final data = incidents.map((i) => {'roomNumber': i.roomNumber, 'crisisType': i.crisisType, 'severity': i.severity, 'status': i.status}).toList();
      _briefing = await GeminiService.generateBriefing(data);
    } catch (_) { _briefing = 'Unable to generate briefing at this time.'; }
    if (mounted) setState(() => _loadingBriefing = false);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Overview', style: AppTextStyles.clashDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Real-time operational intelligence', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 28),

            // Stat cards
            Row(children: [
              _StatCard(label: 'Active Incidents', value: '${incidents.activeCount}', color: AppColors.crisisRed, icon: Icons.warning_amber_rounded),
              const SizedBox(width: 16),
              _StatCard(label: 'Avg Response Time', value: '—', color: AppColors.amberAlert, icon: Icons.timer_outlined),
              const SizedBox(width: 16),
              _StatCard(label: 'Resolved Today', value: '—', color: AppColors.signalTeal, icon: Icons.check_circle_outline, useAnalytics: true),
              const SizedBox(width: 16),
              _StatCard(label: 'On-Duty Staff', value: '${staff.onDutyStaff.length}', color: AppColors.primaryPurple, icon: Icons.people_outline),
            ]),
            const SizedBox(height: 28),

            // 60/40 layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 6, child: _buildIncidentTable(incidents.activeIncidents, context)),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: _buildDonutChart(incidents.activeIncidents)),
                  ]);
                }
                return Column(children: [
                  _buildIncidentTable(incidents.activeIncidents, context),
                  const SizedBox(height: 24),
                  _buildDonutChart(incidents.activeIncidents),
                ]);
              },
            ),
            const SizedBox(height: 28),
            _buildRecentResolved(),
            const SizedBox(height: 28),
            _buildBriefing(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTable(List<IncidentModel> incidents, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderGhost),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(22),
          child: Row(children: [
            Text('Active Incidents', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.crisisRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.badge), border: Border.all(color: AppColors.crisisRed.withValues(alpha: 0.2))),
              child: Text('${incidents.length}', style: AppTextStyles.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.crisisRed)),
            ),
          ]),
        ),
        if (incidents.isEmpty)
          Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('No active incidents', style: AppTextStyles.dmSans(color: AppColors.textMuted))))
        else
          ...incidents.take(10).map((i) => _IncidentRow(incident: i, onTap: () => context.go('/admin/incidents'))),
      ]),
    );
  }

  Widget _buildDonutChart(List<IncidentModel> incidents) {
    final typeCount = <String, int>{};
    for (final i in incidents) { typeCount[i.crisisType] = (typeCount[i.crisisType] ?? 0) + 1; }
    final colors = {'fire': AppColors.fireColor, 'medical': AppColors.medicalColor, 'security': AppColors.securityColor};

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.borderGhost)),
      child: Column(children: [
        Text('Incidents by Type', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: incidents.isEmpty
              ? Center(child: Text('No data', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
              : PieChart(PieChartData(
                  centerSpaceRadius: 50,
                  sectionsSpace: 3,
                  sections: typeCount.entries.map((e) => PieChartSectionData(
                    value: e.value.toDouble(),
                    color: colors[e.key] ?? AppColors.textMuted,
                    radius: 40,
                    title: '${e.value}',
                    titleStyle: AppTextStyles.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  )).toList(),
                )),
        ),
        const SizedBox(height: 20),
        Wrap(spacing: 16, runSpacing: 8, children: typeCount.entries.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key] ?? AppColors.textMuted, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('${e.key}: ${e.value}', style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textSecondary)),
        ])).toList()),
      ]),
    );
  }

  Widget _buildRecentResolved() {
    return StreamBuilder<List<IncidentModel>>(
      stream: IncidentService.streamResolvedIncidents(),
      builder: (context, snapshot) {
        final resolved = (snapshot.data ?? []).take(5).toList();
        return Container(
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.borderGhost)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(children: [
                Text('Recent Resolved', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.signalTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.badge), border: Border.all(color: AppColors.signalTeal.withValues(alpha: 0.2))),
                  child: Text('Last 5', style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.signalTeal)),
                ),
                const Spacer(),
                TextButton(onPressed: () => context.go('/admin/incidents'), child: Text('View all →', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.signalTeal))),
              ]),
            ),
            if (resolved.isEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: Text('No resolved incidents yet', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
            else
              ...resolved.map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderGhost, width: 0.5))),
                child: Row(children: [
                  SizedBox(width: 60, child: Text(i.roomNumber, style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary))),
                  CrisisTypeIcon(type: i.crisisType, size: 16),
                  const SizedBox(width: 6),
                  SizedBox(width: 70, child: Text(i.crisisType, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textSecondary))),
                  SeverityBadge(level: i.severity),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i.resolvedAt != null ? DateFormat('MMM dd, HH:mm').format(i.resolvedAt!) : '', style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted))),
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.signalTeal.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check, color: AppColors.signalTeal, size: 12)),
                ]),
              )),
          ]),
        );
      },
    );
  }

  Widget _buildBriefing() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderGhost),
        boxShadow: [BoxShadow(color: AppColors.primaryPurple.withValues(alpha: 0.04), blurRadius: 32)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('AI Executive Briefing', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          const GeminiTag(),
          const SizedBox(width: 8),
          IconButton(onPressed: _loadBriefing, icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 18), tooltip: 'Regenerate'),
        ]),
        const SizedBox(height: 16),
        if (_loadingBriefing) const LoadingSkeleton(rows: 4, height: 16)
        else Text(_briefing ?? 'Click refresh to generate a briefing.', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textSecondary).copyWith(height: 1.6)),
      ]),
    );
  }
}

class _IncidentRow extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback onTap;
  const _IncidentRow({required this.incident, required this.onTap});
  @override
  State<_IncidentRow> createState() => _IncidentRowState();
}

class _IncidentRowState extends State<_IncidentRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final i = widget.incident;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.elevated : Colors.transparent,
            border: const Border(bottom: BorderSide(color: AppColors.borderGhost, width: 0.5)),
          ),
          child: Row(children: [
            SizedBox(width: 60, child: Text(i.roomNumber, style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary))),
            CrisisTypeIcon(type: i.crisisType, size: 16),
            const SizedBox(width: 6),
            SizedBox(width: 70, child: Text(i.crisisType, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textSecondary))),
            SeverityBadge(level: i.severity),
            const SizedBox(width: 8),
            Expanded(child: Text(
              i.acceptedBy != null ? i.acceptedBy!['staffName'] ?? '' : 'Unassigned',
              style: AppTextStyles.dmSans(fontSize: 12, color: i.acceptedBy != null ? AppColors.textPrimary : AppColors.crisisRed),
            )),
            Text(i.elapsedFormatted, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 12),
            StatusIndicator(status: i.status, showLabel: false),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool useAnalytics;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon, this.useAnalytics = false});
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: widget.useAnalytics
          ? StreamBuilder<Map<String, dynamic>>(
              stream: AnalyticsService.streamTodayAnalytics(),
              builder: (context, snap) {
                final data = snap.data ?? {};
                final displayValue = widget.label.contains('Resolved') ? '${data['resolvedIncidents'] ?? 0}'
                    : widget.label.contains('Response') ? '${(data['avgResponseTime'] as num?)?.toStringAsFixed(1) ?? '—'}m' : widget.value;
                return _buildCard(displayValue);
              },
            )
          : _buildCard(widget.value),
    );
  }

  Widget _buildCard(String displayValue) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: AppAnimation.defaultCurve,
        padding: const EdgeInsets.all(22),
        transform: Matrix4.identity()..translate(0.0, _hovered ? -3.0 : 0.0),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.elevated : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: _hovered ? widget.color.withValues(alpha: 0.25) : AppColors.borderGhost),
          boxShadow: [if (_hovered) BoxShadow(color: widget.color.withValues(alpha: 0.08), blurRadius: 24)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const Spacer(),
            Container(height: 3, width: 32, decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.color, widget.color.withValues(alpha: 0.2)]), borderRadius: BorderRadius.circular(2))),
          ]),
          const SizedBox(height: 16),
          Text(displayValue, style: AppTextStyles.clashDisplay(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.label, style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}
