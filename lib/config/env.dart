/// Environment configuration for CrisisSync
/// Contains API keys and service credentials.
class Env {
  Env._();

  // Gemini API Keys — rotated automatically on 429
  static const List<String> geminiApiKeys = [
    'AIzaSyAXhEfJFsjdXH3erdc_oGRjCEP8S7hspNg',
    'AIzaSyBhVuufhc9xyOd8Y5qRxvmrK_X8EUJjQuo',
    'AIzaSyC531MIRcXdX4YiipAx6qW1Cc9DZprbeaM',
    'AIzaSyCa1xS7uXCjqG8lXRxQImQPoc9UqYRqClY',
    'AIzaSyBlIwF1FvyKDKyw487C9YNlvV0u-jYY2sQ',
  ];

  static const String geminiModel = 'gemini-2.0-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyAXhEfJFsjdXH3erdc_oGRjCEP8S7hspNg';

  // EmailJS Credentials
  // TODO: Create a free account at https://emailjs.com
  // TODO: Fill in your Service ID and Public Key below
  static const String emailjsServiceId = 'YOUR_EMAILJS_SERVICE_ID';
  static const String emailjsPublicKey = 'YOUR_EMAILJS_PUBLIC_KEY';

  // EmailJS Template IDs
  // TODO: Create these 4 templates in your EmailJS dashboard
  static const String emailTemplateCrisisCreated = 'crisis_created';
  static const String emailTemplateCrisisAccepted = 'crisis_accepted';
  static const String emailTemplateCrisisResolved = 'crisis_resolved';
  static const String emailTemplateStaffAlert = 'staff_alert';
}
