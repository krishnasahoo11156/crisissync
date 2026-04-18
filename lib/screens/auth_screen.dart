import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/config/router.dart';
import 'package:crisissync/providers/auth_provider.dart';

/// Auth screen with Google Sign-In and portal-aware switching.
///
/// If the user is already logged in:
///   - If their role matches the requested portal → redirect immediately
///   - If their role does NOT match → sign out first, then show sign-in
///
/// This ensures users can switch between Guest / Staff / Admin portals
/// by choosing a different portal on the landing page.
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
    // Schedule the portal-check after the first frame so that 
    // context.read<AuthProvider>() is available and the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleExistingSession();
    });
  }

  /// Handle the case where the user is already logged in.
  Future<void> _handleExistingSession() async {
    final auth = context.read<AuthProvider>();

    // Wait for auth to finish loading
    if (auth.isLoading) {
      // Listen for when loading completes
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

    // If no portal hint, just go to user's home
    if (requestedPortal.isEmpty) {
      if (mounted) _navigateToPortal(userRole);
      return;
    }

    // Check if the user's role matches the requested portal
    if (_roleMatchesPortal(userRole, requestedPortal)) {
      // Role matches → go directly
      if (mounted) _navigateToPortal(userRole);
    } else {
      // Role doesn't match → sign out silently and let them re-sign-in
      setState(() => _isSigningOut = true);
      await auth.signOut();
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  /// Check if user's role allows access to the requested portal.
  bool _roleMatchesPortal(String role, String portal) {
    // Admin can access everything
    if (role == 'admin') return true;
    // Otherwise must be exact match
    return role == portal;
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.signInWithGoogle();

      if (!mounted) return;

      if (auth.isLoggedIn) {
        final role = auth.userRole;

        // Check if guest needs room number
        if (role == 'guest' && (auth.user?.roomNumber == null || auth.user!.roomNumber!.isEmpty)) {
          _showRoomNumberDialog();
          return;
        }

        // Check role vs requested portal
        final requestedPortal = widget.portalHint;
        if (requestedPortal.isNotEmpty && !_roleMatchesPortal(role ?? 'guest', requestedPortal)) {
          // User signed in with wrong account for this portal
          setState(() {
            _error = _portalMismatchMessage(role ?? 'guest', requestedPortal);
          });
          // Sign them out so they can try with the correct account
          await auth.signOut();
        } else {
          _navigateToPortal(role);
        }
      } else if (auth.error != null) {
        setState(() => _error = _friendlyError(auth.error!));
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  String _portalMismatchMessage(String actualRole, String requestedPortal) {
    final portalNames = {'guest': 'Guest', 'staff': 'Staff', 'admin': 'Admin'};
    final actual = portalNames[actualRole] ?? actualRole;
    final requested = portalNames[requestedPortal] ?? requestedPortal;
    return 'Your account is registered as "$actual" but you selected the $requested Portal.\n\n'
        'Please sign in with a $requested account, or go back and select the $actual Portal.';
  }

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
    // Show raw error in dev so nothing is hidden
    return 'Sign-in failed: $raw';
  }

  void _navigateToPortal(String? role) {
    final home = AppRouter.homeForRole(role);
    context.go(home);
  }

  void _showRoomNumberDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(
          'Enter Your Room Number',
          style: AppTextStyles.clashDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your hotel room number to continue.',
              style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTextStyles.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. 306',
                prefixIcon: Icon(Icons.hotel, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final room = controller.text.trim();
              if (room.isEmpty) return;

              final auth = context.read<AuthProvider>();
              final nav = Navigator.of(ctx);
              await auth.updateRoomNumber(room);
              if (mounted) {
                nav.pop();
                _navigateToPortal(auth.userRole);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.signalTeal,
            ),
            child: Text(
              'Continue',
              style: AppTextStyles.clashDisplay(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    // Show loading while signing out to switch portals
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
          width: 420,
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
                widget.portalHint.isNotEmpty
                    ? 'Sign in with your $_portalDisplayName Google account'
                    : 'Use your Google account to continue',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
                            // Google "G" logo
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
