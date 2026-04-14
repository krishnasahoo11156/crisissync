import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crisissync/models/user_model.dart';
import 'package:crisissync/services/auth_service.dart';

/// Authentication state provider.
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  String? get userRole => _user?.role;
  String get uid => _user?.uid ?? '';

  AuthProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      try {
        _user = await AuthService.getUserProfile(firebaseUser.uid);
        if (_user == null) {
          // Check seed accounts
          final email = firebaseUser.email ?? '';
          final seed = UserModel.seedAccounts.firstWhere(
            (a) => a['email'] == email,
            orElse: () => <String, dynamic>{},
          );

          if (seed.isNotEmpty) {
            _user = UserModel(
              uid: firebaseUser.uid,
              email: email,
              name: seed['name'] ?? firebaseUser.displayName ?? 'User',
              role: seed['role'] ?? 'guest',
              roomNumber: seed['roomNumber'],
              staffRole: seed['staffRole'],
              isOnDuty: seed['isOnDuty'] ?? false,
            );
          } else {
            _user = UserModel(
              uid: firebaseUser.uid,
              email: email,
              name: firebaseUser.displayName ?? 'Guest',
              role: 'guest',
            );
          }
          await AuthService.createOrUpdateUser(_user!);
        }
      } catch (e) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.signInWithGoogle();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateRoomNumber(String roomNumber) async {
    if (_user == null) return;
    await AuthService.updateRoomNumber(_user!.uid, roomNumber);
    _user = _user!.copyWith(roomNumber: roomNumber);
    notifyListeners();
  }

  void refreshUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
