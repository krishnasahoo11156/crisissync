class VenueModel {
  final String id;
  final String name;
  final List<FloorModel> floors;
  final Map<String, String> emergencyContacts;

  VenueModel({
    required this.id,
    required this.name,
    required this.floors,
    required this.emergencyContacts,
  });

  factory VenueModel.fromMap(String id, Map<String, dynamic> data) {
    return VenueModel(
      id: id,
      name: data['name'] ?? '',
      floors: (data['floors'] as List<dynamic>?)
              ?.map((e) => FloorModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      emergencyContacts: Map<String, String>.from(data['emergencyContacts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'floors': floors.map((f) => f.toMap()).toList(),
      'emergencyContacts': emergencyContacts,
    };
  }

  static VenueModel get defaultVenue => VenueModel(
    id: 'hotel_main',
    name: 'Grand Meridian Hotel',
    floors: [
      FloorModel(floorId: 'B1', name: 'Basement', rooms: ['B101', 'B102', 'B103']),
      FloorModel(floorId: 'F1', name: 'Floor 1 — Lobby', rooms: ['101', '102', '103', '104', '105']),
      FloorModel(floorId: 'F2', name: 'Floor 2', rooms: ['201', '202', '203', '204', '205', '206']),
      FloorModel(floorId: 'F3', name: 'Floor 3', rooms: ['301', '302', '303', '304', '305', '306']),
      FloorModel(floorId: 'F4', name: 'Floor 4', rooms: ['401', '402', '403', '404', '405', '406', '407', '408', '409', '410', '411', '412']),
      FloorModel(floorId: 'RT', name: 'Rooftop', rooms: ['Pool', 'Restaurant', 'Bar']),
    ],
    emergencyContacts: {
      'fire': '101',
      'ambulance': '102',
      'police': '100',
      'reception': '0',
    },
  );
}

class FloorModel {
  final String floorId;
  final String name;
  final List<String> rooms;

  FloorModel({
    required this.floorId,
    required this.name,
    required this.rooms,
  });

  factory FloorModel.fromMap(Map<String, dynamic> data) {
    return FloorModel(
      floorId: data['floorId'] ?? '',
      name: data['name'] ?? '',
      rooms: List<String>.from(data['rooms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'floorId': floorId,
      'name': name,
      'rooms': rooms,
    };
  }
}
