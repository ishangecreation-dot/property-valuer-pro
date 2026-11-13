import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/entitlement_service.dart';

class MonthlyLimitReachedDialog extends StatefulWidget {
  final VoidCallback? onPaidUnlocked;

  const MonthlyLimitReachedDialog({
    Key? key,
    this.onPaidUnlocked,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {VoidCallback? onPaidUnlocked}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MonthlyLimitReachedDialog(onPaidUnlocked: onPaidUnlocked),
    );
  }

  @override
  State<MonthlyLimitReachedDialog> createState() => _MonthlyLimitReachedDialogState();
}

class _MonthlyLimitReachedDialogState extends State<MonthlyLimitReachedDialog> {
  bool _showLicenseInput = false;
  final TextEditingController _licenseController = TextEditingController();
  String? _errorMessage;
  bool _isVerifying = false;

  void _verifyLicense() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final success = await EntitlementService.verifyAndApplyLicense(_licenseController.text);

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Paid Version Activated Successfully! Unlimited monthly report generation unlocked.'),
        ),
      );
      widget.onPaidUnlocked?.call();
    } else {
      setState(() {
        _errorMessage = 'Invalid commercial license key or unverified payment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Monthly Report Limit Reached',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have reached your monthly report generation limit. Upgrade to the Paid Version to generate more reports.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.primaryNavy,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            if (!_showLicenseInput) ...[
              InkWell(
                onTap: () => setState(() => _showLicenseInput = true),
                child: const Row(
                  children: [
                    Icon(Icons.vpn_key, size: 16, color: AppColors.primaryActionTeal),
                    SizedBox(width: 6),
                    Text(
                      'Have a Paid Commercial License Key?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryActionTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Divider(color: AppColors.borders),
              const SizedBox(height: 8),
              const Text(
                'Enter Verified Paid License Key:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _licenseController,
                decoration: InputDecoration(
                  hintText: 'e.g. VLR-PRO-XXXX-XXXX',
                  errorText: _errorMessage,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _showLicenseInput = false),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyLicense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: _isVerifying
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Activate', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
