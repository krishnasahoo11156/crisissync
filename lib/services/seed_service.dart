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
    if (checkSnap.docs.length > 2) {
      _hasSeeded = true;
      return; // Already has enough analytics data
    }

    print('Seeding gimmick data for analytics...');

    // 1. Get all users to distribute incidents
    final usersSnap = await _firestore.collection('users').get();
    final users = usersSnap.docs.map((d) => UserModel.fromFirestore(d)).toList();

    // If users aren't loaded yet, we'll use the seed accounts directly
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

    // We will aggregate analytics data in memory
    final Map<String, Map<String, dynamic>> analyticsMap = {};

    // Generate past 30 days of data
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // 2 to 6 incidents per day
      final dailyIncidentCount = 2 + random.nextInt(5);

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
        final guest = guests[random.nextInt(guests.length)];
        final staff = staffAndAdmins[random.nextInt(staffAndAdmins.length)];
        final crisisType = crisisTypes[random.nextInt(crisisTypes.length)];
        final room = rooms[random.nextInt(rooms.length)];
        final severity = 1 + random.nextInt(5);

        // Randomize times
        final startHour = random.nextInt(23);
        final startMin = random.nextInt(59);
        final createdAt = DateTime(date.year, date.month, date.day, startHour, startMin);
        
        final responseTimeMinutes = 1.0 + random.nextInt(15) + random.nextDouble();
        final resolvedAt = createdAt.add(Duration(seconds: (responseTimeMinutes * 60).toInt()));

        final incidentId = _uuid.v4().substring(0, 8).toUpperCase();
        
        // Incident data
        final incidentData = {
          'guestUid': guest['uid'] ?? 'dummy_guest_uid',
          'guestName': guest['name'],
          'guestEmail': guest['email'] ?? 'guest@example.com',
          'roomNumber': room,
          'crisisType': crisisType,
          'severity': severity,
          'status': 'resolved',
          'description': 'Gimmick incident for analytics.',
          'timeline': [
            {
              'action': 'Incident reported',
              'by': guest['uid'] ?? 'dummy',
              'byName': guest['name'],
              'timestamp': Timestamp.fromDate(createdAt),
            },
            {
              'action': 'Incident resolved',
              'by': staff['uid'] ?? 'dummy',
              'byName': staff['name'],
              'timestamp': Timestamp.fromDate(resolvedAt),
              'notes': 'Resolved quickly.',
            }
          ],
          'responders': [
            {
              'uid': staff['uid'] ?? 'dummy',
              'name': staff['name'],
              'role': staff['staffRole'] ?? 'Staff',
              'joinedAt': Timestamp.fromDate(createdAt.add(const Duration(minutes: 1))),
            }
          ],
          'resolvedBy': {
            'staffUid': staff['uid'] ?? 'dummy',
            'staffName': staff['name'],
            'staffRole': staff['staffRole'] ?? 'Staff',
            'resolvedAt': Timestamp.fromDate(resolvedAt),
            'notes': 'Resolved quickly.',
          },
          'checklistProgress': {},
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(resolvedAt),
          'resolvedAt': Timestamp.fromDate(resolvedAt),
          'emailSentOnCreate': true,
          'emailSentOnAccept': true,
          'emailSentOnResolve': true,
          'postIncidentReport': 'Generated by gimmick seeder.',
          'adiScore': random.nextDouble() * 40 + 10,
        };

        final docRef = _firestore.collection('incidents').doc(incidentId);
        batch.set(docRef, incidentData);
        batchCount++;

        // Update analytics
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

        if (batchCount >= 400) {
          await batch.commit();
          batchCount = 0;
          batch = _firestore.batch();
        }
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

    // Seed 2 active incidents for today
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
        'description': 'Active gimmick incident.',
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
        'description': 'Active gimmick incident.',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': createdAt.millisecondsSinceEpoch,
      });

      // Update today's analytics for the active incident
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docRef = _firestore.collection('analytics').doc(todayStr);
      batch.set(docRef, {
        'totalIncidents': FieldValue.increment(1),
        'incidentsByType.$crisisType': FieldValue.increment(1),
        'incidentsBySeverity.$severity': FieldValue.increment(1),
        'incidentsByFloor.${room.startsWith('B') ? 'Basement' : RegExp(r'[0-9]').hasMatch(room[0]) ? 'Floor ${room[0]}' : room}': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    _hasSeeded = true;
    print('Finished seeding gimmick data!');
  }
}
