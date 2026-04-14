import 'package:firebase_database/firebase_database.dart';
import 'package:crisissync/models/incident_model.dart';

/// Realtime Database service for sub-200ms active incident updates.
class RtdbService {
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Stream all active incidents from RTDB.
  static Stream<List<IncidentModel>> streamActiveIncidents() {
    return _rtdb.ref('active_incidents').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <IncidentModel>[];

      final incidents = <IncidentModel>[];
      data.forEach((key, value) {
        if (value is Map) {
          incidents.add(IncidentModel.fromRtdb(key.toString(), value));
        }
      });

      // Sort by severity DESC then createdAt DESC
      incidents.sort((a, b) {
        final sevComp = b.severity.compareTo(a.severity);
        if (sevComp != 0) return sevComp;
        return b.createdAt.compareTo(a.createdAt);
      });

      return incidents;
    });
  }

  /// Stream a single active incident from RTDB.
  static Stream<IncidentModel?> streamIncident(String incidentId) {
    return _rtdb.ref('active_incidents/$incidentId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return IncidentModel.fromRtdb(incidentId, data);
    });
  }

  /// Get count of active incidents.
  static Stream<int> streamActiveCount() {
    return _rtdb.ref('active_incidents').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.length ?? 0;
    });
  }

  /// Check for new incidents (detect additions).
  static Stream<DatabaseEvent> onChildAdded() {
    return _rtdb.ref('active_incidents').onChildAdded;
  }

  /// Listen for removed incidents.
  static Stream<DatabaseEvent> onChildRemoved() {
    return _rtdb.ref('active_incidents').onChildRemoved;
  }
}
