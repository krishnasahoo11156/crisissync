import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // guest, staff, admin
  final String? roomNumber;
  final String? staffRole; // Security, Medical, FrontDesk, Manager
  final bool isOnDuty;
  final String? fcmToken;
  final DateTime createdAt;
  final Map<String, dynamic>? lastLocation;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.roomNumber,
    this.staffRole,
    this.isOnDuty = false,
    this.fcmToken,
    DateTime? createdAt,
    this.lastLocation,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'guest',
      roomNumber: data['roomNumber'],
      staffRole: data['staffRole'],
      isOnDuty: data['isOnDuty'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLocation: data['lastLocation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (staffRole != null) 'staffRole': staffRole,
      'isOnDuty': isOnDuty,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
      if (lastLocation != null) 'lastLocation': lastLocation,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? roomNumber,
    String? staffRole,
    bool? isOnDuty,
    String? fcmToken,
    DateTime? createdAt,
    Map<String, dynamic>? lastLocation,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      roomNumber: roomNumber ?? this.roomNumber,
      staffRole: staffRole ?? this.staffRole,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }

  /// Pre-configured accounts for seeding.
  static List<Map<String, dynamic>> get seedAccounts => [
    {
      'email': 'krishnasahoo11156@gmail.com',
      'name': 'Krishna (Admin)',
      'role': 'admin',
      'isOnDuty': true,
    },
    {
      'email': 'hrnovabyte@gmail.com',
      'name': 'Nova',
      'role': 'staff',
      'staffRole': 'Security',
      'isOnDuty': true,
    },
    {
      'email': 'antigravitykrishna1@gmail.com',
      'name': 'Krishna',
      'role': 'staff',
      'staffRole': 'Medical',
      'isOnDuty': true,
    },
    {
      'email': 'sahoosujata291@gmail.com',
      'name': 'Sujata',
      'role': 'staff',
      'staffRole': 'Front Desk',
      'isOnDuty': true,
    },
    {
      'email': 'shriisingh123@gmail.com',
      'name': 'Shrii',
      'role': 'staff',
      'staffRole': 'Manager',
      'isOnDuty': true,
    },
    {
      'email': 'krsnasahoo469@gmail.com',
      'name': 'Krish',
      'role': 'guest',
      'roomNumber': '306',
    },
    {
      'email': 'krishnasahoo4285@gmail.com',
      'name': 'Krishna S',
      'role': 'guest',
      'roomNumber': '412',
    },
  ];
}
