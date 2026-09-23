import 'package:storagio/core/constants/static_values.dart';

enum LoginMethod { emailPassword, google }

class MUser {
  // Non editable fields
  final int? localId; // SQLite primary key
  final String id; // Global UUID
  final String email;
  final String? password; // password hash
  final LoginMethod loginMethod; // email, google, apple, etc.
  final bool synced;

  // Editable fields
  final String fullName;
  final String? profileImage;

  final int lowStockLimit;

  MUser({
    this.localId,
    required this.id,
    required this.email,
    this.password,
    required this.loginMethod,
    this.synced = false,
    required this.fullName,
    this.profileImage,
    this.lowStockLimit = 4,
  });

  /// Converts User model to Map for storage.
  /// By default:
  /// - Returns SQLite-compatible map (includes localId, synced, password)
  /// If [forFirebase] is true:
  /// - Excludes local-only fields (localId, synced)
  /// - Excludes sensitive data (password)
  Map<String, dynamic> toMap({bool forFirebase = false}) {
    final map = <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'loginMethod': loginMethod.name,
      'profileImage': profileImage,
      'lowStockLimit': lowStockLimit,
    };

    // Add local-only fields
    if (!forFirebase) {
      map['localId'] = localId;
      map['synced'] = synced ? 1 : 0;

      // Only store locally (and preferably hashed)
      map['password'] = password;
    }

    return map;
  }

  factory MUser.fromMap(Map<String, dynamic> map) {
    return MUser(
      // Local-only (nullable when coming from Firebase)
      localId: map['localId'],
      synced: (map['synced'] ?? 0) == 1,

      // Core fields
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],

      password: map['password'] ?? '', // may be null from Firebase

      loginMethod: LoginMethod.values.firstWhere(
        (e) => e.name == map['loginMethod'],
        orElse: () => LoginMethod.emailPassword,
      ),

      profileImage: map['profileImage'] ?? '',

      lowStockLimit: map['lowStockLimit'] ?? 4,
    );
  }

  MUser copyWith({
    int? localId,
    String? id,
    String? fullName,
    String? email,
    LoginMethod? loginMethod,
    String? password,
    String? profileImage,
    int? lowStockLimit,
    bool? synced,
  }) {
    return MUser(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      loginMethod: loginMethod ?? this.loginMethod,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,

      lowStockLimit: lowStockLimit ?? this.lowStockLimit,

      synced: synced ?? this.synced,
    );
  }

  void log(bool isFirebase) {
    logger.d('========== MUser ==========');

    logger.d(isFirebase ? 'Firebase user data' : 'SQLite user data');

    if (!isFirebase) {
      logger.d("""
        localId: $localId
        synced: $synced
        password: $password
      """);
    }

    logger.d("""
      id: $id
      fullName: $fullName
      email: $email
      loginMethod: ${loginMethod.name}
      profileImage: $profileImage
      lowStockLimit: $lowStockLimit
      ===========================
    """);
  }
}
