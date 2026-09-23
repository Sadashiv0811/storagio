import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/services/s_authentication.dart';

/// PROVIDER
final loginVMProvider = ChangeNotifierProvider.autoDispose<LoginVM>(
  (ref) => LoginVM(ref),
);

/// VIEW MODEL
class LoginVM extends ChangeNotifier {
  final Ref ref;

  LoginVM(this.ref);

  /// Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// Form Key
  final formKey = GlobalKey<FormState>();

  /// Password Visibility
  bool obscurePassword = true;

  /// Loading State
  bool isLoading1 = false; // Email & Password
  bool isLoading2 = false; // Google

  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;

    return isValid;
  }

  /// Login with Email and Password
  Future<bool> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    logger.d("Email: $email");
    logger.d("Password: $password");

    errorMessage = null;

    try {
      isLoading1 = true;
      notifyListeners();

      // Check internet connection
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        errorMessage = "No internet connection";

        notifyListeners();

        return false;
      }

      // Firebase auth
      final auth = await ref.read(authenticationProvider.future);

      await auth.signInWithEmailAndPassword(email, password);

      logger.d("Login Success");

      return true;
    } catch (e) {
      logger.d("Login Error: $e");

      errorMessage = e.toString();

      notifyListeners();

      return false;
    } finally {
      isLoading1 = false;
      notifyListeners();
    }
  }

  /// Continue with Google
  Future<bool> continueWithGoogle(BuildContext context) async {
    errorMessage = null;
    try {
      isLoading2 = true;
      notifyListeners();

      // Check internet connection
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        errorMessage = "No internet connection";

        notifyListeners();

        return false;
      }

      // Firebase auth
      final auth = await ref.read(authenticationProvider.future);

      await auth.signInWithGoogle();

      logger.d("Google Login Success");

      return true;
    } catch (e) {
      logger.d("Google Login Error: $e");

      errorMessage = e.toString();

      notifyListeners();

      return false;
    } finally {
      isLoading2 = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
