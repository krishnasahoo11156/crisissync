import 'package:flutter/material.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/rtdb_service.dart';
import 'dart:async';

/// Incident state provider.
class IncidentProvider extends ChangeNotifier {
  List<IncidentModel> _activeIncidents = [];
  List<IncidentModel> _allIncidents = [];
  bool _isLoading = true;
  StreamSubscription? _rtdbSub;
  StreamSubscription? _firestoreSub;
  StreamSubscription? _allSub;

  List<IncidentModel> get activeIncidents => _activeIncidents;
  List<IncidentModel> get allIncidents => _allIncidents;
  bool get isLoading => _isLoading;
  int get activeCount => _activeIncidents.length;
  int get criticalCount => _activeIncidents.where((i) => i.severity >= 4).length;

  void startListening() {
    // RTDB for sub-200ms detection
    _rtdbSub = RtdbService.streamActiveIncidents().listen((incidents) {
      _activeIncidents = incidents;
      _isLoading = false;
      notifyListeners();
    });

    // Firestore for full data
    _firestoreSub = IncidentService.streamActiveIncidents().listen((incidents) {
      // Merge with RTDB data — Firestore has richer data
      for (final fsIncident in incidents) {
        final idx = _activeIncidents.indexWhere((i) => i.id == fsIncident.id);
        if (idx >= 0) {
          _activeIncidents[idx] = fsIncident;
        } else {
          _activeIncidents.add(fsIncident);
        }
      }
      // Remove any that are no longer active in Firestore
      _activeIncidents.removeWhere(
        (i) => !incidents.any((fi) => fi.id == i.id) && i.geminiClassification != null,
      );
      _activeIncidents.sort((a, b) {
        final sevComp = b.severity.compareTo(a.severity);
        if (sevComp != 0) return sevComp;
        return b.createdAt.compareTo(a.createdAt);
      });
      notifyListeners();
    });
  }

  void startListeningAll() {
    _allSub = IncidentService.streamAllIncidents().listen((incidents) {
      _allIncidents = incidents;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _rtdbSub?.cancel();
    _firestoreSub?.cancel();
    _allSub?.cancel();
    super.dispose();
  }
}
