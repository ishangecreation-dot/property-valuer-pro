import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/building_details.dart';
import '../../../core/storage/storage_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class BuildingDetailsScreen extends StatefulWidget {
  const BuildingDetailsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingDetailsScreen> createState() => _BuildingDetailsScreenState();
}

class _BuildingDetailsScreenState extends State<BuildingDetailsScreen> {
  ValuationProject? _project;
  BuildingDetails _details = BuildingDetails();
  bool _isLoading = true;

  final _gfAreaCtrl = TextEditingController();
  final _ufAreaCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  final List<String> _roofOptions = ['Asbestos on Timber Rafters', 'Concrete Flat Roof', 'Tile', 'Zinc Aluminium on Iron Trusses', 'Other'];
  final List<String> _wallOptions = ['Brick Masonry, Plastered & Painted', 'Cement Block Masonry', 'Colour Washed', 'Other'];
  final List<String> _floorOptions = ['Ceramic Tiled', 'Cement Rendered', 'Cut Cement / Terrazzo', 'Other'];
  final List<String> _conditionOptions = ['Good', 'Fair', 'Poor', 'Under Construction'];
  final List<String> _occupancyOptions = ['Owner Occupied', 'Tenanted', 'Vacant'];

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _details = proj.buildingDetails;
      if (_details.buildings.isNotEmpty) {
        final b = _details.buildings.first;
        _gfAreaCtrl.text = b.groundFloorAreaSqFt > 0 ? b.groundFloorAreaSqFt.toStringAsFixed(0) : '1500';
        _ufAreaCtrl.text = b.upperFloorAreaSqFt > 0 ? b.upperFloorAreaSqFt.toStringAsFixed(0) : '0';
        _ageCtrl.text = b.ageYears.toString();
      }
    }
    setState(() => _isLoading = false);
  }

  void _syncData() {
    if (_details.buildings.isNotEmpty) {
      final b = _details.buildings.first;
      b.groundFloorAreaSqFt = double.tryParse(_gfAreaCtrl.text.trim()) ?? 1500.0;
      b.upperFloorAreaSqFt = double.tryParse(_ufAreaCtrl.text.trim()) ?? 0.0;
      b.ageYears = int.tryParse(_ageCtrl.text.trim()) ?? 5;
    }

    if (_project != null) {
      _project!.buildingDetails = _details;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _pickPhoto(int slotIdx, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _details.photographs[slotIdx].filePath = picked.path;
        });
      }
    } catch (_) {
      setState(() {
        _details.photographs[slotIdx].filePath = 'photo_slot_${slotIdx + 1}.jpg';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBuilding = _details.buildings.isNotEmpty ? _details.buildings.first : BuildingSpecification();

    return ResponsiveWorkflowScaffold(
      currentStep: 8,
      title: 'Building Specs & Photographs',
      onBack: () {
        _syncData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncData();
        Navigator.pushNamed(context, '/step9');
      },
      nextLabel: 'Save & Continue to Valuation',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Multiple Buildings Switch / Support
                  SwitchListTile(
                    title: const Text('Building Improvements on Property', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Toggle off if evaluating bare land only'),
                    value: _details.hasBuilding,
                    activeColor: AppColors.primaryActionTeal,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _details.hasBuilding = val),
                  ),

                  if (_details.hasBuilding) ...[
                    // Structural Specifications Card
                    SectionCard(
                      title: 'Building Specifications & Finishes',
                      subtitle: 'Specify structural construction materials for ${activeBuilding.buildingName}.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Roof Structure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _roofOptions.map((r) {
                              final isSel = activeBuilding.roofType == r;
                              return ChoiceChip(
                                label: Text(r),
                                selected: isSel,
                                selectedColor: AppColors.primaryNavy,
                                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),
                                onSelected: (val) {
                                  if (val) setState(() => activeBuilding.roofType = r);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text('Walls Construction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _wallOptions.map((w) {
                              final isSel = activeBuilding.wallType == w;
                              return ChoiceChip(
                                label: Text(w),
                                selected: isSel,
                                selectedColor: AppColors.primaryNavy,
                                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),
                                onSelected: (val) {
                                  if (val) setState(() => activeBuilding.wallType = w);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text('Flooring Finishes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: _floorOptions.map((f) {
                              final isSel = activeBuilding.floorType == f;
                              return ChoiceChip(
                                label: Text(f),
                                selected: isSel,
                                selectedColor: AppColors.primaryActionTeal,
                                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),
                                onSelected: (val) {
                                  if (val) setState(() => activeBuilding.floorType = f);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: LabeledTextField(
                                  label: 'Ground Floor Area (sq.ft.)',
                                  hint: 'e.g. 1500',
                                  controller: _gfAreaCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LabeledTextField(
                                  label: 'Upper Floor Area (sq.ft.)',
                                  hint: 'e.g. 0',
                                  controller: _ufAreaCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: LabeledTextField(
                                  label: 'Building Age (Years)',
                                  hint: 'e.g. 5',
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Structural Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: activeBuilding.structuralCondition,
                                      items: _conditionOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                      onChanged: (v) => setState(() => activeBuilding.structuralCondition = v!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Accommodation Room Steppers Card
                    SectionCard(
                      title: 'Accommodation & Room Counts',
                      subtitle: 'Use simple plus/minus controls to record room breakdown.',
                      child: Column(
                        children: activeBuilding.roomCounters.map((rc) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.secondaryText),
                                      onPressed: rc.count > 0 ? () => setState(() => rc.count--) : null,
                                    ),
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${rc.count}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primaryActionTeal),
                                      onPressed: () => setState(() => rc.count++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Land Physical Characteristics Card
                  SectionCard(
                    title: 'Land Characteristics & Demarcations',
                    subtitle: 'Physical site observations from valuer inspection.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Shape of Land',
                                initialValue: _details.landShape,
                                hint: 'e.g. Regular rectangular shape',
                                onChanged: (v) => _details.landShape = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Topography / Grade',
                                initialValue: _details.landTopography,
                                hint: 'e.g. Flat at road grade',
                                onChanged: (v) => _details.landTopography = v,
                              ),
                            ),
                          ],
                        ),
                        LabeledTextField(
                          label: 'Subsoil & Foundation Characteristics',
                          initialValue: _details.subsoilCondition,
                          hint: 'e.g. Firm gravelly clay loam suitable for construction',
                          onChanged: (v) => _details.subsoilCondition = v,
                        ),
                        LabeledTextField(
                          label: 'Physical Boundary Demarcations on Site',
                          initialValue: _details.boundaryDemarcations,
                          hint: 'e.g. 5ft-6ft cement block parapet wall and barbed-wire fence',
                          onChanged: (v) => _details.boundaryDemarcations = v,
                        ),
                      ],
                    ),
                  ),

                  // Property Photographs Slots (4 Required for SKILL.md Annexure III)
                  SectionCard(
                    title: 'Property Photographs Register (4 Slots)',
                    subtitle: 'Capture with back camera or upload from gallery. These will be embedded into the report\'s photographic annexure.',
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _details.photographs.length,
                      itemBuilder: (context, idx) {
                        final photo = _details.photographs[idx];
                        final hasFile = photo.filePath.isNotEmpty;

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: hasFile ? AppColors.success : AppColors.borders),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasFile ? Icons.check_circle : Icons.camera_alt_outlined,
                                color: hasFile ? AppColors.success : AppColors.secondaryText,
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  photo.slotName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    onPressed: () => _pickPhoto(idx, ImageSource.camera),
                                    tooltip: 'Camera',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.photo_library, size: 16),
                                    onPressed: () => _pickPhoto(idx, ImageSource.gallery),
                                    tooltip: 'Gallery',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
