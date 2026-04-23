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
        // Try to load existing Firestore profile.
        _user = await AuthService.getUserProfile(firebaseUser.uid);

        // If no profile yet, create a default guest profile.
        // The auth screen will update the role/name via registration flow.
        if (_user == null) {
          _user = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? '',
            role: 'guest',
          );
          await AuthService.createOrUpdateUser(_user!);
        }
      } catch (e) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  /// Sign in with Google, assigning [portalRole] to brand-new users.
  Future<void> signInWithGoogle({String portalRole = 'guest'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.signInWithGoogle(portalRole: portalRole);
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

  Future<void> updateName(String name) async {
    if (_user == null) return;
    await AuthService.updateName(_user!.uid, name);
    _user = _user!.copyWith(name: name);
    notifyListeners();
  }

  Future<void> updateRole(String role, {String? staffRole}) async {
    if (_user == null) return;
    await AuthService.updateRole(_user!.uid, role, staffRole: staffRole);
    _user = _user!.copyWith(role: role, staffRole: staffRole ?? _user!.staffRole);
    notifyListeners();
  }

  void refreshUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
