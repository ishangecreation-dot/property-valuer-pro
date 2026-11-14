import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/monthly_usage_service.dart';
import '../../../core/services/entitlement_service.dart';

class AdminSettingsModal extends StatefulWidget {
  const AdminSettingsModal({Key? key}) : super(key: key);

  @override
  State<AdminSettingsModal> createState() => _AdminSettingsModalState();
}

class _AdminSettingsModalState extends State<AdminSettingsModal> {
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _metaPlacementIdController = TextEditingController();
  bool _obscureApiKey = true;
  String _selectedProvider = 'Gemini 3.8 Flash';
  String _selectedAdProvider = AdService.activeAdProvider;
  bool _isTesting = false;
  String? _testResult;
  bool _enableAds = AdService.isAdsEnabled;
  bool _isPaidTier = false;
  MonthlyUsageState? _usageState;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final key = await EncryptionService.getAiApiKey();
    final provider = await EncryptionService.getAiProvider();
    final usage = await MonthlyUsageService.getUsage();
    final isPaid = await EntitlementService.isPaidTier();

    setState(() {
      _apiKeyController.text = key;
      _selectedProvider = provider;
      _selectedAdProvider = AdService.activeAdProvider;
      _metaPlacementIdController.text = AdService.metaInterstitialPlacementId;
      _enableAds = AdService.isAdsEnabled;
      _usageState = usage;
      _isPaidTier = isPaid;
    });
  }

  void _verifyPassword() async {
    final ok = await EncryptionService.verifyAdminPassword(_passwordController.text);
    if (ok) {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Admin Password. Please try again.')),
      );
    }
  }

  void _saveSettings() async {
    await EncryptionService.saveAiApiKey(_apiKeyController.text);
    await EncryptionService.saveAiProvider(_selectedProvider);

    if (_enableAds) {
      if (_selectedAdProvider == AppConstants.adProviderMeta) {
        await AdService.enableMetaAds(interstitialId: _metaPlacementIdController.text);
      } else {
        await AdService.enableAdMobAds();
      }
    } else {
      await AdService.disableAds();
    }

    await EntitlementService.setDirectEntitlementForTesting(_isPaidTier);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin Settings Saved Securely (Encrypted)')),
    );
    Navigator.of(context).pop();
  }

  void _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    final success = await AiService.testConnection();
    setState(() {
      _isTesting = false;
      _testResult = success
          ? 'API Connection Successful! Ready for OCR & Extraction.'
          : 'Could not connect. Please verify your API Key.';
    });
  }

  void _resetMonthlyCount() async {
    await MonthlyUsageService.resetCounterForTesting();
    final usage = await MonthlyUsageService.getUsage();
    setState(() => _usageState = usage);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly generation counter reset to 0/10.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: AppColors.primaryNavy),
                      SizedBox(width: 8),
                      Text(
                        'Admin Settings & Monetization',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borders),
              const SizedBox(height: 12),

              if (!_isAuthenticated) ...[
                const Text(
                  'Enter Admin Password to access system configuration, monthly quotas, and advertising settings.',
                  style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Admin Password',
                    hintText: 'Enter master password (Set on first use)',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _verifyPassword,
                  child: const Text('Unlock Settings'),
                ),
              ] else ...[
                // AI Provider Selection
                const Text(
                  'AI Provider',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  items: const [
                    DropdownMenuItem(value: 'Gemini 3.8 Flash', child: Text('Gemini 3.8 Flash (Recommended)')),
                    DropdownMenuItem(value: 'Gemini 3.5 Flash', child: Text('Gemini 3.5 Flash')),
                    DropdownMenuItem(value: 'OpenAI GPT-4o', child: Text('OpenAI GPT-4o')),
                    DropdownMenuItem(value: 'Claude 3.5 Sonnet', child: Text('Claude 3.5 Sonnet')),
                    DropdownMenuItem(value: 'Custom Endpoint', child: Text('Custom Private Backend')),
                  ],
                  onChanged: (val) => setState(() => _selectedProvider = val!),
                ),
                const SizedBox(height: 16),

                // API Key Input
                const Text(
                  'AI API Key (Encrypted Storage)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  decoration: InputDecoration(
                    hintText: 'Enter your AI API Key...',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Test Connection
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check, size: 16),
                      label: const Text('Test Connection'),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _testResult!.contains('Successful') ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: AppColors.borders),
                const SizedBox(height: 8),

                // SECTION 20: Monthly Report Limit & Paid Tier
                const Text(
                  'Monthly Free Report Limit (Section 20)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borders),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Month: ${_usageState?.monthIdentifier ?? "N/A"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Usage: ${_usageState?.usedClicks ?? 0} / ${MonthlyUsageService.maxMonthlyClicks}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetMonthlyCount,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset Counter (0/10)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await MonthlyUsageService.setSimulatedCountForTesting(10);
                                final u = await MonthlyUsageService.getUsage();
                                setState(() => _usageState = u);
                              },
                              icon: const Icon(Icons.lock, size: 14),
                              label: const Text('Simulate 10/10 Limit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Paid Version Entitlement (Unlimited)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Bypasses monthly generation limit and disables all ads', style: TextStyle(fontSize: 11)),
                  value: _isPaidTier,
                  activeColor: AppColors.success,
                  onChanged: (val) => setState(() => _isPaidTier = val),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.borders),
                const SizedBox(height: 8),

                // Advertising & Meta Audience Network Configuration
                const Text(
                  'Meta Audience Network & Advertising',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  title: const Text('Enable Interstitial Ads', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Shows interstitial ad before generating report in free version', style: TextStyle(fontSize: 11)),
                  value: _enableAds,
                  activeColor: AppColors.primaryActionTeal,
                  onChanged: (val) => setState(() => _enableAds = val),
                ),

                if (_enableAds) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAdProvider,
                    decoration: const InputDecoration(
                      labelText: 'Ad Network Provider',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppConstants.adProviderMeta,
                        child: Text('Meta Audience Network (Facebook FAN)'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.adProviderAdMob,
                        child: Text('Google AdMob'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAdProvider = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _metaPlacementIdController,
                    decoration: const InputDecoration(
                      labelText: 'Meta Interstitial Placement ID',
                      hintText: 'VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0081FB), // Meta Blue
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => AdService.showMetaPreviewInterstitial(context),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Preview Meta Interstitial Ad Now'),
                  ),
                ],

                const SizedBox(height: 16),
                Text(
                  'Application: ${AppConstants.appName} v${AppConstants.appVersion}',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),

                // Save button
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save & Apply Settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
