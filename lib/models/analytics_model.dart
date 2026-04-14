class AnalyticsModel {
  final String date;
  final int totalIncidents;
  final int resolvedIncidents;
  final double avgResponseTime; // in minutes
  final Map<String, int> incidentsByType;
  final Map<String, int> incidentsByFloor;
  final Map<String, int> incidentsBySeverity;
  final Map<String, dynamic> staffPerformance;

  AnalyticsModel({
    required this.date,
    this.totalIncidents = 0,
    this.resolvedIncidents = 0,
    this.avgResponseTime = 0,
    Map<String, int>? incidentsByType,
    Map<String, int>? incidentsByFloor,
    Map<String, int>? incidentsBySeverity,
    Map<String, dynamic>? staffPerformance,
  })  : incidentsByType = incidentsByType ?? {},
        incidentsByFloor = incidentsByFloor ?? {},
        incidentsBySeverity = incidentsBySeverity ?? {},
        staffPerformance = staffPerformance ?? {};

  factory AnalyticsModel.fromMap(String date, Map<String, dynamic> data) {
    return AnalyticsModel(
      date: date,
      totalIncidents: data['totalIncidents'] ?? 0,
      resolvedIncidents: data['resolvedIncidents'] ?? 0,
      avgResponseTime: (data['avgResponseTime'] as num?)?.toDouble() ?? 0,
      incidentsByType: Map<String, int>.from(data['incidentsByType'] ?? {}),
      incidentsByFloor: Map<String, int>.from(data['incidentsByFloor'] ?? {}),
      incidentsBySeverity: Map<String, int>.from(data['incidentsBySeverity'] ?? {}),
      staffPerformance: Map<String, dynamic>.from(data['staffPerformance'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalIncidents': totalIncidents,
      'resolvedIncidents': resolvedIncidents,
      'avgResponseTime': avgResponseTime,
      'incidentsByType': incidentsByType,
      'incidentsByFloor': incidentsByFloor,
      'incidentsBySeverity': incidentsBySeverity,
      'staffPerformance': staffPerformance,
    };
  }
}
