import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/user/m_user.dart';
import 'package:storagio/user/r_user.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

final authenticationProvider = FutureProvider<Authentication>((ref) async {
  final userRepository = await ref.watch(userRepositoryProvider.future);

  return Authentication(userRepository);
});

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Repository that handles ALL local database (SQLite) operations
  final UserRepository userRepository;

  Authentication(this.userRepository);

  // ######################### Email and Password #########################
  // ========================
  // SIGN UP
  // ========================
  Future<void> createUserWithEmailAndPassword(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      // Firebase Authentication (remote)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw AuthException(
          "Could not retrieve user profile. Please try again.",
        );
      }

      // Use Firebase UID (IMPORTANT)
      final uid = firebaseUser.uid;

      // Create LOCAL user model (for SQLite storage)
      final user = MUser(
        id: uid, // Firebase UID
        fullName: fullName,
        email: email,
        password: PasswordUtils.hashPassword(password),
        loginMethod: LoginMethod.emailPassword,
        profileImage: "",
        lowStockLimit: 4,
        synced: true,
      );

      // =========================
      // SAVE TO FIRESTORE
      // =========================
      await _firestore
          .collection('users')
          .doc(uid)
          .set(user.toMap(forFirebase: true));

      // =========================
      // SAVE TO SQLITE
      // =========================
      // INSERT INTO SQLite DATABASE
      // Internally calls:
      // db.insert('users', user.toMap())
      // - Stores user locally for offline access
      // - Uses ConflictAlgorithm.replace (so duplicate overwrites)
      await userRepository.insertUser(user);

      // At this point:
      // Firebase has the user (cloud)
      // SQLite has the user (local cache)

      logger.d("Registration Successful");
    } on FirebaseAuthException catch (e) {
      logger.d("Registration error: ${e.message}");
      throw AuthException(_handleFirebaseAuthError(e));
    } on SocketException catch (_) {
      throw AuthException(
        "Network error. Please check your internet connection.",
      );
    } catch (e) {
      logger.d("Unexpected error: $e");
      throw AuthException("Something went wrong. Please try again later.");
    }
  }

  // ========================
  // LOGIN
  // ========================
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Firebase login (remote authentication)
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw AuthException("Login failed. Please try again.");
      }

      final uid = firebaseUser.uid;

      // =========================
      // FETCH FROM FIRESTORE
      // =========================

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw AuthException("User data not found");
      }

      final user = MUser.fromMap(doc.data()!);

      // =========================
      // SAVE TO SQLITE
      // =========================

      await userRepository.insertUser(user);

      logger.d("Login Successful");
      // Firebase UID = Single Source of Truth
    } on FirebaseAuthException catch (e) {
      logger.d("Login error: ${e.message}");
      throw AuthException(_handleFirebaseAuthError(e));
    } on SocketException catch (_) {
      throw AuthException(
        "Network error. Please check your internet connection.",
      );
    } catch (e) {
      logger.d("Unexpected error: $e");
      throw AuthException("Something went wrong. Please try again later.");
    }
  }

  // ######################### Google Sign In #########################
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize once
      await googleSignIn.initialize();

      // Google account picker
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Required scopes
      const scopes = ['email', 'profile'];

      // Authorization (NEW API)
      final authorization = await googleUser.authorizationClient
          .authorizeScopes(scopes);

      // Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: authorization.accessToken,
      );

      // Firebase login
      final userCredential = await _auth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw AuthException("Failed to sync with Google. Please try again.");
      }

      final uid = firebaseUser.uid;

      final docRef = _firestore.collection('users').doc(uid);

      final doc = await docRef.get();

      MUser user;

      // New user
      if (!doc.exists) {
        user = MUser(
          id: uid,
          fullName: firebaseUser.displayName ?? "",
          email: firebaseUser.email ?? "",
          password: "",
          loginMethod: LoginMethod.google,
          profileImage: firebaseUser.photoURL ?? "",
          lowStockLimit: 4,
          synced: true,
        );

        await docRef.set(user.toMap(forFirebase: true));
      } else {
        user = MUser.fromMap(doc.data()!);
      }

      // Save locally
      await userRepository.insertUser(user);

      logger.d("Google Sign In Successful");
    } on FirebaseAuthException catch (e) {
      logger.d("Sign in error: ${e.message}");
      throw AuthException(_handleFirebaseAuthError(e));
    } on SocketException catch (_) {
      throw AuthException(
        "Network error. Please check your internet connection.",
      );
    } catch (e) {
      logger.d("Unexpected error: $e");
      // Catch platform-specific cancellations if the SDK throws instead of returning null
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('canceled')) {
        throw AuthException("Sign-in cancelled.");
      }

      throw AuthException("Google Sign-In failed. Please try again.");
    }
  }

  // ========================
  // LOGOUT
  // ========================
  Future<void> logout() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.signOut();

    // Sign out from Firebase (remote session ends)
    await _auth.signOut();

    // DELETE FROM users;
    await userRepository.clearAll();

    // Result:
    // No local user remains
  
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      // Network / Cloud issues
      case 'network-request-failed':
        return "No internet connection. Please check your network and try again.";

      // Login issues
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Invalid email or password. Please try again.";
      case 'user-disabled':
        return "This account has been disabled. Please contact support.";

      // Registration issues
      case 'email-already-in-use':
        return "This email address is already registered. Try logging in.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Your password is too weak. Please use a stronger password.";

      // Google Sign in / Credential issues
      case 'account-exists-with-different-credential':
        return "An account already exists with this email but using a different sign-in provider.";
      case 'operation-not-allowed':
        return "This sign-in method is currently disabled.";

      // Default fallback
      default:
        return e.message ?? "Authentication failed. Please try again.";
    }
  }
}

// =========================
// HASH PASSWORD
// =========================
class PasswordUtils {
  static String hashPassword(String password) {
    // Convert password string to bytes
    final bytes = utf8.encode(password);

    // Generate SHA-256 hash
    final hashed = sha256.convert(bytes);

    // Return hash as string
    return hashed.toString();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message; // No "Exception: " prefix!
}
