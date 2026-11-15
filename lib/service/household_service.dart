import 'package:supabase_flutter/supabase_flutter.dart';

class HouseholdService {
  final SupabaseClient _supabase = Supabase.instance.client;

  //  جلب الأسر
  Future<List<Map<String, dynamic>>> getHouseholds() async {
    final data = await _supabase
        .from('households')
        .select('''
          *,
          neighborhoods (
            name
            
          )
        ''')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  //  جلب أسرة واحدة
  Future<Map<String, dynamic>> getHouseholdById(String id) async {
    final data = await _supabase
        .from('households')
        .select()
        .eq('id', id)
        .single();

    return Map<String, dynamic>.from(data);
  }

  //  إنشاء أسرة جديدة
  Future<void> createHousehold({
    required String neighborhoodId,
    required String headName,
    String? phone,
    String? occupation,
    String? workplace,
    String? housingType,
    String? wifeName,
    String? wifeIdType,
    String? wifeIdNumber,
    int malesCount = 0,
    int femalesCount = 0,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (headName.trim().isEmpty) {
      throw Exception('اسم رب الأسرة مطلوب');
    }

    if (malesCount < 0 || femalesCount < 0) {
      throw Exception('عدد الذكور والإناث لا يمكن أن يكون سالباً');
    }

    await _supabase.from('households').insert({
      'neighborhood_id': neighborhoodId,
      'head_name': headName,
      'wife_name': wifeName,
      'phone': phone,
      'occupation': occupation,
      'workplace': workplace,
      'housing_type': housingType,
      'males_count': malesCount,
      'females_count': femalesCount,
      'notes': notes,
      'created_by': userId,
      'updated_by': userId,
    });
  }

  //  تعديل بيانات أسرة
  Future<void> updateHousehold({
    required String id,
    required String neighborhoodId,
    required String headName,
    String? phone,
    String? occupation,
    String? workplace,
    String? housingType,
    String? wifeName,
    String? wifeIdType,
    String? wifeIdNumber,
    required int malesCount,
    required int femalesCount,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (headName.trim().isEmpty) {
      throw Exception('اسم رب الأسرة مطلوب');
    }

    if (malesCount < 0 || femalesCount < 0) {
      throw Exception('عدد الذكور والإناث لا يمكن أن يكون سالباً');
    }

    await _supabase
        .from('households')
        .update({
          'neighborhood_id': neighborhoodId,
          'head_name': headName.trim(),
          'phone': phone,
          'occupation': occupation,
          'workplace': workplace,
          'housing_type': housingType,
          'wife_name': wifeName,
          'wife_id_type': wifeIdType,
          'wife_id_number': wifeIdNumber,
          'males_count': malesCount,
          'females_count': femalesCount,
          'notes': notes,
          'updated_by': userId,
        })
        .eq('id', id);
  }

  //  حذف أسرة
  Future<void> deleteHousehold(String id) async {
    await _supabase.from('households').delete().eq('id', id);
  }
}
