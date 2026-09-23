class MDeletedRecord {
  final int? localId;

  final String recordId; // deleted record id
  final String collectionName; // deleted record table name

  final DateTime deletedAt;

  MDeletedRecord({
    this.localId,
    required this.recordId,
    required this.collectionName,
    required this.deletedAt,
  });

  // ========================
  // TO MAP
  // ========================

  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'recordId': recordId,
      'collectionName': collectionName,
      'deletedAt': deletedAt.millisecondsSinceEpoch,
    };
  }

  // ========================
  // FROM MAP
  // ========================

  factory MDeletedRecord.fromMap(Map<String, dynamic> map) {
    final rawDeletedAt = map['deletedAt'];
    final deletedAtMillis = rawDeletedAt is int
        ? rawDeletedAt
        : int.tryParse(rawDeletedAt?.toString() ?? '') ?? 0;

    return MDeletedRecord(
      localId: map['localId'],
      recordId: map['recordId'],
      collectionName: map['collectionName'],
      deletedAt: DateTime.fromMillisecondsSinceEpoch(deletedAtMillis),
    );
  }

  // ========================
  // COPY WITH
  // ========================

  MDeletedRecord copyWith({
    int? localId,
    String? recordId,
    String? collectionName,
    DateTime? deletedAt,
  }) {
    return MDeletedRecord(
      localId: localId ?? this.localId,
      recordId: recordId ?? this.recordId,
      collectionName: collectionName ?? this.collectionName,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
