import 'package:flutter/material.dart';
import 'package:crisissync/models/user_model.dart';
import 'package:crisissync/services/auth_service.dart';
import 'dart:async';

/// Staff state provider.
class StaffProvider extends ChangeNotifier {
  List<UserModel> _staffList = [];
  bool _isLoading = true;
  StreamSubscription? _sub;

  List<UserModel> get staffList => _staffList;
  List<UserModel> get onDutyStaff => _staffList.where((s) => s.isOnDuty).toList();
  bool get isLoading => _isLoading;

  void startListening() {
    _sub = AuthService.streamStaffUsers().listen((staff) {
      _staffList = staff;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleDuty(String uid, bool isOnDuty) async {
    await AuthService.toggleDutyStatus(uid, isOnDuty);
  }

  Future<void> updateRole(String uid, String role) async {
    await AuthService.updateStaffRole(uid, role);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
