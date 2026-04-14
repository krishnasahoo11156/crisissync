import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/fcm_service.dart';
import 'package:intl/intl.dart';

/// Guest non-emergency concern form.
class GuestConcernScreen extends StatefulWidget {
  const GuestConcernScreen({super.key});

  @override
  State<GuestConcernScreen> createState() => _GuestConcernScreenState();
}

class _GuestConcernScreenState extends State<GuestConcernScreen> {
  String _category = 'Noise';
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  final _categories = ['Noise', 'Maintenance', 'Safety', 'Other'];

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.user!;

    try {
      final incidentId = await IncidentService.createIncident(
        guestUid: user.uid,
        guestName: user.name,
        guestEmail: user.email,
        roomNumber: user.roomNumber ?? 'N/A',
        crisisType: _category.toLowerCase(),
        severity: 1,
        description: _descController.text.trim(),
      );

      // Only notify Front Desk
      await FcmService.createNotification(
        uid: '', // Will be resolved to Front Desk staff
        message: '📋 Non-emergency: ${_category} concern from Room ${user.roomNumber}',
        incidentId: incidentId,
        type: 'concern',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Concern submitted successfully'),
            backgroundColor: AppColors.signalTeal,
          ),
        );
        context.go('/guest');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.crisisRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guestTheme,
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(
          backgroundColor: AppColors.guestCard,
          leading: IconButton(
            onPressed: () => context.go('/guest'),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          title: Text(
            'Report a Concern',
            style: AppTextStyles.clashDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Non-Emergency Report',
                style: AppTextStyles.clashDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For non-urgent issues, please describe your concern below.',
                style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              // Category dropdown
              Text(
                'Category',
                style: AppTextStyles.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'Description',
                style: AppTextStyles.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 5,
                style: AppTextStyles.dmSans(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Describe your concern...',
                  filled: true,
                  fillColor: Colors.white,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signalTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Submit Concern',
                          style: AppTextStyles.clashDisplay(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
}
