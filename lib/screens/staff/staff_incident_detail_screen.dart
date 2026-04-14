import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/gemini_service.dart';
import 'package:crisissync/services/email_service.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:crisissync/widgets/loading_skeleton.dart';
import 'package:crisissync/widgets/adi_score_gauge.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

/// Staff incident detail screen with AI checklist.
class StaffIncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  const StaffIncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<StaffIncidentDetailScreen> createState() => _StaffIncidentDetailScreenState();
}

class _StaffIncidentDetailScreenState extends State<StaffIncidentDetailScreen> {
  final _noteController = TextEditingController();
  Timer? _adiTimer;
  double _adiScore = 0;
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
    _noteController.dispose();
    _adiTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startADITimer(IncidentModel incident) {
    _adiTimer?.cancel();
    _calculateADI(incident);
    _adiTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _calculateADI(incident);
    });
  }

  Future<void> _calculateADI(IncidentModel incident) async {
    final lastAction = incident.timeline.isNotEmpty
        ? incident.timeline.last.timestamp
        : incident.createdAt;
    final score = await GeminiService.calculateADIScore(
      severity: incident.severity,
      elapsed: DateTime.now().difference(incident.createdAt),
      timeSinceLastAction: DateTime.now().difference(lastAction),
      responderCount: incident.responders.length,
      crisisType: incident.crisisType,
    );
    if (mounted) setState(() => _adiScore = score);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return StreamBuilder<IncidentModel?>(
      stream: IncidentService.streamIncident(widget.incidentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.crisisRed));
        }

        final incident = snapshot.data;
        if (incident == null) {
          return Center(
            child: Text('Incident not found', style: AppTextStyles.dmSans(color: AppColors.textMuted)),
          );
        }

        if (incident.isActive && _adiTimer == null) {
          _startADITimer(incident);
        }

        return Scaffold(
          backgroundColor: AppColors.void_,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/staff/dashboard'),
                            child: Text('Dashboard', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                          ),
                          Text(' / ', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                          Text(
                            'Room ${incident.roomNumber} — ${incident.crisisType.toUpperCase()}',
                            style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title row
                      Row(
                        children: [
                          Text(
                            'Room ${incident.roomNumber}',
                            style: AppTextStyles.clashDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 12),
                          CrisisTypeIcon(type: incident.crisisType, size: 24),
                          const SizedBox(width: 8),
                          SeverityBadge(level: incident.severity, large: true),
                          const SizedBox(width: 12),
                          StatusIndicator(status: incident.status),
                          const Spacer(),
                          ADIScoreGauge(score: _adiScore, size: 64),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Started ${incident.elapsedFormatted} ago',
                        style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),

                      // Two-column layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _buildLeftColumn(incident, user)),
                                const SizedBox(width: 24),
                                Expanded(flex: 4, child: _buildRightColumn(incident, user)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildLeftColumn(incident, user),
                              const SizedBox(height: 24),
                              _buildRightColumn(incident, user),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Resolve footer
              if (incident.isActive && user != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.void_,
                    border: Border(top: BorderSide(color: AppColors.borderDark)),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showResolveDialog(incident, user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.signalTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    child: Text(
                      'Mark Incident Resolved',
                      style: AppTextStyles.clashDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(IncidentModel incident, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gemini checklist
        _buildChecklist(incident, user),
        const SizedBox(height: 20),
        // Situation brief
        _buildSituationBrief(incident),
        const SizedBox(height: 20),
        // External escalation
        _buildEscalation(incident, user),
      ],
    );
  }

  Widget _buildRightColumn(IncidentModel incident, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeline(incident),
        const SizedBox(height: 20),
        _buildResponders(incident),
        const SizedBox(height: 20),
        _buildNoteInput(incident, user),
      ],
    );
  }

  Widget _buildChecklist(IncidentModel incident, dynamic user) {
    final gc = incident.geminiClassification;

    return Container(
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
              Text('AI Response Checklist', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              const GeminiTag(),
            ],
          ),
          const SizedBox(height: 16),
          if (gc == null)
            const LoadingSkeleton(rows: 4, height: 52)
          else ...[
            // Classification header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.void_,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gc.crisisType.toUpperCase(), style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Response: ${gc.responseRole}', style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textMuted)),
                  if (gc.emotionalState != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: gc.emotionalState == 'Panicked' || gc.emotionalState == 'Incoherent'
                            ? AppColors.crisisRed.withValues(alpha: 0.15)
                            : AppColors.amberAlert.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        'Guest State: ${gc.emotionalState}',
                        style: AppTextStyles.jetBrainsMono(
                          fontSize: 11,
                          color: gc.emotionalState == 'Panicked' || gc.emotionalState == 'Incoherent'
                              ? AppColors.crisisRed : AppColors.amberAlert,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress
            _buildProgress(gc.checklist.length, incident.checklistProgress),
            const SizedBox(height: 12),
            // Checklist items
            ...gc.checklist.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final progress = incident.checklistProgress['$idx'];
              final isDone = progress != null && progress['done'] == true;

              return _ChecklistItem(
                text: item,
                isDone: isDone,
                doneBy: isDone ? progress['doneByName'] : null,
                doneAt: isDone && progress['doneAt'] != null ? progress['doneAt'].toDate() : null,
                onToggle: () async {
                  if (user == null) return;
                  await IncidentService.updateChecklistItem(
                    incidentId: incident.id,
                    itemIndex: idx,
                    done: !isDone,
                    staffUid: user.uid,
                    staffName: user.name,
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProgress(int total, Map<String, dynamic> progress) {
    final done = progress.values.where((v) => v is Map && v['done'] == true).length;
    final fraction = total > 0 ? done / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: fraction,
                strokeWidth: 3,
                backgroundColor: AppColors.borderDark,
                valueColor: const AlwaysStoppedAnimation(AppColors.signalTeal),
              ),
              Text(
                '$done/$total',
                style: AppTextStyles.jetBrainsMono(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$done of $total completed',
          style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSituationBrief(IncidentModel incident) {
    final gc = incident.geminiClassification;
    if (gc == null) return const SizedBox();

    return Container(
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
              Text('Situation Brief', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              const GeminiTag(),
            ],
          ),
          const SizedBox(height: 12),
          Text(gc.situationBrief, style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
          if (incident.description != null && incident.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Guest reported:', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text('"${incident.description}"', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textPrimary).copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildEscalation(IncidentModel incident, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escalate to External Services', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _EscalationBtn(label: 'Fire Brigade 101', icon: Icons.local_fire_department, color: AppColors.fireColor, onTap: () => _escalate(incident, user, 'fire', '101')),
              const SizedBox(width: 8),
              _EscalationBtn(label: 'Ambulance 102', icon: Icons.medical_services, color: AppColors.medicalColor, onTap: () => _escalate(incident, user, 'ambulance', '102')),
              const SizedBox(width: 8),
              _EscalationBtn(label: 'Police 100', icon: Icons.local_police, color: AppColors.securityColor, onTap: () => _escalate(incident, user, 'police', '100')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _escalate(IncidentModel incident, dynamic user, String service, String number) async {
    if (user == null) return;
    await IncidentService.escalateToExternal(
      incidentId: incident.id,
      staffUid: user.uid,
      staffName: user.name,
      service: service,
    );
    final uri = Uri(scheme: 'tel', path: number);
    launchUrl(uri);
  }

  Widget _buildTimeline(IncidentModel incident) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...incident.timeline.reversed.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5), decoration: const BoxDecoration(color: AppColors.signalTeal, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.action, style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('${e.byName} · ${DateFormat('hh:mm a').format(e.timestamp)}', style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
                      if (e.notes != null && e.notes!.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text(e.notes!, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted))),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Responding Staff', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (incident.responders.isEmpty)
            Text('No responders yet', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: incident.responders.map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.void_,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: AppColors.surface, child: Text(r.name.isNotEmpty ? r.name[0] : '?', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary))),
                    const SizedBox(width: 6),
                    Text(r.name, style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    Text(r.role, style: AppTextStyles.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteInput(IncidentModel incident, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Internal Note', style: AppTextStyles.clashDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Add note for team...'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              if (_noteController.text.trim().isEmpty || user == null) return;
              await IncidentService.addTimelineNote(
                incidentId: incident.id,
                staffUid: user.uid,
                staffName: user.name,
                note: _noteController.text.trim(),
              );
              _noteController.clear();
            },
            child: Text('Post Note', style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _showResolveDialog(IncidentModel incident, dynamic user) async {
    final notesController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.modal)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resolve Incident', style: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Text('Room ${incident.roomNumber} — ${incident.crisisType.toUpperCase()} — SEV ${incident.severity}',
                    style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Resolution notes (optional)...'),
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: AppColors.geminiPurple),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GeminiTag(),
                            const SizedBox(width: 8),
                            Text('Generating AI report...', style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel', style: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          setDialogState(() => isLoading = true);
                          try {
                            final aiReport = await IncidentService.resolveIncident(
                              incidentId: incident.id,
                              staffUid: user.uid,
                              staffName: user.name,
                              staffRole: user.staffRole ?? 'Staff',
                              notes: notesController.text.trim(),
                            );

                            try {
                              await EmailService.sendIncidentResolved(
                                guestEmail: incident.guestEmail,
                                guestName: incident.guestName,
                                incidentId: incident.id,
                                staffName: user.name,
                                staffRole: user.staffRole ?? 'Staff',
                                roomNumber: incident.roomNumber,
                                responseTime: incident.elapsedFormatted,
                                aiReport: aiReport,
                                notes: notesController.text.trim(),
                                timestamp: DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now()),
                              );
                            } catch (_) {}

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) context.go('/staff/dashboard');
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.signalTeal),
                        child: Text('Confirm Resolution', style: AppTextStyles.clashDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  final bool isDone;
  final String? doneBy;
  final DateTime? doneAt;
  final VoidCallback onToggle;

  const _ChecklistItem({required this.text, required this.isDone, this.doneBy, this.doneAt, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border(left: BorderSide(color: isDone ? AppColors.signalTeal : AppColors.borderDark, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.signalTeal : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDone ? AppColors.signalTeal : AppColors.borderDark, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: AppTextStyles.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                    ).copyWith(decoration: isDone ? TextDecoration.lineThrough : null),
                  ),
                ),
              ],
            ),
            if (isDone && doneBy != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  'Done by $doneBy${doneAt != null ? ' at ${DateFormat('hh:mm a').format(doneAt!)}' : ''}',
                  style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EscalationBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EscalationBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 18),
        label: Text(label, style: AppTextStyles.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
