import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/gemini_service.dart';
import 'package:crisissync/services/analytics_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Service for all incident CRUD operations with both Firestore and RTDB.
class IncidentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  static const _uuid = Uuid();

  /// Create a new incident.
  static Future<String> createIncident({
    required String guestUid,
    required String guestName,
    required String guestEmail,
    required String roomNumber,
    required String crisisType,
    int severity = 3,
    String? description,
    String? voiceTranscript,
  }) async {
    final incidentId = _uuid.v4().substring(0, 8).toUpperCase();
    final now = DateTime.now();

    final incidentData = {
      'guestUid': guestUid,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'roomNumber': roomNumber,
      'crisisType': crisisType,
      'severity': severity,
      'status': 'active',
      'description': description ?? '',
      'voiceTranscript': voiceTranscript,
      'timeline': [
        {
          'action': 'Incident reported',
          'by': guestUid,
          'byName': guestName,
          'timestamp': Timestamp.fromDate(now),
        }
      ],
      'responders': [],
      'checklistProgress': {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'emailSentOnCreate': false,
      'emailSentOnAccept': false,
      'emailSentOnResolve': false,
    };

    // Write to Firestore
    await _firestore.collection('incidents').doc(incidentId).set(incidentData);

    // Write to RTDB for sub-200ms updates
    await _rtdb.ref('active_incidents/$incidentId').set({
      'guestUid': guestUid,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'roomNumber': roomNumber,
      'crisisType': crisisType,
      'severity': severity,
      'status': 'active',
      'description': description ?? '',
      'createdAt': now.millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    });

    // Update analytics
    await AnalyticsService.incrementIncidentCount(crisisType, severity, roomNumber);

    // Classify with Gemini (async — doesn't block)
    _classifyIncidentAsync(incidentId, crisisType, description ?? '', voiceTranscript, roomNumber);

    return incidentId;
  }

  /// Async Gemini classification.
  static Future<void> _classifyIncidentAsync(
    String incidentId,
    String crisisType,
    String description,
    String? voiceTranscript,
    String roomNumber,
  ) async {
    try {
      final classification = await GeminiService.classifyIncident(
        crisisType: crisisType,
        description: description,
        voiceTranscript: voiceTranscript,
        roomNumber: roomNumber,
      );

      await _firestore.collection('incidents').doc(incidentId).update({
        'geminiClassification': classification,
        'severity': classification['severity'] ?? 3,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update RTDB severity
      await _rtdb.ref('active_incidents/$incidentId').update({
        'severity': classification['severity'] ?? 3,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Gemini classification failure is non-critical
    }
  }

  /// Accept an incident.
  static Future<void> acceptIncident({
    required String incidentId,
    required String staffUid,
    required String staffName,
    required String staffRole,
  }) async {
    final now = DateTime.now();
    final acceptData = {
      'staffUid': staffUid,
      'staffName': staffName,
      'staffRole': staffRole,
      'acceptedAt': Timestamp.fromDate(now),
    };

    await _firestore.collection('incidents').doc(incidentId).update({
      'status': 'accepted',
      'acceptedBy': acceptData,
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([
        {
          'action': 'Incident accepted',
          'by': staffUid,
          'byName': staffName,
          'timestamp': Timestamp.fromDate(now),
          'notes': 'Accepted by $staffName ($staffRole)',
        }
      ]),
      'responders': FieldValue.arrayUnion([
        {
          'uid': staffUid,
          'name': staffName,
          'role': staffRole,
          'joinedAt': Timestamp.fromDate(now),
        }
      ]),
    });

    // Update RTDB
    await _rtdb.ref('active_incidents/$incidentId').update({
      'status': 'accepted',
      'acceptedBy': {
        'staffUid': staffUid,
        'staffName': staffName,
        'staffRole': staffRole,
      },
      'updatedAt': now.millisecondsSinceEpoch,
    });
  }

  /// Resolve an incident.
  static Future<String> resolveIncident({
    required String incidentId,
    required String staffUid,
    required String staffName,
    required String staffRole,
    String? notes,
  }) async {
    final now = DateTime.now();

    // Get incident for report generation
    final doc = await _firestore.collection('incidents').doc(incidentId).get();
    final incident = IncidentModel.fromFirestore(doc);

    // Generate AI report
    String aiReport = '';
    try {
      aiReport = await GeminiService.generatePostIncidentReport(
        crisisType: incident.crisisType,
        severity: incident.severity,
        roomNumber: incident.roomNumber,
        guestName: incident.guestName,
        description: incident.description ?? '',
        staffName: staffName,
        staffRole: staffRole,
        resolvedNotes: notes ?? '',
        responseTime: now.difference(incident.createdAt),
        timeline: incident.timeline.map((e) => e.toMap()).toList(),
      );
    } catch (_) {
      aiReport = 'AI report generation failed. Please create a manual report.';
    }

    await _firestore.collection('incidents').doc(incidentId).update({
      'status': 'resolved',
      'resolvedBy': {
        'staffUid': staffUid,
        'staffName': staffName,
        'staffRole': staffRole,
        'resolvedAt': Timestamp.fromDate(now),
        'notes': notes ?? '',
      },
      'resolvedAt': Timestamp.fromDate(now),
      'postIncidentReport': aiReport,
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([
        {
          'action': 'Incident resolved',
          'by': staffUid,
          'byName': staffName,
          'timestamp': Timestamp.fromDate(now),
          'notes': notes,
        }
      ]),
    });

    // Remove from RTDB
    await _rtdb.ref('active_incidents/$incidentId').remove();

    // Update analytics
    await AnalyticsService.recordResolution(
      incident.crisisType,
      now.difference(incident.createdAt).inMinutes.toDouble(),
      staffUid,
    );

    return aiReport;
  }

  /// Escalate to external services.
  static Future<void> escalateToExternal({
    required String incidentId,
    required String staffUid,
    required String staffName,
    required String service, // fire, ambulance, police
  }) async {
    final now = DateTime.now();

    await _firestore.collection('incidents').doc(incidentId).update({
      'status': 'escalated',
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': FieldValue.arrayUnion([
        {
          'action': 'Escalated to external: $service',
          'by': staffUid,
          'byName': staffName,
          'timestamp': Timestamp.fromDate(now),
          'notes': 'External $service services contacted',
        }
      ]),
    });

    await _rtdb.ref('active_incidents/$incidentId').update({
      'status': 'escalated',
      'updatedAt': now.millisecondsSinceEpoch,
    });
  }

  /// Update checklist item.
  static Future<void> updateChecklistItem({
    required String incidentId,
    required int itemIndex,
    required bool done,
    required String staffUid,
    required String staffName,
  }) async {
    await _firestore.collection('incidents').doc(incidentId).update({
      'checklistProgress.$itemIndex': {
        'done': done,
        'doneBy': staffUid,
        'doneByName': staffName,
        'doneAt': Timestamp.fromDate(DateTime.now()),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a note to timeline.
  static Future<void> addTimelineNote({
    required String incidentId,
    required String staffUid,
    required String staffName,
    required String note,
  }) async {
    await _firestore.collection('incidents').doc(incidentId).update({
      'timeline': FieldValue.arrayUnion([
        {
          'action': 'Note added',
          'by': staffUid,
          'byName': staffName,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'notes': note,
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rate an incident (guest).
  static Future<void> rateIncident(String incidentId, int rating) async {
    await _firestore.collection('incidents').doc(incidentId).update({
      'rating': rating,
    });
  }

  // ─── Streams ───

  /// Stream a single incident.
  static Stream<IncidentModel?> streamIncident(String incidentId) {
    return _firestore.collection('incidents').doc(incidentId).snapshots().map(
      (doc) => doc.exists ? IncidentModel.fromFirestore(doc) : null,
    );
  }

  /// Stream all active incidents.
  static Stream<List<IncidentModel>> streamActiveIncidents() {
    return _firestore
        .collection('incidents')
        .where('status', whereIn: ['active', 'accepted', 'responding', 'escalated'])
        .orderBy('severity', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => IncidentModel.fromFirestore(d)).toList());
  }

  /// Stream incidents for a guest.
  static Stream<List<IncidentModel>> streamGuestIncidents(String guestUid) {
    return _firestore
        .collection('incidents')
        .where('guestUid', isEqualTo: guestUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => IncidentModel.fromFirestore(d)).toList());
  }

  /// Stream all incidents (admin).
  static Stream<List<IncidentModel>> streamAllIncidents() {
    return _firestore
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => IncidentModel.fromFirestore(d)).toList());
  }

  /// Stream resolved incidents.
  static Stream<List<IncidentModel>> streamResolvedIncidents() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'resolved')
        .orderBy('resolvedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => IncidentModel.fromFirestore(d)).toList());
  }

  /// Get today's resolved count.
  static Future<int> getTodayResolvedCount() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc = await _firestore.collection('analytics').doc(today).get();
    if (doc.exists) {
      return (doc.data()?['resolvedIncidents'] ?? 0) as int;
    }
    return 0;
  }
}
