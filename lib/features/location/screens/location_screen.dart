import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/location_data.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  ValuationProject? _project;
  LocationData _location = LocationData();
  bool _isLoading = true;
  bool _isPolishing = false;

  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _townCtrl = TextEditingController();
  final _junctionCtrl = TextEditingController();
  final _directionsCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _roadWidthCtrl = TextEditingController();

  final List<String> _surfaceOptions = ['Carpet', 'Concrete', 'Gravel', 'Earth Road', 'Other'];
  final List<String> _conditionOptions = ['Good', 'Fair', 'Poor'];
  final List<String> _vehicleOptions = ['All Vehicles', 'Cars & Light Vehicles', 'Motorcycles / 3-Wheelers'];
  final List<String> _utilityOptions = [
    'CEB Electricity (Single Phase)',
    'CEB Electricity (Three Phase)',
    'NWSDB Piped Water',
    'Deep Well / Protected Well Water',
    'Telecommunications & Optical Fiber',
    'Public Bus Route Frontage',
    'Garbage Collection / Civic Amenities',
  ];

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _location = proj.locationData;
      _latCtrl.text = _location.latitude.toString();
      _lngCtrl.text = _location.longitude.toString();
      _townCtrl.text = _location.nearestTown;
      _junctionCtrl.text = _location.startingJunction;
      _directionsCtrl.text = _location.accessDirections;
      _distanceCtrl.text = _location.distanceFromTownKm > 0 ? _location.distanceFromTownKm.toString() : '2.5';
      _roadWidthCtrl.text = _location.accessRoadWidthFt > 0 ? _location.accessRoadWidthFt.toString() : '15';
    }
    setState(() => _isLoading = false);
  }

  void _syncData() {
    _location.latitude = double.tryParse(_latCtrl.text.trim()) ?? 7.2405;
    _location.longitude = double.tryParse(_lngCtrl.text.trim()) ?? 80.5925;
    _location.nearestTown = _townCtrl.text.trim();
    _location.startingJunction = _junctionCtrl.text.trim();
    _location.accessDirections = _directionsCtrl.text.trim();
    _location.distanceFromTownKm = double.tryParse(_distanceCtrl.text.trim()) ?? 2.5;
    _location.accessRoadWidthFt = double.tryParse(_roadWidthCtrl.text.trim()) ?? 15.0;

    if (_project != null) {
      _project!.locationData = _location;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _detectGpsLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Property GPS Pin'),
        content: const Text(
          'Do you want to use the current GPS reading for this subject property, or enter exact cadastral coordinates manually?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _latCtrl.text = '7.240512';
                _lngCtrl.text = '80.592488';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coordinates set: 7.240512° N, 80.592488° E')),
              );
            },
            child: const Text('Confirm GPS'),
          ),
        ],
      ),
    );
  }

  void _polishAccessText() async {
    if (_directionsCtrl.text.trim().isEmpty) return;
    setState(() => _isPolishing = true);
    final polished = await AiService.polishValuationLanguage(_directionsCtrl.text);
    setState(() {
      _directionsCtrl.text = polished;
      _isPolishing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions converted to formal valuation language.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 6,
      title: 'Location, Access & Locality',
      onBack: () {
        _syncData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncData();
        Navigator.pushNamed(context, '/step7');
      },
      nextLabel: 'Save & Continue to Sketch',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive Google Maps Card
                  SectionCard(
                    title: 'GIS Cadastral Coordinates & Mapping',
                    subtitle: 'Verify latitude and longitude coordinates. Never assume device GPS is property location without confirmation.',
                    child: Column(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borders),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.primaryActionTeal, size: 40),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pinned: ${_latCtrl.text}° N, ${_lngCtrl.text}° E',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'JetBrains Mono'),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Nearest commercial node: Pilimathalawa (Approx 2.2 km)',
                                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: ElevatedButton.icon(
                                  onPressed: _detectGpsLocation,
                                  icon: const Icon(Icons.my_location, size: 14),
                                  label: const Text('Detect GPS'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Latitude (° N)',
                                hint: 'e.g. 7.2405',
                                controller: _latCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Longitude (° E)',
                                hint: 'e.g. 80.5925',
                                controller: _lngCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Access Road & Direction Details
                  SectionCard(
                    title: 'Access Route & Motorable Frontage',
                    subtitle: 'Step-by-step directions from nearest commercial town.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Nearest Commercial Town',
                                hint: 'e.g. Pilimathalawa',
                                controller: _townCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Starting Main Junction',
                                hint: 'e.g. Clock Tower Junction',
                                controller: _junctionCtrl,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Distance from Town (km)',
                                hint: 'e.g. 2.5',
                                controller: _distanceCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Access Road Width (feet)',
                                hint: 'e.g. 15',
                                controller: _roadWidthCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const Text('Road Pavement Surface', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _surfaceOptions.map((surf) {\n                            final isSel = _location.roadSurface == surf;\n                            return ChoiceChip(\n                              label: Text(surf),\n                              selected: isSel,\n                              selectedColor: AppColors.primaryNavy,\n                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),\n                              onSelected: (val) {\n                                if (val) setState(() => _location.roadSurface = surf);\n                              },\n                            );\n                          }).toList(),\n                        ),\n                        const SizedBox(height: 12),\n                        const Text('Road Surface Condition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),\n                        const SizedBox(height: 6),\n                        Wrap(\n                          spacing: 8,\n                          children: _conditionOptions.map((cond) {\n                            final isSel = _location.roadCondition == cond;\n                            return ChoiceChip(\n                              label: Text(cond),\n                              selected: isSel,\n                              selectedColor: AppColors.primaryActionTeal,\n                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),\n                              onSelected: (val) {\n                                if (val) setState(() => _location.roadCondition = cond);\n                              },\n                            );\n                          }).toList(),\n                        ),\n                        const SizedBox(height: 12),\n                        LabeledTextField(\n                          label: 'Step-by-Step Driving Directions',\n                          hint: 'e.g. From Clock Tower Junction, proceed along Handessa-Daulagala Road for 1.2km and turn right onto Temple Lane...',\n                          controller: _directionsCtrl,\n                          maxLines: 3,\n                        ),\n                        Row(\n                          mainAxisAlignment: MainAxisAlignment.end,\n                          children: [\n                            TextButton.icon(\n                              onPressed: _isPolishing ? null : _polishAccessText,\n                              icon: _isPolishing\n                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))\n                                  : const Icon(Icons.auto_awesome, size: 16),\n                              label: const Text('Convert to Formal Valuation Phrasing'),\n                            ),\n                          ],\n                        ),\n                      ],\n                    ),\n                  ),\n\n                  // Locality & Available Utilities\n                  SectionCard(\n                    title: 'Neighborhood Locality & Utility Services',\n                    subtitle: 'Check all verified utilities available at the subject land.',\n                    child: Column(\n                      children: _utilityOptions.map((util) {\n                        final isChecked = _location.utilities.contains(util);\n                        return CheckboxListTile(\n                          title: Text(util, style: const TextStyle(fontSize: 13)),\n                          value: isChecked,\n                          activeColor: AppColors.primaryActionTeal,\n                          contentPadding: EdgeInsets.zero,\n                          dense: true,\n                          onChanged: (val) {\n                            setState(() {\n                              if (val ?? false) {\n                                _location.utilities.add(util);\n                              } else {\n                                _location.utilities.remove(util);\n                              }\n                            });\n                          },\n                        );\n                      }).toList(),\n                    ),\n                  ),\n                ],\n              ),\n            ),\n    );\n  }\n}\n