import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/encryption_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/monthly_usage_service.dart';
import '../../../core/services/entitlement_service.dart';

class AdminSettingsModal extends StatefulWidget {
  const AdminSettingsModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminSettingsModal(),
    );
  }

  @override
  State<AdminSettingsModal> createState() => _AdminSettingsModalState();
}

class _AdminSettingsModalState extends State<AdminSettingsModal> {
  bool _isAuthenticated = false;
  bool _obscurePassword = true;
  bool _obscureApiKey = true;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _metaPlacementIdController = TextEditingController();

  String _selectedProvider = 'Gemini 3.8 Flash';
  String _selectedAdProvider = AdService.activeAdProvider;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;
  bool _enableAds = AdService.isAdsEnabled;
  bool _isPaidTier = false;
  MonthlyUsageState? _usageState;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _apiKeyController.dispose();
    _metaPlacementIdController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final key = await EncryptionService.getAiApiKey();
    final provider = await EncryptionService.getAiProvider();
    final usage = await MonthlyUsageService.getUsage();
    final isPaid = await EntitlementService.isPaidTier();

    if (!mounted) return;
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

  /// Verifies password against default administrator password
  Future<void> _handleLogin() async {
    final input = _passwordController.text.trim();
    final isValid = await EncryptionService.verifyAdminPassword(input);

    if (!mounted) return;

    if (!isValid) {
      // Display Access Denied Alert Dialog per Section 2
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Access Denied',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          content: const Text(
            'Incorrect password. Please contact your app creator Admin.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Keep administrator password popup open and clear password field
      if (mounted) {
        _passwordController.clear();
        setState(() {});
      }
      return;
    }

    // Password is correct: transition to AI API Key Settings screen
    final key = await EncryptionService.getAiApiKey();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = true;
      _apiKeyController.text = key;
    });
  }

  /// Saves the Gemini API key securely
  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter your API key first.'),
        ),
      );
      setState(() {
        _testMessage = 'Please enter your API key first.';
        _testSuccess = false;
      });
      return;
    }

    final saved = await EncryptionService.saveAiApiKey(key);
    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('API key saved successfully.'),
        ),
      );
      setState(() {
        _testMessage = 'API key saved successfully.';
        _testSuccess = true;
      });
    }
  }

  /// Tests connectivity with the configured AI provider and API Key
  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter your API key first.'),
        ),
      );
      setState(() {
        _testMessage = 'Please enter your API key first.';
        _testSuccess = false;
      });
      return;
    }

    // Save key first so AiService uses this entered key
    await EncryptionService.saveAiApiKey(key);

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final success = await AiService.testConnection();
    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = success;
      _testMessage = success
          ? 'API Connection Successful! Gemini Vision OCR is ready.'
          : 'Could not connect. Please verify your API Key and internet access.';
    });
  }

  Future<void> _saveAdvancedSettings() async {
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
      const SnackBar(content: Text('Advanced Settings Saved Securely')),
    );
  }

  Future<void> _resetMonthlyCount() async {
    await MonthlyUsageService.resetCounterForTesting();
    final usage = await MonthlyUsageService.getUsage();
    if (!mounted) return;
    setState(() => _usageState = usage);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly generation counter reset to 0/10.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: _isAuthenticated ? _buildApiKeySettings() : _buildAuthenticationPopup(),
      ),
    );
  }

  /// 1. Administrator Authentication Popup
  Widget _buildAuthenticationPopup() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: AppColors.primaryNavy, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Administrator Authentication',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 17,
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
          const Text(
            'Enter the administrator password to access AI API settings.',
            style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Administrator Password',
              hintText: 'Enter password...',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: _handleLogin,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. AI API Key Settings Screen
  Widget _buildApiKeySettings() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.vpn_key, color: AppColors.primaryNavy, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'AI API Key Settings',
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

          // Heading
          const Text(
            'Enter Your Gemini API Key',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),

          // Short Instruction
          const Text(
            'Paste your Gemini API key below to enable AI document extraction.',
            style: TextStyle(fontSize: 13, color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Multiline, paste-friendly API Key Input Field
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            maxLines: _obscureApiKey ? 1 : 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Paste Gemini API Key here (e.g. AIzaSy...)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.paste, size: 20, color: AppColors.primaryNavy),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        setState(() {
                          _apiKeyController.text = data!.text!.trim();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off, size: 20),
                    tooltip: _obscureApiKey ? 'Show API Key' : 'Hide API Key',
                    onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Test Result / Status Display
          if (_testMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _testSuccess == true ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testSuccess == true ? AppColors.success : AppColors.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess == true ? Icons.check_circle : Icons.error_outline,
                    color: _testSuccess == true ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _testSuccess == true ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons: Save API Key, Test Connection, Close
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: _saveApiKey,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.network_check, size: 18),
                label: const Text('Test Connection'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borders),

          // Advanced Admin & Monetization Tools (Section 20 & Meta Ads)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Advanced Monetization & Quota Controls',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                // AI Provider Selection
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'AI Engine Model',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Gemini 3.8 Flash', child: Text('Gemini 3.8 Flash (Recommended)')),
                    DropdownMenuItem(value: 'Gemini 3.5 Flash', child: Text('Gemini 3.5 Flash')),
                    DropdownMenuItem(value: 'OpenAI GPT-4o', child: Text('OpenAI GPT-4o')),
                    DropdownMenuItem(value: 'Claude 3.5 Sonnet', child: Text('Claude 3.5 Sonnet')),
                    DropdownMenuItem(value: 'Custom Endpoint', child: Text('Custom Private Backend')),
                  ],
                  onChanged: (val) => setState(() => _selectedProvider = val!),
                ),
                const SizedBox(height: 12),

                // SECTION 20: Monthly Report Limit & Paid Tier
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
                              label: const Text('Reset (0/10)', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await MonthlyUsageService.setSimulatedCountForTesting(10);
                                final u = await MonthlyUsageService.getUsage();
                                if (!mounted) return;
                                setState(() => _usageState = u);
                              },
                              icon: const Icon(Icons.lock, size: 14),
                              label: const Text('Simulate 10/10', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  title: const Text('Paid Tier Entitlement (Unlimited)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Bypasses monthly limit and disables ads', style: TextStyle(fontSize: 11)),
                  value: _isPaidTier,
                  activeColor: AppColors.success,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isPaidTier = val),
                ),

                SwitchListTile(
                  title: const Text('Enable Interstitial Ads', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Shows interstitial before generating report in free version', style: TextStyle(fontSize: 11)),
                  value: _enableAds,
                  activeColor: AppColors.primaryActionTeal,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _enableAds = val),
                ),

                if (_enableAds) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedAdProvider,
                    decoration: const InputDecoration(labelText: 'Ad Network Provider', isDense: true),
                    items: const [
                      DropdownMenuItem(value: AppConstants.adProviderMeta, child: Text('Meta Audience Network (Facebook FAN)')),
                      DropdownMenuItem(value: AppConstants.adProviderAdMob, child: Text('Google AdMob')),
                    ],
                    onChanged: (val) => setState(() => _selectedAdProvider = val!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _metaPlacementIdController,
                    decoration: const InputDecoration(
                      labelText: 'Meta Interstitial Placement ID',
                      hintText: 'VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0081FB),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => AdService.showMetaPreviewInterstitial(context),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Preview Meta Interstitial Ad'),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveAdvancedSettings,
                  child: const Text('Save Advanced Settings'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'Application: ${AppConstants.appName} v${AppConstants.appVersion}',
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
