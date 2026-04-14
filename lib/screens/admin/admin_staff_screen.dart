import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisissync/config/theme.dart';
import 'package:crisissync/models/user_model.dart';
import 'package:crisissync/providers/staff_provider.dart';

/// Admin staff management screen.
class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffProvider>();

    return Scaffold(
      backgroundColor: AppColors.void_,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Staff Management', style: AppTextStyles.clashDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.signalTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text('${staff.onDutyStaff.length} On Duty', style: AppTextStyles.jetBrainsMono(fontSize: 12, color: AppColors.signalTeal)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  topRight: Radius.circular(AppRadius.card),
                ),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(flex: 2, child: Text('Name', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                  Expanded(flex: 3, child: Text('Email', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                  Expanded(flex: 1, child: Text('Role', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                  Expanded(flex: 1, child: Text('Status', style: AppTextStyles.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                  const SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
                ],
              ),
            ),

            // Staff rows
            Expanded(
              child: staff.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.geminiPurple))
                  : staff.staffList.isEmpty
                      ? Center(child: Text('No staff configured', style: AppTextStyles.dmSans(color: AppColors.textMuted)))
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderDark),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(AppRadius.card),
                              bottomRight: Radius.circular(AppRadius.card),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: staff.staffList.length,
                            itemBuilder: (context, index) {
                              final s = staff.staffList[index];
                              final isEven = index % 2 == 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                color: isEven ? AppColors.surface : const Color(0xFF151515),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.crisisRed,
                                      child: Text(
                                        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Name
                                    Expanded(
                                      flex: 2,
                                      child: Text(s.name, style: AppTextStyles.clashDisplay(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                    ),
                                    // Email
                                    Expanded(
                                      flex: 3,
                                      child: Text(s.email, style: AppTextStyles.jetBrainsMono(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                    ),
                                    // Role badge
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.geminiPurple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(AppRadius.badge),
                                        ),
                                        child: Text(
                                          s.staffRole ?? 'Staff',
                                          style: AppTextStyles.jetBrainsMono(fontSize: 10, color: AppColors.geminiPurple),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    // Status
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: s.isOnDuty ? AppColors.signalTeal.withValues(alpha: 0.15) : AppColors.textMuted.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppRadius.badge),
                                        ),
                                        child: Text(
                                          s.isOnDuty ? 'On Duty' : 'Off Duty',
                                          style: AppTextStyles.jetBrainsMono(
                                            fontSize: 10,
                                            color: s.isOnDuty ? AppColors.signalTeal : AppColors.textMuted,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    // Actions
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => staff.toggleDuty(s.uid, !s.isOnDuty),
                                            icon: Icon(
                                              s.isOnDuty ? Icons.toggle_on : Icons.toggle_off,
                                              color: s.isOnDuty ? AppColors.signalTeal : AppColors.textMuted,
                                              size: 28,
                                            ),
                                            tooltip: s.isOnDuty ? 'Set Off Duty' : 'Set On Duty',
                                          ),
                                          IconButton(
                                            onPressed: () => _editRole(s),
                                            icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
                                            tooltip: 'Edit Role',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _editRole(UserModel s) {
    String selectedRole = s.staffRole ?? 'Security';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text('Edit Role — ${s.name}', style: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: DropdownButtonFormField<String>(
          initialValue: selectedRole,
          dropdownColor: AppColors.surface,
          items: ['Security', 'Medical', 'Front Desk', 'Manager'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => selectedRole = v ?? selectedRole,
          style: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Staff Role'),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<StaffProvider>().updateRole(s.uid, selectedRole);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.geminiPurple),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
