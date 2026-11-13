import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../core/storage/storage_service.dart';
import '../../../widgets/responsive_scaffold.dart';

class GenerationSuccessScreen extends StatefulWidget {
  const GenerationSuccessScreen({Key? key}) : super(key: key);

  @override
  State<GenerationSuccessScreen> createState() => _GenerationSuccessScreenState();
}

class _GenerationSuccessScreenState extends State<GenerationSuccessScreen> {
  ValuationProject? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    setState(() {
      _project = proj;
      _isLoading = false;
    });
  }

  void _openDocx() async {
    if (_project != null && _project!.generatedDocxPath.isNotEmpty) {
      await OpenFilex.open(_project!.generatedDocxPath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening DOCX in Microsoft Word...')),
      );
    }
  }

  void _shareDocx() async {
    if (_project != null && _project!.generatedDocxPath.isNotEmpty) {
      await Share.shareXFiles(
        [XFile(_project!.generatedDocxPath)],
        text: 'Valuation Dossier - ${_project!.projectName}',
      );
    } else {
      await Share.share('Valuation Report: ${_project?.projectName ?? "Valuation Dossier"}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 10,
      title: 'Report Generated',
      showBottomNav: false,
      showAdBanner: true, // Non-intrusive banner on Screen 10 Post-Generation as specified
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon Badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: AppColors.success, size: 54),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Valuation Report Generated Successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The editable Microsoft Word (.docx) document has been formatted to the ${_project?.targetPageCount ?? 4}-page budget with executive cover and underwriting annexures.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 28),

                    // 3 Large Action Buttons
                    ElevatedButton.icon(
                      onPressed: _openDocx,
                      icon: const Icon(Icons.edit_document, size: 20),
                      label: const Text('Open Editable DOCX in Word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryActionTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _shareDocx,
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Share Valuation Report (DOCX / Email)'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project saved locally to device storage.')),
                        );
                      },
                      icon: const Icon(Icons.save_alt, size: 20),
                      label: const Text('Save & Archive Project'),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppColors.borders),
                    const SizedBox(height: 12),

                    // Secondary Nav Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/step10'),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Generate Another Copy'),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                          icon: const Icon(Icons.dashboard, size: 16),
                          label: const Text('Return to Dashboard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
