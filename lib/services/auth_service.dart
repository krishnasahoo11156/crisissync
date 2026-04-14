import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crisissync/models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (web popup).
  static Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final UserCredential result = await _auth.signInWithPopup(googleProvider);
      final User? user = result.user;
      if (user == null) return null;

      // Check if user exists in Firestore
      UserModel? userModel = await getUserProfile(user.uid);
      if (userModel != null) return userModel;

      // Check pre-configured accounts by email
      final email = user.email ?? '';
      final seedAccount = UserModel.seedAccounts.firstWhere(
        (a) => a['email'] == email,
        orElse: () => {},
      );

      if (seedAccount.isNotEmpty) {
        userModel = UserModel(
          uid: user.uid,
          email: email,
          name: seedAccount['name'] ?? user.displayName ?? 'User',
          role: seedAccount['role'] ?? 'guest',
          roomNumber: seedAccount['roomNumber'],
          staffRole: seedAccount['staffRole'],
          isOnDuty: seedAccount['isOnDuty'] ?? false,
        );
      } else {
        // New unknown user — default to guest
        userModel = UserModel(
          uid: user.uid,
          email: email,
          name: user.displayName ?? 'Guest',
          role: 'guest',
        );
      }

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

  /// Update FCM token.
  static Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Sign out.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Seed pre-configured accounts to Firestore.
  static Future<void> seedAccounts() async {
    final batch = _firestore.batch();
    for (final account in UserModel.seedAccounts) {
      // Check if already seeded by email
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: account['email'])
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        final docRef = _firestore.collection('users').doc();
        batch.set(docRef, {
          ...account,
          'isOnDuty': account['isOnDuty'] ?? false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
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
