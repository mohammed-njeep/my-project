import 'package:flutter/material.dart';
import 'package:my_project/services/services.dart';

class AddHouseholdScreen extends StatefulWidget {
  const AddHouseholdScreen({super.key});

  @override
  State<AddHouseholdScreen> createState() => _AddHouseholdScreenState();
}

class _AddHouseholdScreenState extends State<AddHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _headController = TextEditingController();
  final _spouseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _employerController = TextEditingController();
  final _housingController = TextEditingController();
  final _maleController = TextEditingController(text: '0');
  final _femaleController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _neighborhoods = [];
  String? _selectedNeighborhoodId;

  bool _loadingNeighborhoods = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _loadNeighborhoods();
  }

  Future<void> _loadNeighborhoods() async {
    try {
      final result = await Backend().getNeighborhoods();

      if (!mounted) return;

      setState(() {
        _neighborhoods = result;
        _loadError = null;
        _loadingNeighborhoods = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString();
        _loadingNeighborhoods = false;
      });
    }
  }

  Future<void> _saveHousehold() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedNeighborhoodId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر الحي أولاً')));
      return;
    }

    setState(() => _saving = true);

    try {
      final result = await Backend().createHousehold(
        householdNumber: _numberController.text.trim(),
        neighborhoodId: _selectedNeighborhoodId!,
        headName: _headController.text.trim(),
        spouseName: _spouseController.text.trim().isEmpty
            ? null
            : _spouseController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty
            ? null
            : _occupationController.text.trim(),
        employer: _employerController.text.trim().isEmpty
            ? null
            : _employerController.text.trim(),
        housingType: _housingController.text.trim().isEmpty
            ? null
            : _housingController.text.trim(),
        maleCount: int.parse(_maleController.text) ?? 0,
        femaleCount: int.parse(_femaleController.text) ?? 0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حفظ الأسرة بنجاح. الرقم: ')));

      _clearForm();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل حفظ الأسرة: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _clearForm() {
    _numberController.clear();
    _headController.clear();
    _spouseController.clear();
    _phoneController.clear();
    _occupationController.clear();
    _employerController.clear();
    _housingController.clear();
    _maleController.text = '0';
    _femaleController.text = '0';
    _notesController.clear();

    setState(() => _selectedNeighborhoodId = null);
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب';
          }

          if (keyboardType == TextInputType.number &&
              value != null &&
              value.isNotEmpty &&
              int.tryParse(value) == null) {
            return 'أدخل رقمًا صحيحًا';
          }

          if (keyboardType == TextInputType.number &&
              value != null &&
              value.isNotEmpty &&
              int.tryParse(value) != null &&
              int.parse(value) < 0) {
            return 'لا يمكن إدخال رقم سالب';
          }

          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _headController.dispose();
    _spouseController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _employerController.dispose();
    _housingController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة أسرة جديدة')),
      body: _loadingNeighborhoods
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تعذر تحميل الأحياء'),
                    const SizedBox(height: 8),
                    Text(_loadError!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadingNeighborhoods = true;
                        });
                        _loadNeighborhoods();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : _neighborhoods.isEmpty
          ? const Center(child: Text('لا توجد أحياء. أضف حيًا أولًا.'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedNeighborhoodId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'اختر الحي',
                      border: OutlineInputBorder(),
                    ),
                    items: _neighborhoods.map((n) {
                      return DropdownMenuItem<String>(
                        value: n['id'].toString(),
                        child: Text('${n['name']} (${n['code']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedNeighborhoodId = value;
                      });
                    },
                    validator: (value) => value == null ? 'اختر الحي' : null,
                  ),
                  const SizedBox(height: 16),

                  _textField(
                    'رقم الأسرة',
                    _numberController,
                    requiredField: true,
                  ),
                  _textField(
                    'اسم رب الأسرة',
                    _headController,
                    requiredField: true,
                  ),
                  _textField('اسم الزوجة أو الزوج', _spouseController),
                  _textField(
                    'رقم الهاتف',
                    _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _textField('المهنة', _occupationController),
                  _textField('جهة العمل', _employerController),
                  _textField('نوع السكن', _housingController),
                  _textField(
                    'عدد الذكور',
                    _maleController,
                    requiredField: true,
                    keyboardType: TextInputType.number,
                  ),
                  _textField(
                    'عدد الإناث',
                    _femaleController,
                    requiredField: true,
                    keyboardType: TextInputType.number,
                  ),
                  _textField('ملاحظات', _notesController),
                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _saving ? null : _saveHousehold,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ الأسرة'),
                  ),
                ],
              ),
            ),
    );
  }
}
