import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NeighborhoodsManagementView extends StatefulWidget {
  const NeighborhoodsManagementView({super.key});

  @override
  State<NeighborhoodsManagementView> createState() => _NeighborhoodsManagementViewState();
}

class _NeighborhoodsManagementViewState extends State<NeighborhoodsManagementView> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List _neighborhoods = [];
  List _filteredNeighborhoods = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenToNeighborhoodsChanges();
    _searchController.addListener(_filterNeighborhoods);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // الاستماع الحي والمباشر لتحديثات جدول neighborhoods
  void _listenToNeighborhoodsChanges() {
    supabase
        .from('neighborhoods')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _neighborhoods = List.from(data);
              _filterNeighborhoods();
              _isLoading = false;
            });
          }
        }, onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showSnackBar('خطأ في مزامنة بيانات الحارات، تحقق من الاتصال.', Colors.redAccent);
          }
        });
  }

  // دالة البحث الفوري
  void _filterNeighborhoods() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredNeighborhoods = List.from(_neighborhoods);
      } else {
        _filteredNeighborhoods = _neighborhoods.where((item) {
          final name = (item['name'] ?? '').toLowerCase();
          final region = (item['region_name'] ?? '').toLowerCase();
          final code = (item['code'] ?? '').toLowerCase();
          return name.contains(query) || region.contains(query) || code.contains(query);
        }).toList();
      }
    });
  }

  // نافذة نجاح العمليات بتصميم أبيض أنيق متوافق مع إدارة المستخدمين
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // نافذة إضافة حارة جديدة
  void _showAddNeighborhoodDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController regionController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.add_location_alt_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Text(
                      'إضافة حارة أو منطقة جديدة',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('اسم الحارة / الحي *', Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: regionController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('اسم المنطقة أو المديرية *', Icons.map_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeController,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('رمز الحارة (اختياري)', Icons.code_rounded),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final region = regionController.text.trim();
                            final code = codeController.text.trim();

                            if (name.isEmpty || region.isEmpty) {
                              _showSnackBar('يرجى ملء اسم الحارة والمنطقة أولاً', Colors.orange);
                              return;
                            }

                            final nav = Navigator.of(context);
                            setDialogState(() => isDialogLoading = true);

                            try {
                              await supabase.from('neighborhoods').insert({
                                'name': name,
                                'region_name': region,
                                'code': code.isEmpty ? null : code,
                                'is_active': true,
                              });

                              nav.pop();
                              _showSuccessDialog('تم إضافة الحارة بنجاح');
                            } on SocketException {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                            } catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('فشل إضافة الحارة: تأكد من عدم تكرار البيانات', Colors.redAccent);
                            }
                          },
                    child: isDialogLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ وإضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // نافذة تعديل بيانات الحارة (مع ضبط المؤشر وتحديث الواجهة لحظياً)
  void _showEditNeighborhoodDialog(Map<String, dynamic> neighborhood) {
    final TextEditingController nameController = TextEditingController(text: neighborhood['name']);
    final TextEditingController regionController = TextEditingController(text: neighborhood['region_name']);
    final TextEditingController codeController = TextEditingController(text: neighborhood['code']?.toString() ?? '');
    
    nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: nameController.text.length),
    );

    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.edit_location_alt_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Text(
                      'تعديل بيانات الحارة',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('اسم الحارة / الحي *', Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: regionController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('اسم المنطقة أو المديرية *', Icons.map_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeController,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('رمز الحارة (اختياري)', Icons.code_rounded),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final region = regionController.text.trim();
                            final code = codeController.text.trim();

                            if (name.isEmpty || region.isEmpty) {
                              _showSnackBar('يرجى ملء الحقول الإجبارية', Colors.orange);
                              return;
                            }

                            final nav = Navigator.of(context);
                            setDialogState(() => isDialogLoading = true);

                            try {
                              await supabase
                                  .from('neighborhoods')
                                  .update({
                                    'name': name,
                                    'region_name': region,
                                    'code': code.isEmpty ? null : code,
                                  })
                                  .eq('id', neighborhood['id']);

                              // التحديث الفوري المحلي للقائمة
                              setState(() {
                                final index = _neighborhoods.indexWhere((item) => item['id'] == neighborhood['id']);
                                if (index != -1) {
                                  _neighborhoods[index]['name'] = name;
                                  _neighborhoods[index]['region_name'] = region;
                                  _neighborhoods[index]['code'] = code.isEmpty ? null : code;
                                  _filterNeighborhoods();
                                }
                              });

                              nav.pop();
                              _showSuccessDialog('تم تعديل بيانات الحارة بنجاح');
                            } on SocketException {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                            } catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('فشل التعديل: $e', Colors.redAccent);
                            }
                          },
                    child: isDialogLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // نافذة تأكيد الحذف مع التحديث الفوري
  void _showDeleteConfirmationDialog(Map<String, dynamic> neighborhood) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('تأكيد الحذف', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'هل أنت متأكد من حذف حارة "${neighborhood['name']}"؟ قد يؤثر ذلك على بيانات الأسر التابعة لها.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  try {
                    await supabase.from('neighborhoods').delete().eq('id', neighborhood['id']);

                    // الحذف الفوري من القائمة المحلية لتحديث الواجهة لحظياً
                    setState(() {
                      _neighborhoods.removeWhere((item) => item['id'] == neighborhood['id']);
                      _filterNeighborhoods();
                    });

                    nav.pop();
                    _showSuccessDialog('تم حذف الحارة بنجاح');
                  } on SocketException {
                    nav.pop();
                    _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                  } catch (e) {
                    nav.pop();
                    _showSnackBar('تعذر الحذف لارتباط الحارة ببيانات أخرى', Colors.redAccent);
                  }
                },
                child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF0284C7), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // خلفية بيضاء رسمية متناسقة
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: const Text(
          'إدارة الحارات والمناطق',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          // شريط البحث السريع
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الحارة، المنطقة، أو الرمز...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : _filteredNeighborhoods.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty ? 'لا توجد حارات مسجلة حالياً' : 'لا توجد نتائج مطابقة لبحثك',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredNeighborhoods.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemBuilder: (context, index) {
                          final item = _filteredNeighborhoods[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0284C7).withOpacity(0.1),
                                child: const Icon(Icons.location_city_rounded, color: Color(0xFF0284C7)),
                              ),
                              title: Text(
                                item['name'] ?? 'بدون اسم',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'المنطقة: ${item['region_name'] ?? 'غير محدد'} ${item['code'] != null && item['code'].toString().isNotEmpty ? ' | الرمز: ${item['code']}' : ''}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.scale(
                                    scale: 0.85,
                                    child: Switch(
                                      value: item['is_active'] ?? true,
                                      activeColor: const Color(0xFF0284C7),
                                      activeTrackColor: const Color(0xFFBAE6FD),
                                      onChanged: (bool value) async {
                                        setState(() {
                                          item['is_active'] = value;
                                        });
                                        try {
                                          await supabase
                                              .from('neighborhoods')
                                              .update({'is_active': value})
                                              .eq('id', item['id']);
                                        } catch (e) {
                                          setState(() {
                                            item['is_active'] = !value;
                                          });
                                          _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                                        }
                                      },
                                    ),
                                  ),
                                  // زر التعديل
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20),
                                    onPressed: () => _showEditNeighborhoodDialog(item),
                                    tooltip: 'تعديل',
                                  ),
                                  // زر الحذف
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showDeleteConfirmationDialog(item),
                                    tooltip: 'حذف',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('إضافة حارة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddNeighborhoodDialog,
      ),
    );
  }
}