import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/ad_service.dart';

class MetaInterstitialAdDialog extends StatefulWidget {
  final VoidCallback onDismissed;
  final String placementId;

  const MetaInterstitialAdDialog({
    Key? key,
    required this.onDismissed,
    required this.placementId,
  }) : super(key: key);

  @override
  State<MetaInterstitialAdDialog> createState() => _MetaInterstitialAdDialogState();
}

class _MetaInterstitialAdDialogState extends State<MetaInterstitialAdDialog> {
  int _countdownSeconds = 5;
  Timer? _timer;
  bool _canDismiss = false;

  @override
  void initState() {
    super.initState();
    AdService.recordAdImpression();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _countdownSeconds = 0;
          _canDismiss = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    if (!_canDismiss) return;
    Navigator.of(context, rootNavigator: true).pop();
    widget.onDismissed();
  }

  void _handleCtaTap() {
    AdService.recordAdClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Commercial Bank Mortgage Solutions...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdChoicesInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF0081FB)),
            SizedBox(width: 8),
            Text('Meta Ad Choices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This advertisement is delivered via Meta Audience Network based on professional business profile insights. You can manage your ad preferences in your Meta / Facebook account settings.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // High-fidelity full-screen Meta Audience Network Interstitial Ad
    return PopScope(
      canPop: _canDismiss,
      onPopInvoked: (didPop) {
        if (didPop) {
          widget.onDismissed();
        }
      },
      child: Dialog.fullscreen(
        backgroundColor: const Color(0xFF0F141C),
        child: SafeArea(
          child: Column(
            children: [
              // Meta Audience Network Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF161E2E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Meta Branding
                    Row(
                      children: [
                        // Meta Infinity Logo Mark
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0081FB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Icon(Icons.all_inclusive, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Meta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Audience Network',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'SPONSORED',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _showAdChoicesInfo,
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF94A3B8),
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Countdown / Close Button
                    _canDismiss
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 22),
                              tooltip: 'Close Ad',
                              onPressed: _handleDismiss,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0081FB)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reward in ${_countdownSeconds}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),

              // Main Creative Media Canvas
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Visual Banner with Banking / Mortgage Theme
                      Container(
                        height: 240,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -20,
                              right: -20,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2563EB).withOpacity(0.25),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.antiqueGold.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.antiqueGold),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.verified, color: AppColors.antiqueGold, size: 14),
                                            SizedBox(width: 6),
                                            Text(
                                              'OFFICIAL BANKING PARTNER',
                                              style: TextStyle(
                                                color: AppColors.antiqueGold,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.account_balance, color: Colors.white70, size: 28),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Commercial Bank of Ceylon',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Mortgage Valuer Digital Clearinghouse',
                                        style: TextStyle(
                                          color: Color(0xFF93C5FD),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (index) => const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            '4.9 (18.2K Sri Lankan Valuers)',
                                            style: TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Meta Audience Network Native Advertiser Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // App Icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0052CC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.real_estate_agent, color: Colors.white, size: 28),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CombBank Valuer Portal',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Free Institutional Mortgage Tool • Finance',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Direct integration with Sri Lankan Commercial Bank credit committees. Submit your DOCX appraisal dossiers online, track mortgage panel status, and receive direct disbursement disbursements within 24 hours.',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Feature bullets
                              _buildBenefitItem(Icons.bolt, 'Instant 1-Click e-Submission for Panel Valuers'),
                              const SizedBox(height: 6),
                              _buildBenefitItem(Icons.security, 'Central Bank of Sri Lanka Regulatory Compliance'),
                              const SizedBox(height: 6),
                              _buildBenefitItem(Icons.cloud_done, 'Automated Deed & Plan Cadastral Matching'),
                            ],
                          ),
                        ),
                      ),

                      // Meta Placement ID metadata badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                        child: Text(
                          'Meta FAN Placement: ${widget.placementId}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA Action Bar (Meta Standard High-Contrast CTA)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF161E2E),
                  border: Border(top: BorderSide(color: Color(0xFF334155))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0081FB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _handleCtaTap,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Install Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (_canDismiss) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF475569)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _handleDismiss,
                        child: const Text('Skip Ad'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}
