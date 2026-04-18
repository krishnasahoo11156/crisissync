import 'package:flutter/material.dart';
import 'package:crisissync/models/incident_model.dart';
import 'package:crisissync/services/incident_service.dart';
import 'package:crisissync/services/rtdb_service.dart';
import 'dart:async';

/// Incident state provider.
class IncidentProvider extends ChangeNotifier {
  List<IncidentModel> _activeIncidents = [];
  List<IncidentModel> _allIncidents = [];
  // Loading stays true until Firestore (rich data) has responded at least once.
  bool _isLoading = true;
  bool _firestoreLoaded = false;
  StreamSubscription? _rtdbSub;
  StreamSubscription? _firestoreSub;
  StreamSubscription? _allSub;

  List<IncidentModel> get activeIncidents => _activeIncidents;
  List<IncidentModel> get allIncidents => _allIncidents;
  bool get isLoading => _isLoading;
  int get activeCount => _activeIncidents.length;
  int get criticalCount => _activeIncidents.where((i) => i.severity >= 4).length;

  void startListening() {
    // RTDB fires first (<200ms) — use only to detect incident IDs quickly.
    // We do NOT render RTDB stubs directly to avoid blank cards.
    _rtdbSub = RtdbService.streamActiveIncidents().listen((_) {
      // Just mark non-loading if Firestore hasn't arrived yet after 2 s.
      // Actual list population is Firestore-driven below.
      Future.delayed(const Duration(seconds: 2), () {
        if (!_firestoreLoaded && _isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
    });

    // Firestore is the single source of truth for the rendered list.
    _firestoreSub = IncidentService.streamActiveIncidents().listen((incidents) {
      _firestoreLoaded = true;
      _isLoading = false;
      _activeIncidents = List<IncidentModel>.from(incidents)
        ..sort((a, b) {
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
