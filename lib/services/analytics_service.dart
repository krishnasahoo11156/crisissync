import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Analytics service for reading/writing daily analytics data.
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Increment incident count for today.
  static Future<void> incrementIncidentCount(
    String crisisType,
    int severity,
    String roomNumber,
  ) async {
    final docRef = _firestore.collection('analytics').doc(_todayKey);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (doc.exists) {
        transaction.update(docRef, {
          'totalIncidents': FieldValue.increment(1),
          'incidentsByType.$crisisType': FieldValue.increment(1),
          'incidentsBySeverity.$severity': FieldValue.increment(1),
          'incidentsByFloor.${_floorFromRoom(roomNumber)}': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'date': _todayKey,
          'totalIncidents': 1,
          'resolvedIncidents': 0,
          'avgResponseTime': 0,
          'incidentsByType': {crisisType: 1},
          'incidentsBySeverity': {'$severity': 1},
          'incidentsByFloor': {_floorFromRoom(roomNumber): 1},
          'staffPerformance': {},
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Record a resolution and update average response time.
  static Future<void> recordResolution(
    String crisisType,
    double responseTimeMinutes,
    String staffUid,
  ) async {
    final docRef = _firestore.collection('analytics').doc(_todayKey);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (doc.exists) {
        final data = doc.data()!;
        final currentResolved = (data['resolvedIncidents'] ?? 0) as int;
        final currentAvg = (data['avgResponseTime'] ?? 0) as num;
        final newResolved = currentResolved + 1;
        final newAvg = ((currentAvg * currentResolved) + responseTimeMinutes) / newResolved;

        final staffPerf = Map<String, dynamic>.from(data['staffPerformance'] ?? {});
        final staffData = Map<String, dynamic>.from(staffPerf[staffUid] ?? {});
        staffData['incidents'] = ((staffData['incidents'] ?? 0) as int) + 1;
        staffData['totalResponseTime'] =
            ((staffData['totalResponseTime'] ?? 0) as num) + responseTimeMinutes;
        staffData['avgResponseTime'] =
            (staffData['totalResponseTime'] as num) / (staffData['incidents'] as int);
        staffPerf[staffUid] = staffData;

        transaction.update(docRef, {
          'resolvedIncidents': newResolved,
          'avgResponseTime': newAvg,
          'staffPerformance': staffPerf,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'date': _todayKey,
          'totalIncidents': 0,
          'resolvedIncidents': 1,
          'avgResponseTime': responseTimeMinutes,
          'incidentsByType': {},
          'incidentsBySeverity': {},
          'incidentsByFloor': {},
          'staffPerformance': {
            staffUid: {
              'incidents': 1,
              'totalResponseTime': responseTimeMinutes,
              'avgResponseTime': responseTimeMinutes,
            }
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Stream today's analytics.
  static Stream<Map<String, dynamic>> streamTodayAnalytics() {
    return _firestore.collection('analytics').doc(_todayKey).snapshots().map(
      (doc) => doc.data() ?? _emptyAnalytics(),
    );
  }

  /// Get analytics for a date range.
  static Future<List<Map<String, dynamic>>> getAnalyticsRange(
    DateTime start,
    DateTime end,
  ) async {
    final startKey = DateFormat('yyyy-MM-dd').format(start);
    final endKey = DateFormat('yyyy-MM-dd').format(end);

    final snap = await _firestore
        .collection('analytics')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .orderBy(FieldPath.documentId)
        .get();

    return snap.docs.map((d) => {'date': d.id, ...d.data()}).toList();
  }

  static String _floorFromRoom(String room) {
    if (room.startsWith('B')) return 'Basement';
    if (room.length >= 1) {
      final floor = room[0];
      return 'Floor $floor';
    }
    return 'Unknown';
  }

  static Map<String, dynamic> _emptyAnalytics() {
    return {
      'date': _todayKey,
      'totalIncidents': 0,
      'resolvedIncidents': 0,
      'avgResponseTime': 0,
      'incidentsByType': {},
      'incidentsBySeverity': {},
      'incidentsByFloor': {},
      'staffPerformance': {},
    };
  }
}
