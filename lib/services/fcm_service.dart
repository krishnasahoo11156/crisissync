import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM service for web push notifications.
/// Uses Firestore onSnapshot as primary real-time mechanism.
/// FCM is the fallback for background/closed browsers.
class FcmService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request notification permission (Web).
  static Future<void> requestPermission() async {
    // Web notification permission is handled via the browser API
    // The firebase-messaging-sw.js service worker handles background push
  }

  /// Save FCM token to user profile.
  static Future<void> saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Create in-app notification for a user.
  static Future<void> createNotification({
    required String uid,
    required String message,
    required String? incidentId,
    required String type,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .add({
      'message': message,
      'incidentId': incidentId,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Notify all on-duty staff of a new incident.
  static Future<void> notifyOnDutyStaff({
    required String incidentId,
    required String crisisType,
    required int severity,
    required String roomNumber,
  }) async {
    final staffSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .where('isOnDuty', isEqualTo: true)
        .get();

    for (final doc in staffSnap.docs) {
      await createNotification(
        uid: doc.id,
        message: '🔴 SEV-$severity $crisisType emergency in Room $roomNumber',
        incidentId: incidentId,
        type: 'new_incident',
      );
    }
  }

  /// Stream unread notification count.
  static Stream<int> streamUnreadCount(String uid) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream notifications for a user.
  static Stream<List<Map<String, dynamic>>> streamNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Mark notification as read.
  static Future<void> markAsRead(String uid, String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead(String uid) async {
    final snap = await _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
