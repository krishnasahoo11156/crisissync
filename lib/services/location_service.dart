import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Location service for staff GPS tracking using browser Geolocation API.
class LocationService {
  static Timer? _locationTimer;

  /// Get current position using browser Geolocation API.
  static Future<Map<String, double>?> getCurrentPosition() async {
    try {
      final completer = Completer<Map<String, double>?>();

      web.window.navigator.geolocation.getCurrentPosition(
        ((web.GeolocationPosition position) {
          completer.complete({
            'latitude': position.coords.latitude.toDouble(),
            'longitude': position.coords.longitude.toDouble(),
          });
        }).toJS,
        ((web.GeolocationPositionError error) {
          completer.complete(null);
        }).toJS,
      );

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  /// Start periodic location updates for staff.
  static void startTracking(String uid) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final pos = await getCurrentPosition();
      if (pos != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'lastLocation': {
              'latitude': pos['latitude'],
              'longitude': pos['longitude'],
              'updatedAt': FieldValue.serverTimestamp(),
            },
          });
        } catch (_) {}
      }
    });
  }

  /// Stop tracking.
  static void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}
