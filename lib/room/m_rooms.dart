class MRoom {
  // Non user editable fields
  final int? localId; // SQLite primary key
  final String id; // Global UUID

  final bool synced;

  // User editable fields
  final String roomName;
  final String icon;
  final int color;

  MRoom({
    this.localId,
    required this.id,
    required this.roomName,
    required this.icon,
    required this.color,
    this.synced = false,
  });

  Map<String, dynamic> toMap({bool forFirebase = false}) {
    final map = <String, dynamic>{
      'id': id, // Global UUID
      'roomName': roomName,
      'icon': icon,
      'color': color,
    };

    // Add local-only fields (SQLite only)
    if (!forFirebase) {
      map['localId'] = localId; // SQLite primary key
      map['synced'] = synced ? 1 : 0; // Sync flag (local only)
    }

    return map;
  }

  factory MRoom.fromMap(Map<String, dynamic> map) {
    return MRoom(
      // Local-only (may be null when coming from Firebase)
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      // Core fields
      id: map['id'],
      roomName: map['roomName'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  MRoom copyWith({
    int? localId,
    String? id,
    String? roomName,
    String? icon,
    int? color,
    bool? synced,
  }) {
    return MRoom(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      synced: synced ?? this.synced,
    );
  }
}
