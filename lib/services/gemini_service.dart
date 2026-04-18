import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crisissync/config/env.dart';

/// Gemini AI service with automatic API key rotation on 429 errors.
class GeminiService {
  static const List<String> _apiKeys = [
    'AIzaSyAXhEfJFsjdXH3erdc_oGRjCEP8S7hspNg',
    'AIzaSyBhVuufhc9xyOd8Y5qRxvmrK_X8EUJjQuo',
    'AIzaSyC531MIRcXdX4YiipAx6qW1Cc9DZprbeaM',
    'AIzaSyCa1xS7uXCjqG8lXRxQImQPoc9UqYRqClY',
    'AIzaSyBlIwF1FvyKDKyw487C9YNlvV0u-jYY2sQ',
  ];
  static int _currentKeyIndex = 0;

  static String get _currentKey => _apiKeys[_currentKeyIndex];

  static void _rotateKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
  }

  /// Make a Gemini API call with automatic key rotation on 429.
  static Future<String> _callGemini(String prompt, {int retries = 5}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      final url = Uri.parse(
        '${Env.geminiBaseUrl}?key=$_currentKey',
      );

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2048,
        }
      });

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          return text;
        } else if (response.statusCode == 429) {
          // Rate limited — rotate key and retry
          _rotateKey();
          continue;
        } else {
          throw Exception('Gemini API error: ${response.statusCode} — ${response.body}');
        }
      } catch (e) {
        if (attempt == retries - 1) rethrow;
        _rotateKey();
      }
    }
    throw Exception('All Gemini API keys exhausted');
  }

  /// Classify a crisis incident.
  static Future<Map<String, dynamic>> classifyIncident({
    required String crisisType,
    required String description,
    String? voiceTranscript,
    required String roomNumber,
  }) async {
    final prompt = '''You are an AI crisis response classifier for a luxury hotel.

Analyze this emergency report and return ONLY valid JSON (no markdown, no code blocks):

Room: $roomNumber
Crisis Type (reported): $crisisType
Description: ${description.isNotEmpty ? description : 'None provided'}
Voice Transcript: ${voiceTranscript ?? 'None'}

Return JSON with these exact fields:
{
  "crisisType": "fire|medical|security|flood|power|other",
  "severity": <1-5 integer>,
  "situationBrief": "<2-3 sentence situational brief>",
  "suggestedAction": "<primary recommended action>",
  "responseRole": "Security|Medical|FrontDesk|Manager",
  "checklist": ["<step 1>", "<step 2>", "<step 3>", "<step 4>"],
  "emotionalState": "Calm|Anxious|Panicked|Incoherent"
}

Severity Guide:
1 = Minor concern, no immediate danger
2 = Low urgency, can wait
3 = Moderate, needs attention within 10 min
4 = High urgency, immediate response needed
5 = Critical/life-threatening, all hands on deck
''';

    try {
      final result = await _callGemini(prompt);
      // Strip markdown code fences if present
      String cleaned = result.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```json?\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {
        'crisisType': crisisType,
        'severity': 3,
        'situationBrief': 'AI classification failed. Please assess the situation manually.',
        'suggestedAction': 'Investigate and assess the situation.',
        'responseRole': 'Security',
        'checklist': [
          'Assess the situation on arrival',
          'Ensure guest safety',
          'Contact relevant emergency services if needed',
          'Document the incident',
        ],
        'emotionalState': 'Anxious',
      };
    }
  }

  /// Generate a post-incident report.
  static Future<String> generatePostIncidentReport({
    required String crisisType,
    required int severity,
    required String roomNumber,
    required String guestName,
    required String description,
    required String staffName,
    required String staffRole,
    required String resolvedNotes,
    required Duration responseTime,
    required List<Map<String, dynamic>> timeline,
  }) async {
    final timelineStr = timeline
        .map((e) => '- ${e['action']} by ${e['byName']} at ${e['timestamp']}')
        .join('\n');

    final prompt = '''Generate a formal post-incident report for a hotel emergency.

INCIDENT DETAILS:
- Type: $crisisType
- Severity: $severity/5
- Room: $roomNumber
- Guest: $guestName
- Description: $description
- Resolved By: $staffName ($staffRole)
- Resolution Notes: $resolvedNotes
- Total Response Time: ${responseTime.inMinutes} minutes ${responseTime.inSeconds % 60} seconds

TIMELINE:
$timelineStr

Write a professional 3-4 paragraph report suitable for hotel records. Include:
1. Incident summary
2. Response actions taken
3. Resolution details
4. Recommendations for prevention
''';

    return _callGemini(prompt);
  }

  /// Generate an executive briefing for admin.
  static Future<String> generateBriefing(List<Map<String, dynamic>> activeIncidents) async {
    final incidentSummary = activeIncidents
        .map((i) => '- Room ${i['roomNumber']}: ${i['crisisType']} (Severity ${i['severity']}) — Status: ${i['status']}')
        .join('\n');

    final prompt = '''You are the AI briefing system for Grand Meridian Hotel's CrisisSync platform.

CURRENT ACTIVE INCIDENTS:
$incidentSummary

${activeIncidents.isEmpty ? 'No active incidents.' : ''}

Generate a 3-4 paragraph executive briefing for hotel management. Include:
1. Current situation overview
2. Priority assessment
3. Resource allocation recommendations
4. Risk factors to monitor

Be concise and actionable. Use professional hospitality industry language.
''';

    return _callGemini(prompt);
  }

  /// Calculate ADI Score.
  static Future<double> calculateADIScore({
    required int severity,
    required Duration elapsed,
    required Duration timeSinceLastAction,
    required int responderCount,
    required String crisisType,
  }) async {
    // Client-side ADI calculation (fast, no API call needed)
    double score = 0;

    // Severity factor (0-40 points)
    score += severity * 8.0;

    // Time elapsed factor (0-25 points)
    final elapsedMinutes = elapsed.inMinutes;
    if (elapsedMinutes > 30) {
      score += 25;
    } else if (elapsedMinutes > 15) {
      score += 18;
    } else if (elapsedMinutes > 5) {
      score += 10;
    } else {
      score += elapsedMinutes * 2.0;
    }

    // Time since last action (0-20 points)
    final idleMinutes = timeSinceLastAction.inMinutes;
    if (idleMinutes > 10) {
      score += 20;
    } else if (idleMinutes > 5) {
      score += 12;
    } else {
      score += idleMinutes * 2.0;
    }

    // Responder factor (0-15 points, inverse)
    if (responderCount == 0) {
      score += 15;
    } else if (responderCount == 1) {
      score += 8;
    } else {
      score += 3;
    }

    // Crisis type urgency modifier
    final typeMultipliers = {
      'fire': 1.3,
      'medical': 1.2,
      'security': 1.1,
      'flood': 1.05,
      'power': 0.9,
      'other': 1.0,
    };
    score *= typeMultipliers[crisisType] ?? 1.0;

    return score.clamp(0, 100);
  }

  /// Generate monthly analytics report.
  static Future<String> generateMonthlyReport(Map<String, dynamic> monthData) async {
    final prompt = '''Generate a monthly executive summary report for Grand Meridian Hotel crisis management.

MONTHLY DATA:
${jsonEncode(monthData)}

Write a 4-paragraph executive summary with:
1. Monthly overview and key metrics
2. Trend analysis and notable patterns
3. Staff performance highlights
4. Recommendations for next month

Use professional language suitable for hotel leadership.
''';

    return _callGemini(prompt);
  }

  /// Generate shift handover report.
  static Future<String> generateShiftHandover({
    required List<Map<String, dynamic>> shiftIncidents,
    required Map<String, dynamic> staffPerformance,
    required String shiftPeriod,
  }) async {
    final prompt = '''Generate a shift handover report for Grand Meridian Hotel.

SHIFT PERIOD: $shiftPeriod
INCIDENTS DURING SHIFT: ${jsonEncode(shiftIncidents)}
STAFF PERFORMANCE: ${jsonEncode(staffPerformance)}

Create a concise handover report for the incoming shift. Include:
1. Shift summary
2. Pending/active incidents requiring attention
3. Staff notes and performance
4. Items for the incoming shift to monitor
''';

    return _callGemini(prompt);
  }

  /// Generate hotspot analysis.
  static Future<String> generateHotspotInsight(List<Map<String, dynamic>> hotspots) async {
    final prompt = '''Analyze these hotel incident hotspots and provide brief insights.

HOTSPOT DATA (top rooms/floors by incident frequency and severity):
${jsonEncode(hotspots)}

Provide exactly 3 brief insights (2 sentences each) about the top hotspot areas.
Focus on possible causes and prevention recommendations.
Return as a JSON array of strings.
''';

    final result = await _callGemini(prompt);
    return result;
  }
}
