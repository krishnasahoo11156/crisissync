import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/incident_model.dart';
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
      // Step 1: Create the incident (must succeed before anything else).
      final incidentId = await IncidentService.createIncident(
        guestUid: user.uid,
        guestName: user.name,
        guestEmail: user.email,
        roomNumber: user.roomNumber ?? 'N/A',
        crisisType: crisisType,
        description: _description,
      );

      // Step 2: Fire-and-forget side effects — don't block or fail the main flow.
      FcmService.notifyOnDutyStaff(
        incidentId: incidentId,
        crisisType: crisisType,
        severity: 3,
        roomNumber: user.roomNumber ?? 'N/A',
      ).catchError((_) {});

      EmailService.sendIncidentCreated(
        guestEmail: user.email,
        guestName: user.name,
        incidentId: incidentId,
        crisisType: crisisType,
        roomNumber: user.roomNumber ?? 'N/A',
        timestamp: DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now()),
      ).catchError((_) {});

      // Step 3: Clear the loading state and show confirmation dialog.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _descController.clear();
      _description = '';

      // Step 4: Show success dialog, then navigate to live status screen.
      await _showIncidentCreatedDialog(incidentId, crisisType, user.roomNumber ?? 'N/A');
      if (mounted) context.go('/guest/status/$incidentId');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.crisisRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Ensure spinner is always cleared even on unexpected error.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Shows a confirmation dialog after the incident is created.
  /// Gives the user a clear signal that their report was received
  /// and offers a direct link to the live status screen.
  Future<void> _showIncidentCreatedDialog(
    String incidentId,
    String crisisType,
    String roomNumber,
  ) async {
    final typeLabel = crisisType[0].toUpperCase() + crisisType.substring(1);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated check icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.signalTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.signalTeal, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                'Emergency Reported!',
                style: AppTextStyles.clashDisplay(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your $typeLabel alert for Room $roomNumber has been sent to staff.',
                style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Incident ID chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      incidentId.length > 12 ? incidentId.substring(0, 12).toUpperCase() : incidentId.toUpperCase(),
                      style: AppTextStyles.jetBrainsMono(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Primary CTA: go to live status
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.radar, size: 18),
                  label: const Text('Track Live Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crisisRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Secondary: stay on home
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Override the post-dialog navigation by pushing a no-op
                  // We go back to guest home instead of status screen
                  if (mounted) context.go('/guest');
                },
                child: Text(
                  'Stay on Home',
                  style: AppTextStyles.dmSans(fontSize: 13, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

                // Live incidents section — shows active/recent reports in real time
                _buildMyIncidentsSection(user.uid),

                const SizedBox(height: 8),
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
                    'View all past incidents →',
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

  /// Live incidents section — streams the guest's own incidents from Firestore
  /// so the home screen always shows their current active reports in real time.
  Widget _buildMyIncidentsSection(String uid) {
    return StreamBuilder<List<IncidentModel>>(
      stream: IncidentService.streamGuestIncidents(uid),
      builder: (context, snapshot) {
        final allIncidents = snapshot.data ?? [];
        // Show only non-resolved incidents on the home screen.
        final activeIncidents = allIncidents
            .where((i) => i.status != 'resolved')
            .toList();

        if (activeIncidents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.crisisRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'YOUR ACTIVE REPORTS',
                  style: AppTextStyles.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.black45, letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/guest/history'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    'See all',
                    style: AppTextStyles.dmSans(fontSize: 12, color: AppColors.crisisRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // One card per active incident
            ...activeIncidents.map((incident) => _buildActiveIncidentCard(incident)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// A compact card for one active incident shown on the home screen.
  Widget _buildActiveIncidentCard(IncidentModel incident) {
    final statusColor = AppColors.colorForStatus(incident.status);
    final isUrgent = incident.severity >= 4;

    return GestureDetector(
      onTap: () => context.go('/guest/status/${incident.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isUrgent
                ? AppColors.crisisRed.withValues(alpha: 0.4)
                : Colors.black12,
          ),
          boxShadow: isUrgent
              ? [BoxShadow(color: AppColors.crisisRed.withValues(alpha: 0.08), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${incident.crisisType.toUpperCase()} — Room ${incident.roomNumber}',
                    style: AppTextStyles.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(incident.status),
                    style: AppTextStyles.dmSans(fontSize: 12, color: statusColor),
                  ),
                ],
              ),
            ),
            // Track button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.crisisRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track',
                    style: AppTextStyles.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.crisisRed,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.crisisRed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Notifying staff…';
      case 'accepted': return 'Staff accepted — help is on the way';
      case 'responding': return 'Staff responding';
      case 'escalated': return 'Escalated to senior staff';
      default: return status;
    }
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
        // Room chip — tappable to open edit profile sheet.
        // Wrapped in Flexible so it shrinks/truncates instead of overflowing.
        Flexible(
          child: Tooltip(
            message: 'Tap to edit profile',
            child: GestureDetector(
              onTap: _showEditProfileSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        room.isNotEmpty ? 'Room $room' : 'Set Room',
                        style: AppTextStyles.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 11, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        NotificationBell(uid: uid),
      ],
    );
  }

  /// Edit profile bottom sheet — lets the guest update name and room number.
  /// Uses AuthProvider.updateName / updateRoomNumber which call notifyListeners(),
  /// so all context.watch<AuthProvider>() widgets rebuild instantly.
  void _showEditProfileSheet() {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(text: auth.user?.name ?? '');
    final roomController = TextEditingController(text: auth.user?.roomNumber ?? '');
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: AppTextStyles.clashDisplay(
                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changes are saved instantly across all screens.',
                style: AppTextStyles.dmSans(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              // Name field
              Text(
                'DISPLAY NAME',
                style: AppTextStyles.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.black45, letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTextStyles.dmSans(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.black38),
                  fillColor: const Color(0xFFF5F5F0),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: AppColors.crisisRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Room field
              Text(
                'ROOM NUMBER',
                style: AppTextStyles.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.black45, letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: roomController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.jetBrainsMono(
                  fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 306',
                  prefixIcon: const Icon(Icons.hotel, color: Colors.black38),
                  fillColor: const Color(0xFFF5F5F0),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: AppColors.crisisRed),
                  ),
                ),
              ),
              if (sheetError != null) ...[  
                const SizedBox(height: 8),
                Text(
                  sheetError!,
                  style: AppTextStyles.dmSans(fontSize: 13, color: AppColors.crisisRed),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final room = roomController.text.trim();
                    if (name.isEmpty) {
                      setSheetState(() => sheetError = 'Name cannot be empty.');
                      return;
                    }
                    if (room.isEmpty) {
                      setSheetState(() => sheetError = 'Room number cannot be empty.');
                      return;
                    }
                    // Update via AuthProvider — notifyListeners() propagates to all watchers.
                    // Read provider before async gap to avoid use_build_context_synchronously lint.
                    final authProv = context.read<AuthProvider>();
                    final currentName = authProv.user?.name ?? '';
                    final currentRoom = authProv.user?.roomNumber ?? '';
                    if (name != currentName) await authProv.updateName(name);
                    if (room != currentRoom) await authProv.updateRoomNumber(room);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crisisRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppTextStyles.clashDisplay(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onLongPressStart: (_) => _onHoldStart(),
      onLongPressEnd: (_) => _onHoldEnd(),
      onLongPressCancel: _onHoldEnd,
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring with glow
            AnimatedBuilder(
              animation: _pulseController1,
              builder: (context, _) => Transform.scale(
                scale: 1.0 + (_pulseController1.value * 0.1),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.crisisRed.withValues(alpha: 0.12 + _pulseController1.value * 0.08),
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
                scale: 1.0 + (_pulseController2.value * 0.1),
                child: Container(
                  width: 195,
                  height: 195,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.crisisRed.withValues(alpha: 0.2 + _pulseController2.value * 0.1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Main button with gradient
            AnimatedBuilder(
              animation: _pulseController1,
              builder: (context, _) => Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.crisisRed, AppColors.crisisRedDim],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crisisRed.withValues(alpha: 0.25 + _pulseController1.value * 0.15),
                      blurRadius: 32 + _pulseController1.value * 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SOS',
                              style: AppTextStyles.clashDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HOLD 2s',
                              style: AppTextStyles.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // Hold progress arc
            if (_isHolding)
              AnimatedBuilder(
                animation: _holdAnimation,
                builder: (context, _) => SizedBox(
                  width: 158,
                  height: 158,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFE8E8EC)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.crisisRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit_note, color: AppColors.crisisRed, size: 18)),
            const SizedBox(width: 10),
            Text('Describe your emergency', style: AppTextStyles.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Type details here...',
              filled: true,
              fillColor: const Color(0xFFF8F8F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button), borderSide: const BorderSide(color: Color(0xFFE8E8EC))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button), borderSide: const BorderSide(color: Color(0xFFE8E8EC))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.button), borderSide: const BorderSide(color: AppColors.crisisRed, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crisisRed,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                elevation: 0,
              ),
              child: Text('Submit Emergency Report', style: AppTextStyles.clashDisplay(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTypeBtn extends StatefulWidget {
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
  State<_QuickTypeBtn> createState() => _QuickTypeBtnState();
}

class _QuickTypeBtnState extends State<_QuickTypeBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            height: 52,
            decoration: BoxDecoration(
              color: _hovered ? widget.color.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: _hovered ? widget.color.withValues(alpha: 0.3) : Colors.black12),
              boxShadow: _hovered ? [BoxShadow(color: widget.color.withValues(alpha: 0.08), blurRadius: 12)] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 8),
                Text(widget.label, style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
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
