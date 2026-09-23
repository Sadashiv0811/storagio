import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_button/sign_button.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/core/constants/routes.dart';
import 'package:storagio/core/theme/theme.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/user/viewmodels/vm_login.dart';
import 'package:storagio/user/vm_user.dart';

class VLogin extends ConsumerWidget {
  const VLogin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(loginVMProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: vm.formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                /// APP ICON
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'res/icon/splash_icon_c.png',
                      width: MediaQuery.sizeOf(context).width * 0.35,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// TITLE
                Text(
                  'Storagio',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.backgroundLight
                        : const Color(0xFF1A1C1E),
                  ),
                ),

                Text(
                  'SMART HOME INVENTORY MANAGER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.borderLight
                        : const Color(0xFF3F474E),
                  ),
                ),

                const SizedBox(height: 25),

                /// LOGIN CARD
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.backgroundLight
                                : const Color(0xFF1A1C1E),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Log in to manage your spaces',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade200
                                : const Color(0xFF74777F),
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// EMAIL
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: CLabel(text: 'EMAIL ADDRESS', requiredField: true,),
                        ),

                        CTextFormField(
                          controller: vm.emailController,
                          hint: 'name@example.com',
                          prefixIconData: Icons.email_outlined,
                          validator: AppValidators.email,
                        ),

                        const SizedBox(height: 24),

                        /// PASSWORD LABEL
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [CLabel(text: 'PASSWORD', requiredField: true,)],
                        ),

                        /// PASSWORD FIELD
                        PasswordTextField(
                          controller: vm.passwordController,
                          prefixIcon: Icons.lock_outlined,
                          obscureText: vm.obscurePassword,
                          toggleVisibility: vm.togglePasswordVisibility,
                          validator: AppValidators.strongPassword,
                        ),

                        const SizedBox(height: 32),

                        /// LOGIN BUTTON
                        Visibility(
                          visible: !vm.isLoading2,
                          child: vm.isLoading1
                              ? CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: CPositiveButton(
                                    text: 'Log In',
                                    callback: () async {
                                      FocusScope.of(context).unfocus();
                                      // Used to remove focus from the currently selected input field.

                                      /// Validate Inputs
                                      final isValid = vm.validateForm();
                                      if (!isValid) return;

                                      final success = await vm.login(context);

                                      if (!context.mounted) return;

                                      // =========================
                                      // LOGIN FAILED
                                      // =========================

                                      if (!success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              vm.errorMessage ?? "Login failed",
                                            ),
                                          ),
                                        );

                                        return;
                                      }

                                      // =========================
                                      // LOGIN SUCCESS
                                      // =========================

                                      if (success) {
                                        await ref
                                            .read(userProvider.notifier)
                                            .refresh();

                                        if (!context.mounted) return;

                                        Navigator.pop(context, RegisterStatus.login.name);
                                      }
                                    },
                                    iconData: Icons.login,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// GOOGLE LOGIN
                Visibility(
                  visible: !vm.isLoading1,
                  child: vm.isLoading2
                      ? CircularProgressIndicator()
                      : SignInButton.mini(
                          btnColor: Colors.white,
                          elevation: 4,
                          buttonSize: ButtonSize.small,
                          onPressed: () async {
                            final success = await ref
                                .read(loginVMProvider)
                                .continueWithGoogle(context);

                            if (!context.mounted) return;

                            // =========================
                            // LOGIN FAILED
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

                            if (success && context.mounted) {
                              await ref.read(userProvider.notifier).refresh();

                              if (!context.mounted) return;

                              Navigator.pop(context, RegisterStatus.login.name);
                            }
                          },
                          buttonType: ButtonType.google,
                          padding: 10,
                        ),
                ),

                const SizedBox(height: 25),

                /// FOOTER
                Visibility(visible: !vm.isLoading1 && !vm.isLoading2,
                  child: FooterSection(
                    message: "Don't have an account? ",
                    callback: () {
                      Navigator.pushNamed(context, AppRoutes.signup);
                    },
                    btnText: "Sign Up",
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
