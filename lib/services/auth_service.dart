import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisissync/models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (web popup).
  ///
  /// [portalRole] — the role the user is signing in for: 'guest', 'staff', or 'admin'.
  /// If the user already has a Firestore profile, it is returned as-is (their stored role wins).
  /// If it's a brand-new user, a minimal profile is created with [portalRole].
  static Future<UserModel?> signInWithGoogle({String portalRole = 'guest'}) async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      // Always show the account chooser so users can pick any account.
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final UserCredential result = await _auth.signInWithPopup(googleProvider);
      final User? user = result.user;
      if (user == null) return null;

      // If user already has a profile in Firestore, return it unchanged.
      UserModel? userModel = await getUserProfile(user.uid);
      if (userModel != null) return userModel;

      // Brand-new user — assign the role for the portal they chose.
      userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: portalRole,
        isOnDuty: portalRole == 'staff',
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile from Firestore.
  static Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create or update user profile in Firestore.
  static Future<void> createOrUpdateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(
      user.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Stream user profile updates.
  static Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
    );
  }

  /// Update user room number.
  static Future<void> updateRoomNumber(String uid, String roomNumber) async {
    await _firestore.collection('users').doc(uid).update({'roomNumber': roomNumber});
  }

  /// Update user display name.
  static Future<void> updateName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({'name': name});
  }

  /// Update user role (used when completing staff/admin registration).
  static Future<void> updateRole(String uid, String role, {String? staffRole}) async {
    final data = <String, dynamic>{'role': role};
    if (staffRole != null) data['staffRole'] = staffRole;
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Update FCM token.
  static Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Sign out.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get all staff users.
  static Stream<List<UserModel>> streamStaffUsers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  /// Get all on-duty staff.
  static Future<List<UserModel>> getOnDutyStaff() async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .where('isOnDuty', isEqualTo: true)
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// Toggle staff duty status.
  static Future<void> toggleDutyStatus(String uid, bool isOnDuty) async {
    await _firestore.collection('users').doc(uid).update({'isOnDuty': isOnDuty});
  }

  /// Update staff role.
  static Future<void> updateStaffRole(String uid, String staffRole) async {
    await _firestore.collection('users').doc(uid).update({'staffRole': staffRole});
  }
}
