class MCategory {
  // Non user editable fields
  final int? localId; // SQLite primary key (auto increment)
  final String id; // Global UUID (for Firebase + sync)

  final bool synced; // sync tracking

  // User editable fields
  final String categoryName;
  final String icon; // store icon identifier (e.g., 'chair', 'tools')
  final int color; // store color as ARGB int (Flutter Color.value)

  MCategory({
    this.localId,
    required this.id,
    required this.categoryName,
    required this.icon,
    required this.color,
    this.synced = false,
  });

  Map<String, dynamic> toMap({bool forFirebase = false}) {
    final map = <String, dynamic>{
      'id': id, // Global UUID (used everywhere)
      'categoryName': categoryName,
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

  factory MCategory.fromMap(Map<String, dynamic> map) {
    return MCategory(
      // Local-only (may be null from Firebase)
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      // Core fields
      id: map['id'],
      categoryName: map['categoryName'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  MCategory copyWith({
    int? localId,
    String? id,
    String? categoryName,
    String? icon,
    int? color,
    bool? synced,
  }) {
    return MCategory(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      synced: synced ?? this.synced,
    );
  }
}
