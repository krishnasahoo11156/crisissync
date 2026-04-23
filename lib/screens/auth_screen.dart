import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/config/router.dart';
import 'package:crisissync/providers/auth_provider.dart';

/// Auth screen with Google Sign-In and portal-aware registration.
///
/// Flow:
/// 1. User picks a portal (guest / staff / admin) on the landing page.
/// 2. They are sent to /auth?portal=<portal>.
/// 3. They click "Continue with Google" — ANY Google account is accepted.
/// 4. If the user is brand new (or their stored role doesn't match the
///    requested portal), a registration dialog collects the extra info
///    needed for that portal and updates the Firestore profile.
/// 5. The user is then navigated to their portal home.
class AuthScreen extends StatefulWidget {
  final String portalHint;

  const AuthScreen({super.key, this.portalHint = ''});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSigningIn = false;
  bool _isSigningOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleExistingSession();
    });
  }

  /// If already logged in and the stored role matches the requested portal,
  /// navigate immediately. If the role doesn't match (user is switching
  /// portals), sign them out so they can sign in fresh.
  Future<void> _handleExistingSession() async {
    final auth = context.read<AuthProvider>();

    if (auth.isLoading) {
      void listener() {
        if (!auth.isLoading) {
          auth.removeListener(listener);
          if (mounted) _handleExistingSession();
        }
      }
      auth.addListener(listener);
      return;
    }

    if (!auth.isLoggedIn) return;

    final userRole = auth.userRole ?? 'guest';
    final requestedPortal = widget.portalHint;

    if (requestedPortal.isEmpty) {
      if (mounted) _navigateToPortal(userRole);
      return;
    }

    // If the stored role already matches (or admin can go anywhere), proceed.
    if (_roleMatchesPortal(userRole, requestedPortal)) {
      if (mounted) _navigateToPortal(userRole);
    } else {
      // Switching portals — sign out and show the sign-in UI.
      setState(() => _isSigningOut = true);
      await auth.signOut();
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  bool _roleMatchesPortal(String role, String portal) {
    if (role == 'admin') return true;
    return role == portal;
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final requestedPortal = widget.portalHint.isNotEmpty ? widget.portalHint : 'guest';

      // Sign in — any Google account is accepted.
      // Pass the requested portal as the role for brand-new users.
      await auth.signInWithGoogle(portalRole: requestedPortal);

      if (!mounted) return;

      if (auth.isLoggedIn) {
        final storedRole = auth.userRole ?? 'guest';

        // ── Case 1: Returning user whose role already matches ──────────────
        if (_roleMatchesPortal(storedRole, requestedPortal)) {
          // Guest may still lack a room number — check.
          if (storedRole == 'guest' &&
              (auth.user?.roomNumber == null || auth.user!.roomNumber!.isEmpty)) {
            _showGuestRegistrationDialog(isNameMissing: _isNameMissing(auth));
          } else {
            _navigateToPortal(storedRole);
          }
          return;
        }

        // ── Case 2: User is switching portals (role mismatch) ──────────────
        // Update their role to match the new portal and collect info.
        await auth.updateRole(requestedPortal);
        if (!mounted) return;
        _showRegistrationDialogForPortal(requestedPortal, isNameMissing: _isNameMissing(auth));
      } else if (auth.error != null) {
        setState(() => _error = _friendlyError(auth.error!));
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  bool _isNameMissing(AuthProvider auth) {
    final name = auth.user?.name ?? '';
    return name.isEmpty;
  }

  void _showRegistrationDialogForPortal(String portal, {bool isNameMissing = false}) {
    switch (portal) {
      case 'guest':
        _showGuestRegistrationDialog(isNameMissing: isNameMissing);
        break;
      case 'staff':
        _showStaffRegistrationDialog(isNameMissing: isNameMissing);
        break;
      case 'admin':
        if (isNameMissing) {
          _showAdminRegistrationDialog();
        } else {
          _navigateToPortal('admin');
        }
        break;
      default:
        _navigateToPortal(portal);
    }
  }

  // ─── Guest Registration Dialog ───────────────────────────────────────────

  void _showGuestRegistrationDialog({bool isNameMissing = false}) {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(
      text: isNameMissing ? '' : (auth.user?.name ?? ''),
    );
    final roomController = TextEditingController(
      text: auth.user?.roomNumber ?? '',
    );
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text(
            'Guest Registration',
            style: AppTextStyles.clashDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please complete your profile to access the Guest Portal.',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              // Name field
              Text(
                'Your Name',
                style: AppTextStyles.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: isNameMissing,
                style: AppTextStyles.dmSans(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. John Smith',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              // Room number field
              Text(
                'Room Number',
                style: AppTextStyles.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: roomController,
                autofocus: !isNameMissing,
                style: AppTextStyles.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 306',
                  prefixIcon: Icon(Icons.hotel, color: AppColors.textMuted),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  dialogError!,
                  style: AppTextStyles.dmSans(
                    fontSize: 13,
                    color: AppColors.crisisRed,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final room = roomController.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter your name.');
                  return;
                }
                if (room.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter your room number.');
                  return;
                }

                final authProv = context.read<AuthProvider>();
                final nav = Navigator.of(ctx);
                await authProv.updateName(name);
                await authProv.updateRoomNumber(room);
                if (mounted) {
                  nav.pop();
                  _navigateToPortal('guest');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.signalTeal,
              ),
              child: Text(
                'Enter Guest Portal',
                style: AppTextStyles.clashDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Staff Registration Dialog ───────────────────────────────────────────

  void _showStaffRegistrationDialog({bool isNameMissing = false}) {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(
      text: isNameMissing ? '' : (auth.user?.name ?? ''),
    );
    String selectedStaffRole = auth.user?.staffRole ?? 'Security';
    String? dialogError;

    const staffRoles = ['Security', 'Medical', 'Front Desk', 'Manager'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text(
            'Staff Registration',
            style: AppTextStyles.clashDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please complete your profile to access the Staff Portal.',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              // Name field
              Text(
                'Your Name',
                style: AppTextStyles.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTextStyles.dmSans(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Jane Doe',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              // Staff role selector
              Text(
                'Staff Role',
                style: AppTextStyles.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: staffRoles.map((role) {
                  final isSelected = selectedStaffRole == role;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedStaffRole = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.crisisRed.withValues(alpha: 0.15)
                            : AppColors.void_.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.crisisRed
                              : AppColors.borderDark,
                        ),
                      ),
                      child: Text(
                        role,
                        style: AppTextStyles.dmSans(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.crisisRed : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  dialogError!,
                  style: AppTextStyles.dmSans(
                    fontSize: 13,
                    color: AppColors.crisisRed,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter your name.');
                  return;
                }

                final authProv = context.read<AuthProvider>();
                final nav = Navigator.of(ctx);
                await authProv.updateName(name);
                await authProv.updateRole('staff', staffRole: selectedStaffRole);
                if (mounted) {
                  nav.pop();
                  _navigateToPortal('staff');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crisisRed,
              ),
              child: Text(
                'Enter Staff Portal',
                style: AppTextStyles.clashDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Admin Registration Dialog ───────────────────────────────────────────

  void _showAdminRegistrationDialog() {
    final auth = context.read<AuthProvider>();
    final nameController = TextEditingController(text: auth.user?.name ?? '');
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal),
          ),
          title: Text(
            'Admin Registration',
            style: AppTextStyles.clashDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm your name to access the Admin Portal.',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Name',
                style: AppTextStyles.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTextStyles.dmSans(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. Admin Name',
                  prefixIcon: Icon(Icons.shield_outlined, color: AppColors.textMuted),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  dialogError!,
                  style: AppTextStyles.dmSans(
                    fontSize: 13,
                    color: AppColors.crisisRed,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter your name.');
                  return;
                }

                final authProv = context.read<AuthProvider>();
                final nav = Navigator.of(ctx);
                await authProv.updateName(name);
                await authProv.updateRole('admin');
                if (mounted) {
                  nav.pop();
                  _navigateToPortal('admin');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.geminiPurple,
              ),
              child: Text(
                'Enter Admin Portal',
                style: AppTextStyles.clashDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _friendlyError(String raw) {
    if (raw.contains('popup-closed') || raw.contains('popup_closed')) {
      return 'Sign-in popup was closed. Please try again.';
    }
    if (raw.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Google Sign-In is not enabled in Firebase Console.\nPlease enable it under Authentication → Sign-in method → Google.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Check your internet connection.';
    }
    if (raw.contains('unauthorized-domain')) {
      return 'This domain is not authorised. Add it under Firebase → Authentication → Settings → Authorised domains.';
    }
    return 'Sign-in failed: $raw';
  }

  void _navigateToPortal(String? role) {
    final home = AppRouter.homeForRole(role);
    context.go(home);
  }

  String get _portalDisplayName {
    switch (widget.portalHint) {
      case 'guest':
        return 'Guest Portal';
      case 'staff':
        return 'Staff Portal';
      case 'admin':
        return 'Admin Portal';
      default:
        return 'CrisisSync';
    }
  }

  Color get _portalAccentColor {
    switch (widget.portalHint) {
      case 'guest':
        return AppColors.signalTeal;
      case 'staff':
        return AppColors.crisisRed;
      case 'admin':
        return AppColors.geminiPurple;
      default:
        return AppColors.signalTeal;
    }
  }

  String get _portalSubtitle {
    switch (widget.portalHint) {
      case 'guest':
        return 'Sign in with any Google account to report and track incidents.';
      case 'staff':
        return 'Sign in with any Google account to manage incidents and responses.';
      case 'admin':
        return 'Sign in with any Google account to access system administration.';
      default:
        return 'Use your Google account to continue.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSigningOut) {
      return Scaffold(
        backgroundColor: AppColors.void_,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.signalTeal),
              const SizedBox(height: 16),
              Text(
                'Switching portal…',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.modal),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Portal badge
              if (widget.portalHint.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _portalAccentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    _portalDisplayName,
                    style: AppTextStyles.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _portalAccentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Sign in to CrisisSync',
                style: AppTextStyles.clashDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _portalSubtitle,
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // "Any Google account" pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _portalAccentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _portalAccentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 13, color: _portalAccentColor),
                    const SizedBox(width: 5),
                    Text(
                      'Any Google account accepted',
                      style: AppTextStyles.dmSans(
                        fontSize: 11,
                        color: _portalAccentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: _isSigningIn
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: AppTextStyles.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.crisisRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.dmSans(
                      fontSize: 13,
                      color: AppColors.crisisRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  '← Back to home',
                  style: AppTextStyles.dmSans(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
