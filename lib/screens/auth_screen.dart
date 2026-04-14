import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';

/// Auth screen with Google Sign-In.
class AuthScreen extends StatefulWidget {
  final String portalHint;

  const AuthScreen({super.key, this.portalHint = ''});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSigningIn = false;
  String? _error;

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

        _navigateToPortal(role);
      } else if (auth.error != null) {
        setState(() => _error = 'Sign-in failed. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _navigateToPortal(String? role) {
    switch (role) {
      case 'admin':
        context.go('/admin');
        break;
      case 'staff':
        context.go('/staff/dashboard');
        break;
      default:
        context.go('/guest');
    }
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
              await auth.updateRoomNumber(room);
              if (mounted) {
                Navigator.of(ctx).pop();
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

  @override
  Widget build(BuildContext context) {
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
                'Use your Google account to continue',
                style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
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
