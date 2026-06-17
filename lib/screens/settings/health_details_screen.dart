import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/health_details_model.dart';
import '../../services/health_details_service.dart';

class HealthDetailsScreen extends StatefulWidget {
  const HealthDetailsScreen({super.key});

  @override
  State<HealthDetailsScreen> createState() => _HealthDetailsScreenState();
}

class _HealthDetailsScreenState extends State<HealthDetailsScreen> {
  static const List<String> _yogaLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final _formKey = GlobalKey<FormState>();
  final _service = HealthDetailsService();

  final _bloodPressureController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _painLevelController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  StreamSubscription<HealthDetailsModel?>? _healthDetailsSubscription;

  String _yogaLevel = _yogaLevels.first;
  bool _isFetching = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _listenToHealthDetails();
  }

  @override
  void dispose() {
    _bloodPressureController.dispose();
    _bloodSugarController.dispose();
    _heartRateController.dispose();
    _painLevelController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _healthDetailsSubscription?.cancel();
    super.dispose();
  }

  void _listenToHealthDetails() {
    _healthDetailsSubscription = _service.healthDetailsStream().listen(
      (details) {
        if (!mounted) return;
        if (details != null && !_isSaving) {
          _fillForm(details);
        }
        setState(() => _isFetching = false);
      },
      onError: (error) {
        if (mounted) {
          _showSnackBar('Unable to load health details: $error');
          setState(() => _isFetching = false);
        }
      },
    );
  }

  Future<void> _saveHealthDetails() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final details = HealthDetailsModel(
      bloodPressure: _bloodPressureController.text.trim(),
      bloodSugar: double.parse(_bloodSugarController.text.trim()),
      heartRate: int.parse(_heartRateController.text.trim()),
      painLevel: int.parse(_painLevelController.text.trim()),
      age: int.parse(_ageController.text.trim()),
      weight: double.parse(_weightController.text.trim()),
      height: double.parse(_heightController.text.trim()),
      yogaLevel: _yogaLevel,
      updatedAt: DateTime.now(),
    );

    try {
      await _service.saveHealthDetails(details);
      if (!mounted) return;
      _showSnackBar('Health details saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Failed to save health details: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _fillForm(HealthDetailsModel details) {
    setState(() {
      _bloodPressureController.text = details.bloodPressure;
      _bloodSugarController.text = _formatNumber(details.bloodSugar);
      _heartRateController.text = details.heartRate == 0
          ? ''
          : details.heartRate.toString();
      _painLevelController.text = details.painLevel == 0
          ? ''
          : details.painLevel.toString();
      _ageController.text = details.age == 0 ? '' : details.age.toString();
      _weightController.text = _formatNumber(details.weight);
      _heightController.text = _formatNumber(details.height);
      _yogaLevel = _yogaLevels.contains(details.yogaLevel)
          ? details.yogaLevel
          : _yogaLevels.first;
    });
  }

  String _formatNumber(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Health Details'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    16,
                    isWide ? 32 : 16,
                    112,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerCard(),
                            const SizedBox(height: 16),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _healthDetailsSection()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _otherDetailsSection()),
                                ],
                              )
                            else ...[
                              _healthDetailsSection(),
                              const SizedBox(height: 16),
                              _otherDetailsSection(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isFetching)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.06),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveHealthDetails,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Health Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: Icon(Icons.health_and_safety, color: Colors.white, size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Health Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep these details updated for a safer yoga experience.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthDetailsSection() {
    return _sectionCard(
      title: 'Health Details',
      icon: Icons.monitor_heart,
      children: [
        _textField(
          controller: _bloodPressureController,
          label: 'Blood Pressure',
          hint: '120/80',
          icon: Icons.bloodtype,
          keyboardType: TextInputType.text,
          validator: _requiredValidator,
        ),
        _textField(
          controller: _bloodSugarController,
          label: 'Blood Sugar (mg/dL)',
          icon: Icons.water_drop,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalInputFormatter],
          validator: (value) =>
              _positiveNumberValidator(value, fieldName: 'Blood Sugar'),
        ),
        _textField(
          controller: _heartRateController,
          label: 'Heart Rate (bpm)',
          icon: Icons.favorite,
          keyboardType: TextInputType.number,
          inputFormatters: [_digitsOnlyFormatter],
          validator: (value) =>
              _positiveIntValidator(value, fieldName: 'Heart Rate'),
        ),
        _textField(
          controller: _painLevelController,
          label: 'Pain Level (1-10)',
          icon: Icons.sick,
          keyboardType: TextInputType.number,
          inputFormatters: [_digitsOnlyFormatter],
          validator: _painLevelValidator,
        ),
      ],
    );
  }

  Widget _otherDetailsSection() {
    return _sectionCard(
      title: 'Other Details',
      icon: Icons.person_search,
      children: [
        _textField(
          controller: _ageController,
          label: 'Age',
          icon: Icons.cake,
          keyboardType: TextInputType.number,
          inputFormatters: [_digitsOnlyFormatter],
          validator: (value) => _positiveIntValidator(value, fieldName: 'Age'),
        ),
        _textField(
          controller: _weightController,
          label: 'Weight (kg)',
          icon: Icons.fitness_center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalInputFormatter],
          validator: (value) =>
              _positiveNumberValidator(value, fieldName: 'Weight'),
        ),
        _textField(
          controller: _heightController,
          label: 'Height (cm)',
          icon: Icons.height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalInputFormatter],
          validator: (value) =>
              _positiveNumberValidator(value, fieldName: 'Height'),
        ),
        DropdownButtonFormField<String>(
          initialValue: _yogaLevel,
          items: _yogaLevels
              .map(
                (level) => DropdownMenuItem(value: level, child: Text(level)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _yogaLevel = value);
          },
          decoration: _inputDecoration(
            label: 'Yoga Level',
            icon: Icons.self_improvement,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Yoga Level is required.' : null,
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(label: label, icon: icon, hint: hint),
        validator: validator,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a valid number.';
    if (number <= 0) return '$fieldName must be positive.';
    return null;
  }

  String? _positiveIntValidator(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a valid number.';
    if (number <= 0) return '$fieldName must be positive.';
    return null;
  }

  String? _painLevelValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pain Level is required.';
    }
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a valid number.';
    if (number < 1 || number > 10) {
      return 'Pain Level must be between 1 and 10.';
    }
    return null;
  }

  static final _digitsOnlyFormatter = FilteringTextInputFormatter.digitsOnly;
  static final _decimalInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,2}'),
  );
}
