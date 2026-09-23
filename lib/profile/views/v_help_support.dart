import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storagio/core/utils/common.dart';
import 'package:storagio/core/utils/input_validators.dart';
import 'package:storagio/profile/viewmodels/vm_report_bug.dart';

enum HelpSupportType { faq, contact, report, guide }

// Stateless Widgets
class VHelpSupportDetails extends StatelessWidget {
  final HelpSupportType type;
  const VHelpSupportDetails({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBarText(switch (type) {
          HelpSupportType.faq => 'FAQs',
          HelpSupportType.report => 'Report Bug',
          HelpSupportType.guide => 'User Guide',
          HelpSupportType.contact => 'Contact Support',
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 20),
          child: switch (type) {
            HelpSupportType.faq => const VFAQs(),
            HelpSupportType.report => const VReportBug(),
            HelpSupportType.guide => const VUserGuide(),
            HelpSupportType.contact => const VContactSupport(),
          },
        ),
      ),
    );
  }
}

class VUserGuide extends StatelessWidget {
  const VUserGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderSection(
          title: "How to Use Storagio",
          message:
              "Learn how to add items, organize rooms, track inventory, and use Storagio efficiently.",
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Storagio helps you organize your household belongings by grouping them into rooms and categories. '
                    'Start by creating your rooms, then add items with details such as quantity, purchase information, '
                    'expiry dates, warranties, bills, and images to keep everything organized in one place.',
                    style: TextStyle(height: 1.5),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Use the search and filter options to quickly locate any item. Enable cloud sync from the Settings '
                    'page to back up your inventory and restore it whenever you sign in on another device. Keeping your '
                    'data synced ensures your inventory is always safe and up to date.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VContactSupport extends StatelessWidget {
  const VContactSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderSection(
          title: 'Contact Support',
          message:
              "Need additional help? Reach out to our support team for assistance with your Storagio account and features.",
        ),
        const SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.email_outlined),
                    SizedBox(width: 12),
                    Text('support@storagio.app'),
                  ],
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Icon(Icons.phone_outlined),
                    SizedBox(width: 12),
                    Text('+91 98765 43210'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VFAQs extends StatelessWidget {
  const VFAQs({super.key});

  static const List<({String question, String answer})> faqs = [
    (
      question: 'How do I add a new item?',
      answer:
          'Tap the "+" button, enter the item details, choose a room and category, then tap Save.',
    ),
    (
      question: 'Can I back up my data?',
      answer:
          'Yes. Sign in to your account and use the Sync option in Settings to securely back up your data to the cloud.',
    ),
    (
      question: 'Can I use the app without an internet connection?',
      answer:
          'Yes. All your inventory data is stored locally. Internet is only required for syncing and restoring backups.',
    ),
    (
      question: 'How can I restore my data?',
      answer:
          'Sign in using the same account and use the Sync feature to download your backed-up inventory.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const HeaderSection(
          title: 'Frequently Asked Questions',
          message:
              "Find answers to common questions about managing items, rooms, categories, backups, and restoring data.",
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(14),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];

                return ExpansionTile(
                  iconColor: isDark
                      ? const Color.fromARGB(255, 0, 234, 255)
                      : const Color(0xFF4C84FF),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  title: Text(
                    faq.question,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [Text(faq.answer, style: textTheme.bodyMedium)],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Consumer Widgets
class VReportBug extends ConsumerWidget {
  const VReportBug({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportBugViewModelProvider);
    final vm = ref.read(reportBugViewModelProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        children: [
          const HeaderSection(
            title: "Report Bug",
            message:
                "Found an issue or unexpected behavior? Report bugs so we can improve app stability and performance.",
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: vm.formKey,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      controller: vm.nameController,
                      decoration: getInputDecoration(
                        context: context,
                        label: "Full Name",
                        prefixIcon: Icons.person_outline,
                      ),
                      validator: AppValidators.fullName,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      controller: vm.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: getInputDecoration(
                        context: context,
                        label: "Email Address",
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: AppValidators.email,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      cursorColor: Theme.of(context).colorScheme.secondary,
                      focusNode: vm.messageNode,
                      controller: vm.messageController,
                      maxLines: 10,
                      decoration: getInputDecoration(
                        context: context,
                        label: "Message",
                      ),
                      validator: AppValidators.message,
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: state.isLoading ? null : vm.submit,
                      icon: state.isLoading ? null : const Icon(Icons.send),
                      label: Text(state.isLoading ? "Submitting..." : "Submit"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration getInputDecoration({
    required BuildContext context,
    required String label,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
          width: 2,
        ),
      ),
      labelStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
