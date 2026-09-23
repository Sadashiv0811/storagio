import 'package:storagio/core/constants/static_values.dart';

class MActivity {
  final int? localId; // SQLite primary key

  final String id; // Global UUID // Important for backup related work

  // Entity details
  final String entityId;
  final String entityName;

  // item / category / room
  final ActivityEntityType entityType;

  // added / updated / deleted / moved
  final ActivityActionType actionType;

  // Activity timestamp
  final DateTime createdAt;

  // Generic change tracking
  final String? fieldName;
  final String? oldValue;
  final String? newValue;

  // Local sync status
  final bool synced;

  MActivity({
    this.localId,
    required this.id,
    required this.entityId,
    required this.entityName,
    required this.entityType,
    required this.actionType,
    required this.createdAt,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.synced = false,
  });

  Map<String, dynamic> toMap({bool forFirebase = false}) {
    // Base data → common for both SQLite & Firebase
    final map = <String, dynamic>{
      'id': id, // Global UUID (used in both local & cloud)

      'entityId': entityId,
      'entityName': entityName,

      'entityType': entityType.name,
      'actionType': actionType.name,

      'createdAt': createdAt.millisecondsSinceEpoch,

      'fieldName': fieldName,
      'oldValue': oldValue,
      'newValue': newValue,
    };

    // Add local-only fields (ONLY for SQLite)
    if (!forFirebase) {
      map['localId'] = localId; // SQLite primary key
      map['synced'] = synced ? 1 : 0; // Sync flag (local state only)
    }

    return map;
  }

  factory MActivity.fromMap(Map<String, dynamic> map) {
    return MActivity(
      // Local-only fields (Does not exist in Firebase)
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      // Common fields (must exist)
      id: map['id'],

      entityId: map['entityId'],
      entityName: map['entityName'],

      entityType: ActivityEntityType.values.firstWhere(
        (e) => e.name == map['entityType'],
        orElse: () => ActivityEntityType.item,
      ),

      actionType: ActivityActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => ActivityActionType.updated,
      ),

      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),

      fieldName: map['fieldName'],
      oldValue: map['oldValue'],
      newValue: map['newValue'],
    );
  }

  MActivity copyWith({
    int? localId,
    String? id,

    String? entityId,
    String? entityName,

    ActivityEntityType? entityType,
    ActivityActionType? actionType,

    DateTime? createdAt,

    String? fieldName,
    String? oldValue,
    String? newValue,

    bool? synced,
  }) {
    return MActivity(
      localId: localId ?? this.localId,

      id: id ?? this.id,

      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,

      entityType: entityType ?? this.entityType,
      actionType: actionType ?? this.actionType,

      createdAt: createdAt ?? this.createdAt,

      fieldName: fieldName ?? this.fieldName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,

      synced: synced ?? this.synced,
    );
  }

  // ========================
  // HELPERS
  // ========================

  bool get isItem => entityType == ActivityEntityType.item;

  bool get isRoom => entityType == ActivityEntityType.room;
}
