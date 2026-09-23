import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/services/s_internet.dart';
import 'package:storagio/core/utils/common.dart';

final reportBugViewModelProvider =
    NotifierProvider.autoDispose<ReportBugViewModel, ReportBugState>(
      ReportBugViewModel.new,
    );

class ReportBugState {
  const ReportBugState({this.isLoading = false});

  final bool isLoading;

  ReportBugState copyWith({bool? isLoading}) {
    return ReportBugState(isLoading: isLoading ?? this.isLoading);
  }
}

class ReportBugViewModel extends Notifier<ReportBugState> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();
  final messageNode = FocusNode();

  @override
  @override
  ReportBugState build() {
    ref.onDispose(_disposeControllers);
    return const ReportBugState();
  }

  void _disposeControllers() {
    _clearControllers();
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
  }

  void _clearControllers() {
    nameController.clear();
    emailController.clear();
    messageController.clear();
  }

  Future<bool> submit() async {
    if (!formKey.currentState!.validate()) return false;

    state = state.copyWith(isLoading: true);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final message = messageController.text.trim();

    logger.d('''
      Name: $name
      Email: $email
      Message: $message''');

    messageNode.unfocus();

    try {
      final hasInternet = await ref.read(internetServiceProvider).isConnected();

      if (!hasInternet) {
        showSnackBar("No internet connection", backgroundColor: Colors.red);
        return false;
      }

      final user = FirebaseAuth.instance.currentUser;

      // Save to Firestore
      await FirebaseFirestore.instance.collection('bug_reports').add({
        'userId': user?.uid,
        'isGuest': user == null,
        'name': name,
        'email': email,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });

      showSnackBar("Message submitted successfully.");

      formKey.currentState?.reset();

      _clearControllers();

      return true;
    } catch (e, s) {
      logger.e("Failed to submit", error: e, stackTrace: s);

      showSnackBar("Something went wrong.", backgroundColor: Colors.red);

      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
