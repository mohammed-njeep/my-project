import 'package:flutter/material.dart';
import 'package:my_project/services/services.dart';

class AddNeighborhoodScreen extends StatefulWidget {
  const AddNeighborhoodScreen({super.key});

  @override
  State<AddNeighborhoodScreen> createState() => _AddNeighborhoodScreenState();
}

class _AddNeighborhoodScreenState extends State<AddNeighborhoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _areaController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveNeighborhood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Backend().createNeighborhood(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        areaName: _areaController.text.trim().isEmpty
            ? null
            : _areaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت إضافة الحي بنجاح')));

      _nameController.clear();
      _codeController.clear();
      _areaController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إضافة الحي: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة حي جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحي',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل اسم الحي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'رمز الحي',
                  hintText: 'مثال: NH-001',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل رمز الحي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنطقة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveNeighborhood,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('حفظ الحي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
