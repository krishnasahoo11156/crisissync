import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/widgets/gemini_tag.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Guest resolved screen with animated checkmark and AI report.
class GuestResolvedScreen extends StatefulWidget {
  final String incidentId;
  const GuestResolvedScreen({super.key, required this.incidentId});

  @override
  State<GuestResolvedScreen> createState() => _GuestResolvedScreenState();
}

class _GuestResolvedScreenState extends State<GuestResolvedScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  int _rating = 0;
  bool _ratingSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0, 0.57, curve: Curves.easeOut),
      ),
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.57, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _submitRating(int rating) async {
    setState(() {
      _rating = rating;
      _ratingSubmitted = true;
    });
    await IncidentService.rateIncident(widget.incidentId, rating);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: StreamBuilder<IncidentModel?>(
        stream: IncidentService.streamIncident(widget.incidentId),
        builder: (context, snapshot) {
          final incident = snapshot.data;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Animated checkmark
                  AnimatedBuilder(
                    animation: _checkController,
                    builder: (context, _) => SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _CheckmarkPainter(
                          circleProgress: _circleAnimation.value,
                          checkProgress: _checkAnimation.value,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Incident Resolved',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (incident?.resolvedAt != null)
                    Text(
                      DateFormat('MMM dd, yyyy – hh:mm a').format(incident!.resolvedAt!),
                      style: AppTextStyles.jetBrainsMono(fontSize: 13, color: AppColors.textMuted),
                    ),
                  if (incident?.resolvedBy != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Resolved by: ${incident!.resolvedBy!['staffName']} — ${incident.resolvedBy!['staffRole']}',
                      style: AppTextStyles.dmSans(fontSize: 16, color: AppColors.textPrimary),
                    ),
                    if (incident.resolvedBy!['notes'] != null &&
                        (incident.resolvedBy!['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Text(
                          '"${incident.resolvedBy!['notes']}"',
                          style: AppTextStyles.dmSans(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // AI Report
                  if (incident?.postIncidentReport != null) ...[
                    Container(
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
                                'AI Incident Report',
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
                          Text(
                            incident!.postIncidentReport!,
                            style: AppTextStyles.dmSans(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Rating
                  if (!_ratingSubmitted) ...[
                    Text(
                      'Rate your experience',
                      style: AppTextStyles.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        return IconButton(
                          onPressed: () => _submitRating(star),
                          icon: Icon(
                            star <= _rating ? Icons.star : Icons.star_border,
                            color: AppColors.amberAlert,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.signalTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.signalTeal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Thank you for your feedback!',
                            style: AppTextStyles.dmSans(
                              fontSize: 14,
                              color: AppColors.signalTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  OutlinedButton(
                    onPressed: () => context.go('/guest'),
                    child: Text(
                      'Back to Home',
                      style: AppTextStyles.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;

  _CheckmarkPainter({required this.circleProgress, required this.checkProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Circle
    final circlePaint = Paint()
      ..color = AppColors.signalTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    // Checkmark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = AppColors.signalTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final startX = size.width * 0.28;
      final startY = size.height * 0.52;
      final midX = size.width * 0.44;
      final midY = size.height * 0.66;
      final endX = size.width * 0.72;
      final endY = size.height * 0.38;

      if (checkProgress <= 0.5) {
        final t = checkProgress / 0.5;
        path.moveTo(startX, startY);
        path.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        final t = (checkProgress - 0.5) / 0.5;
        path.moveTo(startX, startY);
        path.lineTo(midX, midY);
        path.lineTo(
          midX + (endX - midX) * t,
          midY + (endY - midY) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.circleProgress != circleProgress || oldDelegate.checkProgress != checkProgress;
}
