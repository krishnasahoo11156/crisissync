import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// Crisis type icon using Material icons with proper colors.
class CrisisTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const CrisisTypeIcon({super.key, required this.type, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconForType(type),
      color: AppColors.colorForCrisisType(type),
      size: size,
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
        return Icons.medical_services;
      case 'security':
        return Icons.shield;
      case 'flood':
        return Icons.water;
      case 'power':
        return Icons.power_off;
      default:
        return Icons.help_outline;
    }
  }
}
