import 'package:supabase_flutter/supabase_flutter.dart';

class AssignmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // جلب الباحثين النشطين
  Future<List<Map<String, dynamic>>> getResearchers() async {
    final data = await _supabase
        .from('profiles')
        .select('user_id, full_name')
        .eq('role', 'researcher')
        .eq('is_active', true)
        .order('full_name');

    return List<Map<String, dynamic>>.from(data);
  }

  // جلب الحارات النشطة
  Future<List<Map<String, dynamic>>> getNeighborhoods() async {
    final data = await _supabase
        .from('neighborhoods')
        .select('id, name ')
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  // جلب جميع التكليفات
  Future<List<Map<String, dynamic>>> getAssignments() async {
    final data = await _supabase
        .from('researcher_neighborhoods')
        .select('''
          id,
          researcher_id,
          neighborhood_id,
          assigned_from,
          assigned_to,
          is_active,
          profiles!researcher_neighborhoods_researcher_id_fkey(
            full_name
          ),
          neighborhoods!researcher_neighborhoods_neighborhood_id_fkey(
            name
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // إسناد حارة إلى باحث
  Future<void> createAssignment({
    required String researcherId,
    required String neighborhoodId,
    required DateTime assignedFrom,
    DateTime? assignedTo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    if (assignedTo != null &&
        assignedTo.isBefore(
          DateTime(assignedFrom.year, assignedFrom.month, assignedFrom.day),
        )) {
      throw Exception('تاريخ النهاية غير صحيح');
    }

    await _supabase.from('researcher_neighborhoods').insert({
      'researcher_id': researcherId,
      'neighborhood_id': neighborhoodId,
      'assigned_by': userId,
      'assigned_from': _formatDate(assignedFrom),
      'assigned_to': assignedTo == null ? null : _formatDate(assignedTo),
      'is_active': true,
    });
  }

  // إنهاء تكليف
  Future<void> endAssignment(String assignmentId) async {
    await _supabase
        .from('researcher_neighborhoods')
        .update({
          'is_active': false,
          'assigned_to': _formatDate(DateTime.now()),
        })
        .eq('id', assignmentId);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
