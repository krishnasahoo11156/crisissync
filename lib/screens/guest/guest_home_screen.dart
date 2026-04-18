import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/fcm_service.dart';
import 'package:crisissync/services/email_service.dart';
import 'package:crisissync/widgets/notification_bell.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

/// Guest home screen with SOS button, quick type, and voice input.
class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _holdController;
  late Animation<double> _holdAnimation;
  bool _isHolding = false;
  bool _isSubmitting = false;
  String _description = '';
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController1 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController2 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _pulseController2.repeat(reverse: true);
    });

    _holdController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _holdAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _holdController, curve: Curves.linear),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSOS();
      }
    });
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _holdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() => _isHolding = true);
    _holdController.forward(from: 0);
  }

  void _onHoldEnd() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reset();
    }
    setState(() => _isHolding = false);
  }

  Future<void> _triggerSOS({String crisisType = 'other'}) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _isHolding = false;
    });

    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    try {
      final incidentId = await IncidentService.createIncident(
        guestUid: user.uid,
        guestName: user.name,
        guestEmail: user.email,
        roomNumber: user.roomNumber ?? 'N/A',
        crisisType: crisisType,
        description: _description,
      );

      // Notify staff
      await FcmService.notifyOnDutyStaff(
        incidentId: incidentId,
        crisisType: crisisType,
        severity: 3,
        roomNumber: user.roomNumber ?? 'N/A',
      );

      // Send email
      try {
        await EmailService.sendIncidentCreated(
          guestEmail: user.email,
          guestName: user.name,
          incidentId: incidentId,
          crisisType: crisisType,
          roomNumber: user.roomNumber ?? 'N/A',
          timestamp: DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now()),
        );
      } catch (_) {}

      if (mounted) context.go('/guest/status/$incidentId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.crisisRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitWithType(String type) async {
    await _triggerSOS(crisisType: type);
  }

  Future<void> _submitText() async {
    if (_descController.text.trim().isEmpty) return;
    _description = _descController.text.trim();
    await _triggerSOS(crisisType: 'other');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox();

    return Theme(
      data: AppTheme.guestTheme,
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Top bar
                _buildTopBar(user.name, user.roomNumber ?? '', user.uid),
                const SizedBox(height: 40),
                // SOS Button
                _buildSOSButton(),
                const SizedBox(height: 32),
                // Quick type buttons
                _buildQuickTypeButtons(),
                const SizedBox(height: 32),
                // Text input
                _buildTextInput(),
                const SizedBox(height: 24),
                // Concern form link
                TextButton(
                  onPressed: () => context.go('/guest/concern'),
                  child: Text(
                    'Report a non-emergency concern →',
                    style: AppTextStyles.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/guest/history'),
                  child: Text(
                    'View past incidents →',
                    style: AppTextStyles.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign out
                TextButton(
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    await auth.signOut();
                    if (mounted) router.go('/');
                  },
                  child: Text(
                    'Sign Out',
                    style: AppTextStyles.dmSans(fontSize: 13, color: Colors.black38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String name, String room, String uid) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grand Meridian Hotel',
                style: AppTextStyles.clashDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome, $name',
                style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        if (room.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.badge),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              'Room $room',
              style: AppTextStyles.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        const SizedBox(width: 8),
        NotificationBell(uid: uid),
      ],
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPressStart: (_) => _onHoldStart(),
      onLongPressEnd: (_) => _onHoldEnd(),
      onLongPressCancel: _onHoldEnd,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            AnimatedBuilder(
              animation: _pulseController1,
              builder: (context, _) => Transform.scale(
                scale: 1.0 + (_pulseController1.value * 0.08),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.crisisRed.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Mid ring
            AnimatedBuilder(
              animation: _pulseController2,
              builder: (context, _) => Transform.scale(
                scale: 1.0 + (_pulseController2.value * 0.08),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.crisisRed.withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Main button
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.crisisRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : Text(
                        'SOS',
                        style: AppTextStyles.clashDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.08 * 32,
                        ),
                      ),
              ),
            ),
            // Hold progress arc
            if (_isHolding)
              AnimatedBuilder(
                animation: _holdAnimation,
                builder: (context, _) => SizedBox(
                  width: 148,
                  height: 148,
                  child: CustomPaint(
                    painter: _ArcPainter(progress: _holdAnimation.value),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTypeButtons() {
    return Row(
      children: [
        _QuickTypeBtn(
          label: 'Fire',
          icon: Icons.local_fire_department,
          color: const Color(0xFFFF8C00),
          onTap: () => _submitWithType('fire'),
        ),
        const SizedBox(width: 12),
        _QuickTypeBtn(
          label: 'Medical',
          icon: Icons.medical_services,
          color: const Color(0xFF3B82F6),
          onTap: () => _submitWithType('medical'),
        ),
        const SizedBox(width: 12),
        _QuickTypeBtn(
          label: 'Security',
          icon: Icons.shield,
          color: const Color(0xFF6B7280),
          onTap: () => _submitWithType('security'),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe your emergency',
            style: AppTextStyles.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Type details here...',
              filled: true,
              fillColor: const Color(0xFFF5F5F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crisisRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Submit Emergency Report',
                style: AppTextStyles.clashDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickTypeBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
