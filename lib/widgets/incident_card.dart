import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/widgets/severity_badge.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:crisissync/widgets/status_indicator.dart';
import 'dart:async';

/// Incident card — Aegis Protocol design with ambient glow,
/// gradient accent bars, and hover elevation.
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
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    if (mounted) setState(() => _elapsed = widget.incident.elapsedFormatted);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final i = widget.incident;
    final accentColor = AppColors.colorForCrisisType(i.crisisType);
    final isSev5 = i.severity == 5;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
          margin: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -2.0 : 0.0),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.elevated : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: _hovered ? accentColor.withValues(alpha: 0.3) : AppColors.borderGhost,
            ),
            boxShadow: [
              if (isSev5)
                BoxShadow(
                  color: AppColors.crisisRed.withValues(alpha: _hovered ? 0.25 : 0.15),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              if (_hovered && !isSev5)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Gradient accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor, accentColor.withValues(alpha: 0.3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.card),
                      bottomLeft: Radius.circular(AppRadius.card),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(widget.compact ? 12 : 18),
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
            Text('Room ${i.roomNumber}', style: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(width: 12),
            CrisisTypeIcon(type: i.crisisType, size: 20),
            const SizedBox(width: 6),
            Text(i.crisisType.toUpperCase(), style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.colorForCrisisType(i.crisisType))),
            const Spacer(),
            SeverityBadge(level: i.severity),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(_elapsed, style: AppTextStyles.jetBrainsMono(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 16),
            StatusIndicator(status: i.status),
          ],
        ),
        if (i.geminiClassification != null) ...[
          const SizedBox(height: 10),
          Text(i.geminiClassification!.situationBrief, style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (i.geminiClassification == null) ...[
          const SizedBox(height: 10),
          _ShimmerLine(),
        ],
        if (widget.onAccept != null && i.status == 'active') ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _AcceptButton(onPressed: widget.onAccept!),
          ),
        ],
        if (i.status == 'accepted' && i.acceptedBy != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.signalTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.signalTeal, size: 12),
              ),
              const SizedBox(width: 8),
              Text('Responding: ${i.acceptedBy!['staffName']} (${i.acceptedBy!['staffRole']})', style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.signalTeal)),
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
        Flexible(child: Text('Rm ${i.roomNumber}', style: AppTextStyles.clashDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        SeverityBadge(level: i.severity),
        const Spacer(),
        Text(_elapsed, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Accept button with gradient and hover glow
class _AcceptButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AcceptButton({required this.onPressed});
  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.crisisRed, _hovered ? AppColors.crisisRedDim : AppColors.crisisRed],
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: [BoxShadow(color: AppColors.crisisRed.withValues(alpha: _hovered ? 0.3 : 0.1), blurRadius: _hovered ? 16 : 8)],
          ),
          child: Center(child: Text('Accept Incident', style: AppTextStyles.clashDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this)..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: 14, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + (2.0 * _c.value), 0),
            end: Alignment(-1.0 + (2.0 * _c.value) + 1.0, 0),
            colors: const [AppColors.surfaceContainer, AppColors.surfaceBright, AppColors.surfaceContainer],
          ),
        ),
      ),
    );
  }
}
