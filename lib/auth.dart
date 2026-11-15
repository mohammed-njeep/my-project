import 'package:supabase_flutter/supabase_flutter.dart';

class Authclass {
  final supabase = Supabase.instance.client;

  Future<void> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    // التحقق من الدور المسموح
    const allowedRoles = ['admin', 'manager', 'researcher'];

    if (!allowedRoles.contains(role)) {
      throw Exception('الدور المحدد غير صحيح');
    }

    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('تعذر إنشاء الحساب');
    }

    // إضافة معلومات المستخدم إلى جدول profiles
    await supabase.from('profiles').upsert({
      'user_id': user.id,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'role': role.trim(),
    });
  }

  login(String email, String pass) async {
    await supabase.auth.signInWithPassword(password: pass, email: email);
  }

  logout() {}
}
