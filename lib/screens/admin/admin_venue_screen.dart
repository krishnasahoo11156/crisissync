import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/venue_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin venue configuration screen.
class AdminVenueScreen extends StatefulWidget {
  const AdminVenueScreen({super.key});

  @override
  State<AdminVenueScreen> createState() => _AdminVenueScreenState();
}

class _AdminVenueScreenState extends State<AdminVenueScreen> {
  VenueModel _venue = VenueModel.defaultVenue;
  bool _loading = true;
  final _fireController = TextEditingController();
  final _ambulanceController = TextEditingController();
  final _policeController = TextEditingController();
  final _receptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('venues').doc('hotel_main').get();
      if (doc.exists) {
        _venue = VenueModel.fromMap(doc.id, doc.data()!);
      } else {
        // Seed default venue
        await FirebaseFirestore.instance.collection('venues').doc('hotel_main').set(_venue.toMap());
      }
    } catch (_) {}
    _fireController.text = _venue.emergencyContacts['fire'] ?? '101';
    _ambulanceController.text = _venue.emergencyContacts['ambulance'] ?? '102';
    _policeController.text = _venue.emergencyContacts['police'] ?? '100';
    _receptionController.text = _venue.emergencyContacts['reception'] ?? '0';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveContacts() async {
    final contacts = {
      'fire': _fireController.text.trim(),
      'ambulance': _ambulanceController.text.trim(),
      'police': _policeController.text.trim(),
      'reception': _receptionController.text.trim(),
    };
    await FirebaseFirestore.instance.collection('venues').doc('hotel_main').update({
      'emergencyContacts': contacts,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts updated'), backgroundColor: AppColors.signalTeal),
      );
    }
  }

  @override
  void dispose() {
    _fireController.dispose();
    _ambulanceController.dispose();
    _policeController.dispose();
    _receptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void_,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.geminiPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Venue Configuration', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(_venue.name, style: AppTextStyles.dmSans(fontSize: 16, color: AppColors.textMuted)),
                  const SizedBox(height: 24),

                  // Floors
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderGhost),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Floor Plan', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ..._venue.floors.map((floor) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.void_,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.geminiPurple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(floor.floorId, style: AppTextStyles.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.geminiPurple)),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(floor.name, style: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                      const Spacer(),
                                      Text('${floor.rooms.length} rooms', style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: floor.rooms.map((room) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.borderGhost),
                                      ),
                                      child: Text(room, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Emergency contacts
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderGhost),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Contacts', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        _contactField('Fire Brigade', _fireController, Icons.local_fire_department, AppColors.fireColor),
                        _contactField('Ambulance', _ambulanceController, Icons.medical_services, AppColors.medicalColor),
                        _contactField('Police', _policeController, Icons.local_police, AppColors.securityColor),
                        _contactField('Reception', _receptionController, Icons.phone, AppColors.signalTeal),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveContacts,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.geminiPurple),
                          child: Text('Save Contacts', style: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _contactField(String label, TextEditingController controller, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary))),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.jetBrainsMono(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
          ),
        ],
      ),
    );
  }
}
