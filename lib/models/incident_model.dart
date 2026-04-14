import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiClassification {
  final String crisisType;
  final int severity;
  final String situationBrief;
  final String suggestedAction;
  final String responseRole;
  final List<String> checklist;
  final String? emotionalState;

  GeminiClassification({
    required this.crisisType,
    required this.severity,
    required this.situationBrief,
    required this.suggestedAction,
    required this.responseRole,
    required this.checklist,
    this.emotionalState,
  });

  factory GeminiClassification.fromMap(Map<String, dynamic> data) {
    return GeminiClassification(
      crisisType: data['crisisType'] ?? 'other',
      severity: data['severity'] ?? 3,
      situationBrief: data['situationBrief'] ?? '',
      suggestedAction: data['suggestedAction'] ?? '',
      responseRole: data['responseRole'] ?? '',
      checklist: List<String>.from(data['checklist'] ?? []),
      emotionalState: data['emotionalState'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crisisType': crisisType,
      'severity': severity,
      'situationBrief': situationBrief,
      'suggestedAction': suggestedAction,
      'responseRole': responseRole,
      'checklist': checklist,
      if (emotionalState != null) 'emotionalState': emotionalState,
    };
  }
}

class TimelineEvent {
  final String action;
  final String by;
  final String byName;
  final DateTime timestamp;
  final String? notes;

  TimelineEvent({
    required this.action,
    required this.by,
    required this.byName,
    required this.timestamp,
    this.notes,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> data) {
    return TimelineEvent(
      action: data['action'] ?? '',
      by: data['by'] ?? '',
      byName: data['byName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'by': by,
      'byName': byName,
      'timestamp': Timestamp.fromDate(timestamp),
      if (notes != null) 'notes': notes,
    };
  }
}

class ResponderInfo {
  final String uid;
  final String name;
  final String role;
  final DateTime joinedAt;

  ResponderInfo({
    required this.uid,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory ResponderInfo.fromMap(Map<String, dynamic> data) {
    return ResponderInfo(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class IncidentModel {
  final String id;
  final String guestUid;
  final String guestName;
  final String guestEmail;
  final String roomNumber;
  final String crisisType;
  final int severity;
  final String status; // active, accepted, responding, escalated, resolved
  final String? description;
  final String? voiceTranscript;
  final GeminiClassification? geminiClassification;
  final Map<String, dynamic>? acceptedBy;
  final Map<String, dynamic>? resolvedBy;
  final List<TimelineEvent> timeline;
  final List<ResponderInfo> responders;
  final Map<String, dynamic> checklistProgress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final bool emailSentOnCreate;
  final bool emailSentOnAccept;
  final bool emailSentOnResolve;
  final String? postIncidentReport;
  final double? adiScore;
  final int? rating;

  IncidentModel({
    required this.id,
    required this.guestUid,
    required this.guestName,
    required this.guestEmail,
    required this.roomNumber,
    required this.crisisType,
    required this.severity,
    required this.status,
    this.description,
    this.voiceTranscript,
    this.geminiClassification,
    this.acceptedBy,
    this.resolvedBy,
    List<TimelineEvent>? timeline,
    List<ResponderInfo>? responders,
    Map<String, dynamic>? checklistProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
    this.emailSentOnCreate = false,
    this.emailSentOnAccept = false,
    this.emailSentOnResolve = false,
    this.postIncidentReport,
    this.adiScore,
    this.rating,
  })  : timeline = timeline ?? [],
        responders = responders ?? [],
        checklistProgress = checklistProgress ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return IncidentModel(
      id: doc.id,
      guestUid: data['guestUid'] ?? '',
      guestName: data['guestName'] ?? '',
      guestEmail: data['guestEmail'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      crisisType: data['crisisType'] ?? 'other',
      severity: data['severity'] ?? 3,
      status: data['status'] ?? 'active',
      description: data['description'],
      voiceTranscript: data['voiceTranscript'],
      geminiClassification: data['geminiClassification'] != null
          ? GeminiClassification.fromMap(data['geminiClassification'] as Map<String, dynamic>)
          : null,
      acceptedBy: data['acceptedBy'] as Map<String, dynamic>?,
      resolvedBy: data['resolvedBy'] as Map<String, dynamic>?,
      timeline: (data['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEvent.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      responders: (data['responders'] as List<dynamic>?)
              ?.map((e) => ResponderInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      checklistProgress: Map<String, dynamic>.from(data['checklistProgress'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      emailSentOnCreate: data['emailSentOnCreate'] ?? false,
      emailSentOnAccept: data['emailSentOnAccept'] ?? false,
      emailSentOnResolve: data['emailSentOnResolve'] ?? false,
      postIncidentReport: data['postIncidentReport'],
      adiScore: (data['adiScore'] as num?)?.toDouble(),
      rating: data['rating'] as int?,
    );
  }

  factory IncidentModel.fromRtdb(String id, Map<dynamic, dynamic> data) {
    return IncidentModel(
      id: id,
      guestUid: data['guestUid'] ?? '',
      guestName: data['guestName'] ?? '',
      guestEmail: data['guestEmail'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      crisisType: data['crisisType'] ?? 'other',
      severity: data['severity'] ?? 3,
      status: data['status'] ?? 'active',
      description: data['description'],
      voiceTranscript: data['voiceTranscript'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
      adiScore: (data['adiScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guestUid': guestUid,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'roomNumber': roomNumber,
      'crisisType': crisisType,
      'severity': severity,
      'status': status,
      if (description != null) 'description': description,
      if (voiceTranscript != null) 'voiceTranscript': voiceTranscript,
      if (geminiClassification != null) 'geminiClassification': geminiClassification!.toMap(),
      if (acceptedBy != null) 'acceptedBy': acceptedBy,
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      'timeline': timeline.map((e) => e.toMap()).toList(),
      'responders': responders.map((e) => e.toMap()).toList(),
      'checklistProgress': checklistProgress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      'emailSentOnCreate': emailSentOnCreate,
      'emailSentOnAccept': emailSentOnAccept,
      'emailSentOnResolve': emailSentOnResolve,
      if (postIncidentReport != null) 'postIncidentReport': postIncidentReport,
      if (adiScore != null) 'adiScore': adiScore,
      if (rating != null) 'rating': rating,
    };
  }

  Map<String, dynamic> toRtdb() {
    return {
      'guestUid': guestUid,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'roomNumber': roomNumber,
      'crisisType': crisisType,
      'severity': severity,
      'status': status,
      'description': description ?? '',
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (adiScore != null) 'adiScore': adiScore,
      if (acceptedBy != null) 'acceptedBy': acceptedBy,
    };
  }

  IncidentModel copyWith({
    String? id,
    String? guestUid,
    String? guestName,
    String? guestEmail,
    String? roomNumber,
    String? crisisType,
    int? severity,
    String? status,
    String? description,
    String? voiceTranscript,
    GeminiClassification? geminiClassification,
    Map<String, dynamic>? acceptedBy,
    Map<String, dynamic>? resolvedBy,
    List<TimelineEvent>? timeline,
    List<ResponderInfo>? responders,
    Map<String, dynamic>? checklistProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool? emailSentOnCreate,
    bool? emailSentOnAccept,
    bool? emailSentOnResolve,
    String? postIncidentReport,
    double? adiScore,
    int? rating,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      guestUid: guestUid ?? this.guestUid,
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      roomNumber: roomNumber ?? this.roomNumber,
      crisisType: crisisType ?? this.crisisType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      geminiClassification: geminiClassification ?? this.geminiClassification,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      timeline: timeline ?? this.timeline,
      responders: responders ?? this.responders,
      checklistProgress: checklistProgress ?? this.checklistProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      emailSentOnCreate: emailSentOnCreate ?? this.emailSentOnCreate,
      emailSentOnAccept: emailSentOnAccept ?? this.emailSentOnAccept,
      emailSentOnResolve: emailSentOnResolve ?? this.emailSentOnResolve,
      postIncidentReport: postIncidentReport ?? this.postIncidentReport,
      adiScore: adiScore ?? this.adiScore,
      rating: rating ?? this.rating,
    );
  }

  Duration get elapsed => DateTime.now().difference(createdAt);

  String get elapsedFormatted {
    final d = elapsed;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  bool get isActive => status != 'resolved';
  bool get isCritical => severity >= 4;
}
