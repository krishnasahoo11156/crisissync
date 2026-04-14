import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'dart:async';

/// Incident card widget used in staff and admin dashboards.
class IncidentCard extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final bool compact;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.onAccept,
    this.compact = false,
  });

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard> {
  Timer? _timer;
  String _elapsed = '';

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() {
        _elapsed = widget.incident.elapsedFormatted;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.incident;
    final borderColor = AppColors.colorForCrisisType(i.crisisType);
    final isSev5 = i.severity == 5;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderDark),
            boxShadow: isSev5
                ? [
                    BoxShadow(
                      color: AppColors.crisisRed.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.card),
                      bottomLeft: Radius.circular(AppRadius.card),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(widget.compact ? 12 : 16),
                    child: widget.compact ? _buildCompact(i) : _buildFull(i),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFull(IncidentModel i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Room ${i.roomNumber}',
              style: AppTextStyles.clashDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            CrisisTypeIcon(type: i.crisisType, size: 20),
            const SizedBox(width: 6),
            Text(
              i.crisisType.toUpperCase(),
              style: AppTextStyles.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.colorForCrisisType(i.crisisType),
              ),
            ),
            const Spacer(),
            SeverityBadge(level: i.severity),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _elapsed,
              style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(width: 16),
            StatusIndicator(status: i.status),
          ],
        ),
        if (i.geminiClassification != null) ...[
          const SizedBox(height: 8),
          Text(
            i.geminiClassification!.situationBrief,
            style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (i.geminiClassification == null) ...[
          const SizedBox(height: 8),
          _ShimmerLine(),
        ],
        if (widget.onAccept != null && i.status == 'active') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crisisRed,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Accept Incident',
                style: AppTextStyles.clashDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        if (i.status == 'accepted' && i.acceptedBy != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.signalTeal, size: 16),
              const SizedBox(width: 6),
              Text(
                'Responding: ${i.acceptedBy!['staffName']} (${i.acceptedBy!['staffRole']})',
                style: AppTextStyles.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.signalTeal,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompact(IncidentModel i) {
    return Row(
      children: [
        CrisisTypeIcon(type: i.crisisType, size: 18),
        const SizedBox(width: 8),
        Text(
          'Rm ${i.roomNumber}',
          style: AppTextStyles.clashDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        SeverityBadge(level: i.severity),
        const Spacer(),
        Text(
          _elapsed,
          style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat();
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
        height: 14,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + (2.0 * _c.value), 0),
            end: Alignment(-1.0 + (2.0 * _c.value) + 1.0, 0),
            colors: const [AppColors.surface, Color(0xFF2A2A2A), AppColors.surface],
          ),
        ),
      ),
    );
  }
}
