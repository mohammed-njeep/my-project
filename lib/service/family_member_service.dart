import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyMemberService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //  جلب أفراد أسرة محددة
  Future<List<Map<String, dynamic>>> getFamilyMembers(
    String householdId,
  ) async {
    final data = await _supabase
        .from('family_members')
        .select()
        .eq('household_id', householdId)
        .isFilter('deleted_at', null)
        .order('full_name');

    return List<Map<String, dynamic>>.from(data);
  }

  //  إضافة فرد جديد
  Future<void> createFamilyMember({
    required String householdId,
    required String fullName,
    required String relationship,
    required String gender,
    DateTime? birthDate,
    String? occupation,
    String? phone,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (fullName.trim().isEmpty) {
      throw Exception('اسم الفرد مطلوب');
    }

    if (!['male', 'female'].contains(gender)) {
      throw Exception('الجنس يجب أن يكون male أو female');
    }

    const validRelationships = [
      'head',
      'spouse',
      'son',
      'daughter',
      'father',
      'mother',
      'brother',
      'sister',
      'other',
    ];

    if (!validRelationships.contains(relationship)) {
      throw Exception('صلة القرابة غير صحيحة');
    }

    await _supabase.from('family_members').insert({
      'household_id': householdId,
      'full_name': fullName.trim(),
      'relationship': relationship,
      'gender': gender,
      'birth_date': birthDate == null ? null : _formatDate(birthDate),
      'occupation': occupation,
      'phone': phone,
      'created_by': userId,
      'updated_by': userId,
    });
  }

  //  تعديل بيانات فرد
  Future<void> updateFamilyMember({
    required String id,
    required String fullName,
    required String relationship,
    required String gender,
    DateTime? birthDate,
    String? occupation,
    String? phone,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (fullName.trim().isEmpty) {
      throw Exception('اسم الفرد مطلوب');
    }

    if (!['male', 'female'].contains(gender)) {
      throw Exception('الجنس يجب أن يكون male أو female');
    }

    const validRelationships = [
      'head',
      'spouse',
      'son',
      'daughter',
      'father',
      'mother',
      'brother',
      'sister',
      'other',
    ];

    if (!validRelationships.contains(relationship)) {
      throw Exception('صلة القرابة غير صحيحة');
    }

    await _supabase
        .from('family_members')
        .update({
          'full_name': fullName.trim(),
          'relationship': relationship,
          'gender': gender,
          'birth_date': birthDate == null ? null : _formatDate(birthDate),
          'occupation': occupation,
          'phone': phone,
          'updated_by': userId,
        })
        .eq('id', id);
  }

  //  حذف فرد
  Future<void> deleteFamilyMember(String id) async {
    await _supabase.from('family_members').delete().eq('id', id);
  }

  // تنسيق التاريخ إلى YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
