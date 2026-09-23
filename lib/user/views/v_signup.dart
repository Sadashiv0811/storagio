import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_button/sign_button.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/user/viewmodels/vm_signup.dart';
import 'package:storagio/user/vm_user.dart';

//Consumer Widgets
class VSignup extends ConsumerWidget {
  const VSignup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(signupVMProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              SizedBox(height: 30),
              
              _HeaderSection(),
              
              SizedBox(height: 20),
              
              SignupForm(),
              
              SizedBox(height: 20),
              
              Visibility(
                visible: !vm.isLoading1,
                child: vm.isLoading2
                    ? CircularProgressIndicator()
                    : SignInButton.mini(
                        btnColor: Colors.white,
                        elevation: 4,
                        buttonSize: ButtonSize.small,
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          // Used to remove focus from the currently selected input field.

                          final success = await vm.continueWithGoogle(context);

                          if (!context.mounted) return;

                          // =========================
                          // FAILED
                          // =========================
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  vm.errorMessage ??
                                      "Google authentication failed",
                                ),
                              ),
                            );

                            return;
                          }

                          // =========================
                          // SUCCESS
                          // =========================
                          if (success) {
                            await ref.read(userProvider.notifier).refresh();

                            if (!context.mounted) return;

                            Navigator.popUntil(
                              context,
                              ModalRoute.withName(AppRoutes.home),
                            );
                          }
                        },
                        buttonType: ButtonType.google,
                        padding: 10,
                      ),
              ),
              
              SizedBox(height: 20),
              
              Visibility(
                visible: !vm.isLoading1 && !vm.isLoading2,
                child: FooterSection(
                  message: "Already have an account? ",
                  btnText: "Log In",
                  callback: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupForm extends ConsumerWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(signupVMProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: vm.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FULL NAME
              CLabel(text: 'FULL NAME', requiredField: true),

              CTextFormField(
                controller: vm.fullNameController,
                hint: 'John Doe',
                prefixIconData: Icons.person_outline,
                validator: AppValidators.fullName,
              ),

              const SizedBox(height: 20),

              /// EMAIL
              CLabel(text: 'EMAIL ADDRESS', requiredField: true),

              CTextFormField(
                controller: vm.emailController,
                hint: 'john@example.com',
                prefixIconData: Icons.email_outlined,
                validator: AppValidators.email,
              ),

              const SizedBox(height: 20),

              /// PASSWORD
              CLabel(text: 'PASSWORD', requiredField: true),

              PasswordTextField(
                controller: vm.passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: vm.obscurePassword,
                toggleVisibility: vm.togglePasswordVisibility,
                validator: AppValidators.strongPassword,
              ),

              const SizedBox(height: 20),

              /// TERMS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: vm.termsAccepted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onChanged: vm.toggleTerms,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'By signing up, you agree to our ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade200
                              : const Color(0xFF444444),
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF005BAA),
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const TextSpan(text: ' and '),

                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF005BAA),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (vm.showTermsError)
                Center(
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Please accept Terms & Conditions",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              /// SIGN UP BUTTON
              Center(
                child: Visibility(
                  visible: !vm.isLoading2,
                  child: vm.isLoading1
                      ? CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: CPositiveButton(
                            text: 'Sign Up',
                            iconData: Icons.login,
                            callback: () async {
                              FocusScope.of(context).unfocus();
                              // Used to remove focus from the currently selected input field.

                              /// Validate Inputs
                              final isValid = vm.validateForm();
                              if (!isValid) return;

                              final success = await vm.signUp(context);

                              if (!context.mounted) return;

                              // =========================
                              // FAILED
                              // =========================

                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      vm.errorMessage ?? "Sign Up failed",
                                    ),
                                  ),
                                );

                                return;
                              }

                              // =========================
                              // SUCCESS
                              // =========================

                              if (success) {
                                await ref.read(userProvider.notifier).refresh();

                                if (!context.mounted) return;

                                Navigator.popUntil(
                                  context,
                                  ModalRoute.withName(AppRoutes.home),
                                );
                              }
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateless Widgets
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'res/icon/splash_icon_c.png',
            width: MediaQuery.sizeOf(context).width * 0.35,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Storagio',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Start organizing your home today',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
