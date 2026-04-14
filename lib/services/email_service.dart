import 'dart:js_interop';

/// Email service using EmailJS for sending real emails from Flutter Web.
/// EmailJS is loaded via CDN in index.html with helper functions.
class EmailService {
  // TODO: Create a free account at https://emailjs.com
  // TODO: Fill in your Service ID and Public Key below
  static const String _serviceId = 'YOUR_EMAILJS_SERVICE_ID';
  static const String _publicKey = 'YOUR_EMAILJS_PUBLIC_KEY';

  /// Initialize EmailJS.
  static void init() {
    try {
      _callInitEmailJS(_publicKey.toJS);
    } catch (_) {
      // EmailJS not loaded — emails will be skipped
    }
  }

  /// Send incident created email to guest.
  static Future<void> sendIncidentCreated({
    required String guestEmail,
    required String guestName,
    required String incidentId,
    required String crisisType,
    required String roomNumber,
    required String timestamp,
  }) async {
    await _send('crisis_created', {
      'to_email': guestEmail,
      'guest_name': guestName,
      'incident_id': incidentId,
      'crisis_type': crisisType,
      'room_number': roomNumber,
      'timestamp': timestamp,
      'subject': '🚨 Your Emergency Request Has Been Received — CrisisSync #$incidentId',
    });
  }

  /// Send incident accepted email to guest.
  static Future<void> sendIncidentAccepted({
    required String guestEmail,
    required String guestName,
    required String incidentId,
    required String staffName,
    required String staffRole,
    required String roomNumber,
    required String timestamp,
  }) async {
    await _send('crisis_accepted', {
      'to_email': guestEmail,
      'guest_name': guestName,
      'incident_id': incidentId,
      'staff_name': staffName,
      'staff_role': staffRole,
      'room_number': roomNumber,
      'timestamp': timestamp,
      'subject': '✅ Your Request Has Been Accepted — Help is On the Way',
    });
  }

  /// Send incident resolved email to guest.
  static Future<void> sendIncidentResolved({
    required String guestEmail,
    required String guestName,
    required String incidentId,
    required String staffName,
    required String staffRole,
    required String roomNumber,
    required String responseTime,
    required String aiReport,
    required String notes,
    required String timestamp,
  }) async {
    await _send('crisis_resolved', {
      'to_email': guestEmail,
      'guest_name': guestName,
      'incident_id': incidentId,
      'staff_name': staffName,
      'staff_role': staffRole,
      'room_number': roomNumber,
      'response_time': responseTime,
      'ai_report': aiReport,
      'notes': notes,
      'timestamp': timestamp,
      'subject': '✨ Your Emergency Has Been Resolved — CrisisSync Report',
    });
  }

  /// Send alert to all on-duty staff.
  static Future<void> sendStaffAlert({
    required List<String> staffEmails,
    required String incidentId,
    required String crisisType,
    required int severity,
    required String roomNumber,
    required String description,
    required String timestamp,
  }) async {
    for (final email in staffEmails) {
      await _send('staff_alert', {
        'to_email': email,
        'incident_id': incidentId,
        'crisis_type': crisisType,
        'severity': severity.toString(),
        'room_number': roomNumber,
        'description': description,
        'timestamp': timestamp,
        'subject': '🔴 ALERT: SEV-$severity Emergency — Room $roomNumber — Immediate Response Required',
      });
    }
  }

  /// Internal method to call EmailJS send via JS interop.
  static Future<void> _send(String templateId, Map<String, String> params) async {
    try {
      final jsParams = params.jsify()!;
      _callSendEmailJS(
        _serviceId.toJS,
        templateId.toJS,
        jsParams,
        _publicKey.toJS,
      );
    } catch (_) {
      // Silently fail — EmailJS may not be configured yet
    }
  }
}

// JS interop bindings for EmailJS helper functions defined in index.html
@JS('window.initEmailJS')
external void _callInitEmailJS(JSString publicKey);

@JS('window.sendEmailJS')
external JSPromise _callSendEmailJS(
  JSString serviceId,
  JSString templateId,
  JSAny params,
  JSString publicKey,
);
