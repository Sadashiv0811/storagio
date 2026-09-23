import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/core/utils/common.dart';

enum ProgressStatus { normal, warning, critical, expired }

class TimeProgress {
  final double progress;
  final int remainingDays;
  final bool expired;
  final double remainingPercentage;
  final ProgressStatus status;

  TimeProgress({
    required this.progress,
    required this.remainingDays,
    required this.expired,
    required this.remainingPercentage,
    required this.status,
  });
}

class WarrantyCard extends StatelessWidget {
  final DateTime? purchaseDate;
  final DateTime warrantyExpiry;
  final String categoryName;

  const WarrantyCard({
    super.key,
    required this.purchaseDate,
    required this.warrantyExpiry,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool isBills = categoryName == CategoryNames.billsRecharges;
    TimeProgress? result;

    if (purchaseDate != null) {
      result = calculateTimeProgress(
        startDate: purchaseDate!,
        endDate: warrantyExpiry,
      );
    }

    String title = isBills ? "DUE DATE" : 'WARRANTY / EXPIRY DATE';

    int remainingDays = 0;
    double progress = 0.0, validityRemaining = 0.0;
    Color progressColor = Colors.green;
    bool isExpired = false;
    String expiryText = "";

    if (result != null) {
      remainingDays = result.remainingDays;
      validityRemaining = result.remainingPercentage;
      progress = result.progress;
      isExpired = result.expired;
      progressColor = getColor(result.status);
      expiryText = getExpiryText(isExpired, isBills, remainingDays);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CLabel(text: title),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  isBills ? Icons.payments : Icons.verified_user,
                  color: isExpired ? Colors.red : Colors.green,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    DateFormat("dd MMM yyyy").format(warrantyExpiry),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            if (purchaseDate != null) ...[
              const SizedBox(height: 9),
              Text(
                expiryText,
                style: TextStyle(
                  fontSize: 14,
                  color: isExpired
                      ? Colors.red
                      : isDark
                      ? Colors.white54
                      : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),
              Tooltip(
                message: isBills
                    ? "${validityRemaining.toStringAsFixed(1)}% recharge validity remaining"
                    : "${validityRemaining.toStringAsFixed(1)}% warranty remaining",

                triggerMode: TooltipTriggerMode.longPress,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

TimeProgress? calculateTimeProgress({
  required DateTime startDate,
  required DateTime endDate,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Include the entire day of expiry that is 24hrs
  final effectiveEndDate = DateTime(
    endDate.year,
    endDate.month,
    endDate.day,
    23,
    59,
    59,
    999,
  );

  final isExpired = endDate.isBefore(today);

  final totalDuration = effectiveEndDate.difference(startDate).inSeconds;

  if (totalDuration <= 0) return null;

  final elapsedDuration = now.difference(startDate).inSeconds;

  double usedPercentage = elapsedDuration / totalDuration;
  usedPercentage = usedPercentage.clamp(0.0, 1.0);

  final progress = 1 - usedPercentage;
  final remainingPercentage = progress * 100;

  final remainingDays = effectiveEndDate.difference(now).inDays;

  ProgressStatus status;

  if (isExpired) {
    status = ProgressStatus.expired;
  } else {
    if (progress <= 0.10) {
      status = ProgressStatus.critical;
    } else if (progress <= 0.30) {
      status = ProgressStatus.warning;
    } else {
      status = ProgressStatus.normal;
    }
  }

  return TimeProgress(
    progress: progress,
    remainingDays: remainingDays,
    expired: isExpired,
    remainingPercentage: remainingPercentage,
    status: status,
  );
}

Color getColor(ProgressStatus status) {
  switch (status) {
    case ProgressStatus.normal:
      return const Color(0xFF63FFDA);

    case ProgressStatus.warning:
      return Colors.orange;

    case ProgressStatus.critical:
      return Colors.red;

    case ProgressStatus.expired:
      return Colors.red.shade900;
  }
}

String getExpiryText(bool isExpired, bool isBills, int remainingDays) {
  if (isExpired) {
    return isBills ? "Payment overdue" : "Expired";
  }

  if (remainingDays > 1) {
    return "$remainingDays days remaining";
  }

  if (remainingDays == 1) {
    return "1 day remaining";
  }

  return isBills ? "Due today" : "Expires today";
}
