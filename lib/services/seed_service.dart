import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crisissync/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class SeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  static bool _hasSeeded = false;

  static Future<void> seedGimmickData() async {
    if (_hasSeeded) return;

    // Check if we already seeded to avoid duplicates
    final checkSnap = await _firestore.collection('analytics').limit(1).get();
    if (checkSnap.docs.isNotEmpty) {
      _hasSeeded = true;
      return; // Already has analytics data
    }

    print('Seeding minimal gimmick data for analytics...');

    // 1. Get all users to distribute incidents
    final usersSnap = await _firestore.collection('users').get();
    final users = usersSnap.docs.map((d) => UserModel.fromFirestore(d)).toList();

    final List<Map<String, dynamic>> staffAndAdmins = [];
    final List<Map<String, dynamic>> guests = [];

    if (users.isEmpty) {
      for (final acc in UserModel.seedAccounts) {
        if (acc['role'] == 'staff' || acc['role'] == 'admin') {
          staffAndAdmins.add(acc);
        } else {
          guests.add(acc);
        }
      }
    } else {
      for (final u in users) {
        if (u.role == 'staff' || u.role == 'admin') {
          staffAndAdmins.add({'uid': u.uid, 'name': u.name, 'role': u.role, 'staffRole': u.staffRole ?? 'Staff'});
        } else {
          guests.add({'uid': u.uid, 'name': u.name, 'email': u.email, 'roomNumber': u.roomNumber ?? '101'});
        }
      }
    }

    if (staffAndAdmins.isEmpty || guests.isEmpty) return;

    final random = Random();
    final crisisTypes = ['fire', 'medical', 'security', 'flood', 'power', 'other'];
    final rooms = ['101', '102', '105', '201', '204', '305', '306', '412', 'B1', 'Lobby', 'Pool'];

    final now = DateTime.now();
    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    // Aggregate analytics only — NO historical incident documents
    final Map<String, Map<String, dynamic>> analyticsMap = {};

    // Seed 30 days of analytics data (no incident docs created)
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // 1 to 3 incidents per day (minimal)
      final dailyIncidentCount = 1 + random.nextInt(3);

      analyticsMap[dateStr] = {
        'date': dateStr,
        'totalIncidents': 0,
        'resolvedIncidents': 0,
        'avgResponseTime': 0.0,
        'incidentsByType': <String, int>{},
        'incidentsBySeverity': <String, int>{},
        'incidentsByFloor': <String, int>{},
        'staffPerformance': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      double totalResponseTimeDay = 0;

      for (int j = 0; j < dailyIncidentCount; j++) {
        final staff = staffAndAdmins[random.nextInt(staffAndAdmins.length)];
        final crisisType = crisisTypes[random.nextInt(crisisTypes.length)];
        final room = rooms[random.nextInt(rooms.length)];
        final severity = 1 + random.nextInt(5);
        final responseTimeMinutes = 1.0 + random.nextInt(15) + random.nextDouble();

        // Update analytics only
        final dayData = analyticsMap[dateStr]!;
        dayData['totalIncidents'] = (dayData['totalIncidents'] as int) + 1;
        dayData['resolvedIncidents'] = (dayData['resolvedIncidents'] as int) + 1;
        totalResponseTimeDay += responseTimeMinutes;

        final byType = dayData['incidentsByType'] as Map<String, int>;
        byType[crisisType] = (byType[crisisType] ?? 0) + 1;

        final bySev = dayData['incidentsBySeverity'] as Map<String, int>;
        bySev['$severity'] = (bySev['$severity'] ?? 0) + 1;

        String floor = 'Unknown';
        if (room.startsWith('B')) floor = 'Basement';
        else if (room.isNotEmpty && RegExp(r'[0-9]').hasMatch(room[0])) floor = 'Floor ${room[0]}';
        else floor = room;

        final byFloor = dayData['incidentsByFloor'] as Map<String, int>;
        byFloor[floor] = (byFloor[floor] ?? 0) + 1;

        final staffPerf = dayData['staffPerformance'] as Map<String, dynamic>;
        final staffUid = staff['uid'] ?? 'dummy';
        final staffStats = staffPerf[staffUid] as Map<String, dynamic>? ?? {
          'incidents': 0,
          'totalResponseTime': 0.0,
          'avgResponseTime': 0.0,
        };
        staffStats['incidents'] = (staffStats['incidents'] as int) + 1;
        staffStats['totalResponseTime'] = (staffStats['totalResponseTime'] as double) + responseTimeMinutes;
        staffStats['avgResponseTime'] = (staffStats['totalResponseTime'] as double) / (staffStats['incidents'] as int);
        staffPerf[staffUid] = staffStats;
      }

      if (analyticsMap[dateStr]!['resolvedIncidents'] > 0) {
        analyticsMap[dateStr]!['avgResponseTime'] =
            totalResponseTimeDay / analyticsMap[dateStr]!['resolvedIncidents'];
      }
    }

    // Write analytics to Firestore
    for (final dateStr in analyticsMap.keys) {
      final docRef = _firestore.collection('analytics').doc(dateStr);
      batch.set(docRef, analyticsMap[dateStr]!);
      batchCount++;
      if (batchCount >= 400) {
        await batch.commit();
        batchCount = 0;
        batch = _firestore.batch();
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      batchCount = 0;
      batch = _firestore.batch();
    }

    // Seed only 2 active incidents for demo (enough to show the live board)
    for (int i = 0; i < 2; i++) {
      final guest = guests[random.nextInt(guests.length)];
      final crisisType = crisisTypes[random.nextInt(crisisTypes.length)];
      final room = rooms[random.nextInt(rooms.length)];
      final severity = 3 + random.nextInt(3); // 3 to 5
      final incidentId = _uuid.v4().substring(0, 8).toUpperCase();
      final createdAt = DateTime.now().subtract(Duration(minutes: 5 + random.nextInt(20)));

      final incidentData = {
        'guestUid': guest['uid'] ?? 'dummy_guest_uid',
        'guestName': guest['name'],
        'guestEmail': guest['email'] ?? 'guest@example.com',
        'roomNumber': room,
        'crisisType': crisisType,
        'severity': severity,
        'status': 'active',
        'description': 'Demo active incident.',
        'timeline': [
          {
            'action': 'Incident reported',
            'by': guest['uid'] ?? 'dummy',
            'byName': guest['name'],
            'timestamp': Timestamp.fromDate(createdAt),
          }
        ],
        'responders': [],
        'checklistProgress': {},
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(createdAt),
        'emailSentOnCreate': true,
        'emailSentOnAccept': false,
        'emailSentOnResolve': false,
        'adiScore': random.nextDouble() * 40 + 10,
      };

      batch = _firestore.batch();
      batch.set(_firestore.collection('incidents').doc(incidentId), incidentData);

      // Write to RTDB for active incidents
      await FirebaseDatabase.instance.ref('active_incidents/$incidentId').set({
        'guestUid': guest['uid'] ?? 'dummy_guest_uid',
        'guestName': guest['name'],
        'guestEmail': guest['email'] ?? 'guest@example.com',
        'roomNumber': room,
        'crisisType': crisisType,
        'severity': severity,
        'status': 'active',
        'description': 'Demo active incident.',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': createdAt.millisecondsSinceEpoch,
      });

      // Update today's analytics
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore.collection('analytics').doc(todayStr);
      batch.set(docRef, {
        'totalIncidents': FieldValue.increment(1),
        'incidentsByType.$crisisType': FieldValue.increment(1),
        'incidentsBySeverity.$severity': FieldValue.increment(1),
        'incidentsByFloor.${room.startsWith('B') ? 'Basement' : RegExp(r'[0-9]').hasMatch(room[0]) ? 'Floor ${room[0]}' : room}': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    }

    _hasSeeded = true;
    print('Finished seeding minimal gimmick data!');
  }
}
