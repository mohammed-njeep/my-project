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
    _listenToUsersChanges(); // تفعيل التحديث الحي التلقائي
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
            _showSnackBar('خطأ في المزامنة: $error', Colors.redAccent);
          }
        });
  }

  // نافذة نجاح الإضافة 
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0A192F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 65,
                ),
                const SizedBox(height: 16),
                const Text(
                  'تم إضافة المستخدم بنجاح',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'تم إنشاء الحساب وحفظ الصلاحيات في النظام',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        color: Color(0xFF0A192F),
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

  // نافذة إضافة مستخدم جديد 
  void _showAddUserDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = 'researcher'; // الدور الافتراضي
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
                backgroundColor: const Color(0xFF0A192F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.person_add_rounded, color: Color(0xFF00E5FF)),
                    SizedBox(width: 10),
                    Text(
                      'إضافة مستخدم جديد',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration('الاسم الكامل', Icons.person_outline),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration('البريد الإلكتروني', Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration('كلمة المرور', Icons.lock_outline),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration('الدور الوظيفي', Icons.badge_outlined),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                          DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                          DropdownMenuItem(value: 'researcher', child: Text('باحث')),
                          DropdownMenuItem(value: 'viewer', child: Text('مشاهد / مدقق')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedRole = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoading ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final email = emailController.text.trim();

                            if (nameController.text.trim().isEmpty ||
                                email.isEmpty ||
                                passwordController.text.trim().isEmpty) {
                              _showSnackBar('يرجى ملء جميع الحقول المطلوبة', Colors.orange);
                              return;
                            }

                            bool emailValid = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            ).hasMatch(email);

                            if (!emailValid) {
                              _showSnackBar('البريد الإلكتروني غير صالح، يرجى كتابة إيميل صحيح', Colors.redAccent);
                              return;
                            }

                            final nav = Navigator.of(context);
                            setDialogState(() => isDialogLoading = true);

                            try {
                              // إنشاء المستخدم وتمرير الاسم والدور في الـ data 
                              // (الـ Trigger في قاعدة البيانات سيتكفل بنسخه إلى جدول profiles تلقائياً)
                              await supabase.auth.signUp(
                                email: email,
                                password: passwordController.text.trim(),
                                data: {
                                  'full_name': nameController.text.trim(),
                                  'role': selectedRole,
                                },
                              );

                              nav.pop();
                              _showSuccessDialog();
                            } catch (e) {
                              setDialogState(() => isDialogLoading = false);
                              _showSnackBar('فشل الإنشاء: $e', Colors.redAccent);
                            }
                          },
                    child: isDialogLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Color(0xFF0A192F), strokeWidth: 2),
                          )
                        : const Text('حفظ وإنشاء', style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة المستخدمين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : _users.isEmpty
              ? const Center(child: Text('لا يوجد مستخدمون مسجلون حالياً', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: _users.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF00E5FF)),
                        ),
                        title: Text(
                          user['full_name'] ?? 'بدون اسم',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'الدور: ${user['role']}',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        trailing: Switch(
                          value: user['is_active'] ?? true,
                          activeColor: const Color(0xFF00E5FF),
                          activeTrackColor: const Color(0xFF0288D1).withOpacity(0.5),
                          onChanged: (bool value) async {
                            await supabase
                                .from('profiles')
                                .update({'is_active': value})
                                .eq('user_id', user['user_id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E5FF),
        icon: const Icon(Icons.person_add_rounded, color: Color(0xFF0A192F)),
        label: const Text('إضافة مستخدم', style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
        onPressed: _showAddUserDialog,
      ),
    );
  }
}