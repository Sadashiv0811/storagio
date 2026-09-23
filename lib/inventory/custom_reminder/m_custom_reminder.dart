class CustomReminder {
  final int? localId;
  final String id;

  final String itemId;

  final String content;
  final DateTime startDate;
  final int intervalDays;
  final bool isActive;

  final bool synced;

  CustomReminder({
    this.localId,
    required this.id,
    required this.itemId,
    required this.content,
    required this.startDate,
    required this.intervalDays,
    this.isActive = true,
    this.synced = false,
  });

  // Convert to Map for SQLite insert/update
  Map<String, dynamic> toMap({bool forFirebase = false}) {
    final map = <String, dynamic>{
      'id': id, // Global UUID
      'itemId': itemId,
      'content': content,
      'startDate': startDate.toIso8601String(),
      'intervalDays': intervalDays,
      'isActive': forFirebase ? isActive : (isActive ? 1 : 0),
    };

    // Local-only fields (SQLite)
    if (!forFirebase) {
      map['localId'] = localId; // SQLite primary key
      map['synced'] = synced ? 1 : 0; // Sync flag
    }

    return map;
  }

  // Create Object from SQLite Map
  factory CustomReminder.fromMap(Map<String, dynamic> map) {
    return CustomReminder(
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      id: map['id'],
      itemId: map['itemId'],
      content: map['content'],
      startDate: DateTime.parse(map['startDate']),
      intervalDays: map['intervalDays'],
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }

  CustomReminder copyWith({
    int? localId,
    String? id,
    String? itemId,
    String? content,
    DateTime? startDate,
    int? intervalDays,
    bool? isActive,
    bool? synced,
  }) {
    return CustomReminder(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      content: content ?? this.content,
      startDate: startDate ?? this.startDate,
      intervalDays: intervalDays ?? this.intervalDays,
      isActive: isActive ?? this.isActive,
      synced: synced ?? this.synced,
    );
  }
}
