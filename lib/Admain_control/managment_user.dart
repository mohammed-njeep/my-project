import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List _users = [];

  @override
  void initState() {
    super.initState();
    _listenToUsersChanges();
  }

  // الاستماع المباشر والحي لتحديثات جدول profiles تلقائياً
  void _listenToUsersChanges() {
    supabase
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .order('created_at', ascending: false)
        .listen((data) {
          if (mounted) {
            setState(() {
              _users = List.from(data);
              _isLoading = false;
            });
          }
        }, onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showSnackBar('خطأ في مزامنة البيانات، تحقق من الاتصال.', Colors.redAccent);
          }
        });
  }

  // نافذة نجاح العمليات بتصميم أبيض أنيق
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

  // نافذة إضافة مستخدم جديد بتصميم رسمي فاتح
  void _showAddUserDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = 'researcher';
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
                    Icon(Icons.person_add_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Text(
                      'إضافة مستخدم جديد للنظام',
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
                        decoration: _dialogInputDecoration('الاسم الكامل', Icons.person_outline),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('البريد الإلكتروني', Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('كلمة المرور (6 أحرف على الأقل)', Icons.lock_outline),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                        decoration: _dialogInputDecoration('الدور الوظيفي والصلاحيات', Icons.badge_outlined),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                          DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                          DropdownMenuItem(value: 'researcher', child: Text('باحث ميداني')),
                          DropdownMenuItem(value: 'viewer', child: Text('مشاهد / مدقق')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
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
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (name.isEmpty || email.isEmpty || password.isEmpty) {
                              _showSnackBar('يرجى ملء جميع الحقول المطلوبة', Colors.orange);
                              return;
                            }

                            bool emailValid = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            ).hasMatch(email);

                            if (!emailValid) {
                              _showSnackBar('البريد الإلكتروني غير صالح، يرجى كتابة صيغة صحيحة', Colors.redAccent);
                              return;
                            }

                            if (password.length < 6) {
                              _showSnackBar('كلمة المرور قصيرة، يجب أن تكون 6 أحرف على الأقل', Colors.orange);
                              return;
                            }

                            final nav = Navigator.of(context);
                            setDialogState(() => isDialogLoading = true);

                            try {
                              await supabase.auth.signUp(
                                email: email,
                                password: password,
                                data: {'full_name': name, 'role': selectedRole},
                              );

                              nav.pop();
                              _showSuccessDialog('تم إضافة المستخدم بنجاح');
                            } on AuthException catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              String msg = 'حدث خطأ أثناء الإنشاء';
                              if (e.message.contains('already registered')) {
                                msg = 'عذراً، البريد الإلكتروني مستخدم مسبقاً لحساب آخر';
                              } else {
                                msg = 'خطأ: ${e.message}';
                              }
                              _showSnackBar(msg, Colors.redAccent);
                            } catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('لا يتوفر اتصال بالإنترنت، تحقق من الشبكة', Colors.redAccent);
                            }
                          },
                    child: isDialogLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ وإنشاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // نافذة تعديل بيانات المستخدم
  void _showEditUserDialog(Map<String, dynamic> user) {
    final TextEditingController nameController = TextEditingController(text: user['full_name']);
    nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: nameController.text.length),
    );

    String selectedRole = user['role'] ?? 'researcher';
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
                    Icon(Icons.edit_rounded, color: Color(0xFF0284C7)),
                    SizedBox(width: 10),
                    Text(
                      'تعديل بيانات المستخدم',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('الاسم الكامل', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: _dialogInputDecoration('الدور الوظيفي', Icons.badge_outlined),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                        DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                        DropdownMenuItem(value: 'researcher', child: Text('باحث ميداني')),
                        DropdownMenuItem(value: 'viewer', child: Text('مشاهد / مدقق')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                  ],
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
                            if (name.isEmpty) {
                              _showSnackBar('يرجى كتابة الاسم الكامل', Colors.orange);
                              return;
                            }

                            final nav = Navigator.of(context);
                            setDialogState(() => isDialogLoading = true);

                            try {
                              await supabase
                                  .from('profiles')
                                  .update({
                                    'full_name': name,
                                    'role': selectedRole,
                                  })
                                  .eq('user_id', user['user_id']);

                              setState(() {
                                final index = _users.indexWhere((u) => u['user_id'] == user['user_id']);
                                if (index != -1) {
                                  _users[index]['full_name'] = name;
                                  _users[index]['role'] = selectedRole;
                                }
                              });

                              nav.pop();
                              _showSuccessDialog('تم تعديل بيانات المستخدم بنجاح');
                            } on SocketException {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                            } catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
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

  // نافذة تأكيد الحذف
  void _showDeleteConfirmationDialog(Map<String, dynamic> user) {
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
                Text(
                  'تأكيد الحذف النهائي',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'هل أنت متأكد من حذف المستخدم "${user['full_name']}"؟ لا يمكن التراجع عن هذا الإجراء.',
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
                    await supabase
                        .from('profiles')
                        .delete()
                        .eq('user_id', user['user_id']);

                    setState(() {
                      _users.removeWhere((u) => u['user_id'] == user['user_id']);
                    });

                    nav.pop();
                    _showSuccessDialog('تم حذف المستخدم بنجاح');
                  } on SocketException {
                    nav.pop();
                    _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                  } catch (e) {
                    nav.pop();
                    _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
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

  // دالة الشارة الرسمية الفاتحة
  Widget _getRoleBadge(String role) {
    String label = 'باحث';
    Color color = const Color(0xFF0284C7);

    if (role == 'admin') {
      label = 'مدير النظام';
      color = const Color(0xFFD97706);
    } else if (role == 'supervisor') {
      label = 'مشرف';
      color = const Color(0xFF059669);
    } else if (role == 'viewer') {
      label = 'مدقق';
      color = const Color(0xFF7C3AED);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // خلفية بيضاء رسمية فاتحة ونظيفة
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: const Text(
          'إدارة المستخدمين والصلاحيات',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : _users.isEmpty
              ? const Center(
                  child: Text('لا يوجد مستخدمون مسجلون حالياً', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = _users[index];
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
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0284C7)),
                        ),
                        title: Text(
                          user['full_name'] ?? 'بدون اسم',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              _getRoleBadge(user['role'] ?? 'researcher'),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: user['is_active'] ?? true,
                                activeColor: const Color(0xFF0284C7),
                                activeTrackColor: const Color(0xFFBAE6FD),
                                onChanged: (bool value) async {
                                  setState(() {
                                    _users[index]['is_active'] = value;
                                  });
                                  try {
                                    await supabase
                                        .from('profiles')
                                        .update({'is_active': value})
                                        .eq('user_id', user['user_id']);
                                  } catch (e) {
                                    setState(() {
                                      _users[index]['is_active'] = !value;
                                    });
                                    _showSnackBar('لا يتوفر اتصال بالإنترنت', Colors.redAccent);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 20),
                              onPressed: () => _showEditUserDialog(user),
                              tooltip: 'تعديل',
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _showDeleteConfirmationDialog(user),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('إضافة مستخدم جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddUserDialog,
      ),
    );
  }
}