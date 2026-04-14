import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/providers/incident_provider.dart';
import 'package:crisissync/widgets/incident_card.dart';
import 'package:crisissync/widgets/crisis_type_icon.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

/// Staff map view — simplified venue map with incident markers.
class StaffMapScreen extends StatefulWidget {
  const StaffMapScreen({super.key});

  @override
  State<StaffMapScreen> createState() => _StaffMapScreenState();
}

class _StaffMapScreenState extends State<StaffMapScreen> {
  String _selectedFloor = 'All';
  final _floors = ['All', 'B1', 'Floor 1', 'Floor 2', 'Floor 3', 'Floor 4', 'Rooftop'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().startListening();
    });
  }

  String _floorFromRoom(String room) {
    if (room.startsWith('B')) return 'B1';
    if (room.startsWith('Pool') || room.startsWith('Restaurant') || room.startsWith('Bar')) return 'Rooftop';
    if (room.isNotEmpty) return 'Floor ${room[0]}';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final filtered = _selectedFloor == 'All'
        ? incidents.activeIncidents
        : incidents.activeIncidents.where((i) => _floorFromRoom(i.roomNumber) == _selectedFloor).toList();

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Column(
        children: [
          // Header + floor selector
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Map View', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _floors.map((f) {
                      final hasIncident = incidents.activeIncidents.any((i) => _floorFromRoom(i.roomNumber) == f);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFloor = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedFloor == f ? AppColors.crisisRed : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.badge),
                              border: Border.all(color: _selectedFloor == f ? AppColors.crisisRed : AppColors.borderDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(f, style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: _selectedFloor == f ? Colors.white : AppColors.textMuted)),
                                if (hasIncident && _selectedFloor != f) ...[
                                  const SizedBox(width: 6),
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.crisisRed, shape: BoxShape.circle)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Map area with incident markers
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, color: AppColors.textMuted.withValues(alpha: 0.3), size: 64),
                          const SizedBox(height: 16),
                          Text('No active incidents on this floor', style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: filtered.map((i) => _MapMarker(
                          incident: i,
                          onTap: () => context.go('/staff/incident/${i.id}'),
                        )).toList(),
                      ),
                    ),
            ),
          ),

          // Bottom incident list
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.void_,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Incidents', style: AppTextStyles.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: incidents.activeIncidents.length,
                    itemBuilder: (context, index) {
                      final i = incidents.activeIncidents[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: IncidentCard(incident: i, compact: true, onTap: () => context.go('/staff/incident/${i.id}')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final dynamic incident;
  final VoidCallback onTap;

  const _MapMarker({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForCrisisType(incident.crisisType);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: incident.severity >= 5
                  ? [BoxShadow(color: AppColors.crisisRed.withValues(alpha: 0.5), blurRadius: 12)]
                  : null,
            ),
            child: CrisisTypeIcon(type: incident.crisisType, size: 22),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Rm ${incident.roomNumber}',
              style: AppTextStyles.jetBrainsMono(fontSize: 10, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
