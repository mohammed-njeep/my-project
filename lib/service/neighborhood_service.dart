import 'package:supabase_flutter/supabase_flutter.dart';

class NeighborhoodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //  جلب الحارات
  Future<List<Map<String, dynamic>>> getNeighborhoods() async {
    final data = await _supabase
        .from('neighborhoods')
        .select()
        .isFilter('deleted_at', null)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  //  إنشاء حارة جديدة
  Future<void> createNeighborhood({
    required String regionName,
    required String name,
    String? code,
    bool isActive = true,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    await _supabase.from('neighborhoods').insert({
      'region_name': regionName,
      'name': name,
      'code': code,
      'is_active': isActive,
      'created_by': userId,
    });
  }

  //  تعديل حارة
  Future<void> updateNeighborhood({
    required String id,
    required String regionName,
    required String name,
    String? code,
    required bool isActive,
  }) async {
    await _supabase
        .from('neighborhoods')
        .update({
          'region_name': regionName,
          'name': name,
          'code': code,
          'is_active': isActive,
        })
        .eq('id', id);
  }

  //  حذف حارة
  Future<void> deleteNeighborhood(String id) async {
    await _supabase.from('neighborhoods').delete().eq('id', id);
  }
}
