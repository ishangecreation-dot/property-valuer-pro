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
                  items: const [\n                    DropdownMenuItem(value: 'Gemini 3.8 Flash', child: Text('Gemini 3.8 Flash (Recommended)')),\n                    DropdownMenuItem(value: 'Gemini 3.5 Flash', child: Text('Gemini 3.5 Flash')),\n                    DropdownMenuItem(value: 'OpenAI GPT-4o', child: Text('OpenAI GPT-4o')),\n                    DropdownMenuItem(value: 'Claude 3.5 Sonnet', child: Text('Claude 3.5 Sonnet')),\n                    DropdownMenuItem(value: 'Custom Endpoint', child: Text('Custom Private Backend')),\n                  ],\n                  onChanged: (val) => setState(() => _selectedProvider = val!),\n                ),\n                const SizedBox(height: 16),\n\n                // API Key Input\n                const Text(\n                  'AI API Key (Encrypted Storage)',\n                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),\n                ),\n                const SizedBox(height: 6),\n                TextField(\n                  controller: _apiKeyController,\n                  obscureText: _obscureApiKey,\n                  decoration: InputDecoration(\n                    hintText: 'Enter your AI API Key...',\n                    suffixIcon: IconButton(\n                      icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off),\n                      onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),\n                    ),\n                  ),\n                ),\n                const SizedBox(height: 10),\n\n                // Test Connection\n                Row(\n                  children: [\n                    OutlinedButton.icon(\n                      onPressed: _isTesting ? null : _testConnection,\n                      icon: _isTesting\n                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))\n                          : const Icon(Icons.network_check, size: 16),\n                      label: const Text('Test Connection'),\n                    ),\n                  ],\n                ),\n                if (_testResult != null) ...[\n                  const SizedBox(height: 8),\n                  Text(\n                    _testResult!,\n                    style: TextStyle(\n                      fontSize: 12,\n                      fontWeight: FontWeight.w600,\n                      color: _testResult!.contains('Successful') ? AppColors.success : AppColors.error,\n                    ),\n                  ),\n                ],\n\n                const SizedBox(height: 16),\n                const Divider(color: AppColors.borders),\n                const SizedBox(height: 8),\n\n                // SECTION 20: Monthly Report Limit & Paid Tier\n                const Text(\n                  'Monthly Free Report Limit (Section 20)',\n                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),\n                ),\n                const SizedBox(height: 6),\n                Container(\n                  padding: const EdgeInsets.all(12),\n                  decoration: BoxDecoration(\n                    color: AppColors.surfaceContainerLow,\n                    borderRadius: BorderRadius.circular(8),\n                    border: Border.all(color: AppColors.borders),\n                  ),\n                  child: Column(\n                    children: [\n                      Row(\n                        mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                        children: [\n                          Text(\n                            'Current Month: ${_usageState?.monthIdentifier ?? \"N/A\"}',\n                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),\n                          ),\n                          Text(\n                            'Usage: ${_usageState?.usedClicks ?? 0} / ${MonthlyUsageService.maxMonthlyClicks}',\n                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),\n                          ),\n                        ],\n                      ),\n                      const SizedBox(height: 8),\n                      Row(\n                        children: [\n                          Expanded(\n                            child: OutlinedButton.icon(\n                              onPressed: _resetMonthlyCount,\n                              icon: const Icon(Icons.refresh, size: 14),\n                              label: const Text('Reset Counter (0/10)'),\n                            ),\n                          ),\n                          const SizedBox(width: 8),\n                          Expanded(\n                            child: OutlinedButton.icon(\n                              onPressed: () async {\n                                await MonthlyUsageService.setSimulatedCountForTesting(10);\n                                final u = await MonthlyUsageService.getUsage();\n                                setState(() => _usageState = u);\n                              },\n                              icon: const Icon(Icons.lock, size: 14),\n                              label: const Text('Simulate 10/10 Limit'),\n                            ),\n                          ),\n                        ],\n                      ),\n                    ],\n                  ),\n                ),\n\n                const SizedBox(height: 12),\n                SwitchListTile(\n                  title: const Text('Paid Version Entitlement (Unlimited)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),\n                  subtitle: const Text('Bypasses monthly generation limit and disables all ads', style: TextStyle(fontSize: 11)),\n                  value: _isPaidTier,\n                  activeColor: AppColors.success,\n                  onChanged: (val) => setState(() => _isPaidTier = val),\n                ),\n\n                const SizedBox(height: 16),\n                const Divider(color: AppColors.borders),\n                const SizedBox(height: 8),\n\n                // Advertising & Meta Audience Network Configuration\n                const Text(\n                  'Meta Audience Network & Advertising',\n                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),\n                ),\n                const SizedBox(height: 6),\n                SwitchListTile(\n                  title: const Text('Enable Interstitial Ads', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),\n                  subtitle: const Text('Shows interstitial ad before generating report in free version', style: TextStyle(fontSize: 11)),\n                  value: _enableAds,\n                  activeColor: AppColors.primaryActionTeal,\n                  onChanged: (val) => setState(() => _enableAds = val),\n                ),\n\n                if (_enableAds) ...[\n                  const SizedBox(height: 8),\n                  DropdownButtonFormField<String>(\n                    value: _selectedAdProvider,\n                    decoration: const InputDecoration(\n                      labelText: 'Ad Network Provider',\n                      isDense: true,\n                    ),\n                    items: const [\n                      DropdownMenuItem(\n                        value: AppConstants.adProviderMeta,\n                        child: Text('Meta Audience Network (Facebook FAN)'),\n                      ),\n                      DropdownMenuItem(\n                        value: AppConstants.adProviderAdMob,\n                        child: Text('Google AdMob'),\n                      ),\n                    ],\n                    onChanged: (val) => setState(() => _selectedAdProvider = val!),\n                  ),\n                  const SizedBox(height: 10),\n                  TextField(\n                    controller: _metaPlacementIdController,\n                    decoration: const InputDecoration(\n                      labelText: 'Meta Interstitial Placement ID',\n                      hintText: 'VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID',\n                      isDense: true,\n                    ),\n                  ),\n                  const SizedBox(height: 10),\n                  ElevatedButton.icon(\n                    style: ElevatedButton.styleFrom(\n                      backgroundColor: const Color(0xFF0081FB), // Meta Blue\n                      foregroundColor: Colors.white,\n                    ),\n                    onPressed: () => AdService.showMetaPreviewInterstitial(context),\n                    icon: const Icon(Icons.play_circle_outline, size: 16),\n                    label: const Text('Preview Meta Interstitial Ad Now'),\n                  ),\n                ],\n\n                const SizedBox(height: 16),\n                Text(\n                  'Application: ${AppConstants.appName} v${AppConstants.appVersion}',\n                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),\n                ),\n                const SizedBox(height: 16),\n\n                // Save button\n                ElevatedButton(\n                  onPressed: _saveSettings,\n                  child: const Text('Save & Apply Settings'),\n                ),\n              ],\n            ],\n          ),\n        ),\n      ),\n    );\n  }\n}\n