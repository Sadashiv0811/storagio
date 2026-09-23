import 'dart:ui';

import 'package:storagio/core/constants/static_values.dart';

class MItem {
  final int? localId; // SQLite primary key
  final String id; // Global UUID
  final String categoryName;
  final String? roomId; // reference UUID

  final bool synced;

  final String name;

  final double? quantity;
  final double? lowStockLimit;
  final String? unit;

  final int? lastPaymentAmount;

  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;

  final String? notes;
  final String? imagePath;

  MItem({
    this.localId,
    required this.id,
    required this.name,
    required this.categoryName,
    this.roomId,
    this.quantity,
    this.lowStockLimit,
    this.unit,
    this.purchaseDate,
    this.warrantyExpiry,
    this.notes,
    this.imagePath,
    this.lastPaymentAmount,
    this.synced = false,
  });

  /// Converts Item model to Map for storage.
  /// By default:
  /// - Returns SQLite-compatible map (includes localId, synced)
  /// If [forFirebase] is true:
  /// - Excludes local-only fields (localId, synced)
  Map<String, dynamic> toMap({bool forFirebase = false}) {
    final map = <String, dynamic>{
      'id': id, // Global UUID
      'name': name,
      'categoryName': categoryName,
      'quantity': quantity,
      'lowStockLimit': lowStockLimit,
      'unit': unit,
      'roomId': roomId,
      'lastPaymentAmount': lastPaymentAmount,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'notes': notes,
      'imagePath': imagePath,
    };

    // Add local-only fields (SQLite only)
    if (!forFirebase) {
      map['localId'] = localId; // SQLite primary key
      map['synced'] = synced ? 1 : 0; // Sync flag (local only)
    }

    return map;
  }

  factory MItem.fromMap(Map<String, dynamic> map) {
    return MItem(
      // Local-only fields (may be null from Firebase)
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      // Core fields
      id: map['id'],
      name: map['name'],
      categoryName: map['categoryName'],

      lastPaymentAmount: map['lastPaymentAmount'],

      quantity: (map['quantity'] as num?)?.toDouble(),
      lowStockLimit: (map['lowStockLimit'] as num?)?.toDouble(),
      unit: map['unit'] ?? ItemUnit.unit.name,

      roomId: map['roomId'],

      purchaseDate: map['purchaseDate'] != null
          ? DateTime.parse(map['purchaseDate'])
          : null,
      warrantyExpiry: map['warrantyExpiry'] != null
          ? DateTime.parse(map['warrantyExpiry'])
          : null,

      notes: map['notes'],
      imagePath: map['imagePath'],
    );
  }

  MItem copyWith({
    int? localId,
    String? id,
    String? name,
    String? categoryName,

    double? Function()? quantity,
    double? Function()? lowStockLimit,

    String? Function()? unit,
    String? Function()? roomId,

    int? Function()? lastPaymentAmount,

    DateTime? Function()? purchaseDate,
    DateTime? Function()? warrantyExpiry,

    String? Function()? notes,
    String? Function()? imagePath,
    bool? synced,
  }) {
    return MItem(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,

      quantity: quantity != null ? quantity() : this.quantity,
      lowStockLimit: lowStockLimit != null
          ? lowStockLimit()
          : this.lowStockLimit,

      unit: unit != null ? unit() : this.unit,
      roomId: roomId != null ? roomId() : this.roomId,

      lastPaymentAmount: lastPaymentAmount != null
          ? lastPaymentAmount()
          : this.lastPaymentAmount,

      purchaseDate: purchaseDate != null ? purchaseDate() : this.purchaseDate,

      warrantyExpiry: warrantyExpiry != null
          ? warrantyExpiry()
          : this.warrantyExpiry,

      notes: notes != null ? notes() : this.notes,
      imagePath: imagePath != null ? imagePath() : this.imagePath,

      synced: synced ?? this.synced,
    );
  }

  /// STOCK STATUS HELPER
  StockStatus getStockStatus() {
    final qty = quantity ?? 0;
    final limit = lowStockLimit ?? 0;

    if (qty == 0) {
      return StockStatus.empty;
    }

    if (qty < limit) {
      return StockStatus.low;
    }

    return StockStatus.good;
  }
}

class StockInfo {
  final Color color;
  final String label;
  StockInfo({required this.color, required this.label});
}

StockInfo getStockInfo(StockStatus stockStatus) {
  switch (stockStatus) {
    case StockStatus.empty:
      return StockInfo(color: stockColors[0], label: "EMPTY");

    case StockStatus.low:
      return StockInfo(color: stockColors[1], label: "LOW");

    case StockStatus.good:
      return StockInfo(color: stockColors[2], label: "GOOD");
  }
}
