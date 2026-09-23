import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/services/s_authentication.dart';

final signupVMProvider = ChangeNotifierProvider.autoDispose<SignupViewModel>((
  ref,
) {
  return SignupViewModel(ref);
});

class SignupViewModel extends ChangeNotifier {
  final Ref ref;

  SignupViewModel(this.ref);

  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool termsAccepted = false;
  bool showTermsError = false;

  /// Loading State
  bool isLoading1 = false; // Email & Password
  bool isLoading2 = false; // Google

  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleTerms(bool? value) {
    termsAccepted = value ?? false;

    /// Hide error when accepted
    if (termsAccepted) {
      showTermsError = false;
    }

    notifyListeners();
  }

  bool validateForm() {
    final isValid = formKey.currentState?.validate() ?? false;

    /// Show error only after button click
    if (!termsAccepted) {
      showTermsError = true;
      notifyListeners();
      return false;
    }

    showTermsError = false;

    return isValid;
  }

  /// Signup with Email and Password
  Future<bool> signUp(BuildContext context) async {
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

      await auth.createUserWithEmailAndPassword(
        fullNameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      logger.d("Signup Success");

      return true;
    } catch (e) {
      logger.d("Signup Error: $e");

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

      logger.d("Google Auth Success");

      return true;
    } catch (e) {
      logger.d("Google Auth Error: $e");

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
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
