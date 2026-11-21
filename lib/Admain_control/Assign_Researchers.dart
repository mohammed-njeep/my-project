import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorAssignmentsView extends StatefulWidget {
  const SupervisorAssignmentsView({super.key});

  @override
  State<SupervisorAssignmentsView> createState() => _SupervisorAssignmentsViewState();
}

class _SupervisorAssignmentsViewState extends State<SupervisorAssignmentsView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<_AssignedGroupItem> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignedList();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('connection')) {
      return 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
    }
    if (text.contains('42501') || text.contains('row-level security') || text.contains('permission')) {
      return 'لا تملك الصلاحية الكافية لإتمام هذه العملية.';
    }
    if (text.contains('23505') || text.contains('duplicate') || text.contains('unique')) {
      return 'يوجد تكليف مسجل مسبقاً بنفس البيانات والتاريخ.';
    }
    if (text.contains('23514') || text.contains('check')) {
      return 'تاريخ نهاية التكليف يجب أن يكون مساوياً أو بعد تاريخ البداية.';
    }
    return 'تعذر إتمام العملية حالياً. يرجى المحاولة مرة أخرى.';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF1E88E5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadAssignedList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todayStr = _formatDate(DateTime.now());

      final supRows = await _supabase
          .from('supervisor_neighborhoods')
          .select('id, supervisor_id, neighborhood_id, assigned_from, assigned_to, is_active')
          .eq('is_active', true)
          .order('assigned_from', ascending: false);

      final resRows = await _supabase
          .from('researcher_neighborhoods')
          .select('researcher_id, neighborhood_id, assigned_from, assigned_to, is_active')
          .eq('is_active', true);

      final profilesRows = await _supabase
          .from('profiles')
          .select('user_id, full_name, supervisor_id');

      final neighborhoodsRows = await _supabase
          .from('neighborhoods')
          .select('id, name, region_name');

      final Map<String, String> userNames = {
        for (final p in List.from(profilesRows))
          p['user_id'].toString(): (p['full_name']?.toString().trim().isNotEmpty == true
              ? p['full_name'].toString()
              : 'مستخدم بدون اسم'),
      };

      final Map<String, String> neighborhoodNames = {
        for (final n in List.from(neighborhoodsRows))
          n['id'].toString(): (n['region_name']?.toString().trim().isNotEmpty == true
              ? '${n['name']} (${n['region_name']})'
              : (n['name']?.toString() ?? 'منطقة غير محددة')),
      };

      final List activeResList = List.from(resRows)
          .where((r) {
        final assignedTo = r['assigned_to']?.toString();
        return assignedTo == null || assignedTo.isEmpty || assignedTo.compareTo(todayStr) >= 0;
      }).toList();

      final List<_AssignedGroupItem> items = [];

      for (final sup in List.from(supRows)) {
        final assignedTo = sup['assigned_to']?.toString();
        final isCurrentlyActive =
            assignedTo == null || assignedTo.isEmpty || assignedTo.compareTo(todayStr) >= 0;

        final supervisorId = sup['supervisor_id'].toString();
        final neighborhoodId = sup['neighborhood_id'].toString();
        final assignedFrom = sup['assigned_from']?.toString() ?? '-';

        final Set<String> researchersInGroup = {};

        for (final r in activeResList) {
          if (r['neighborhood_id'].toString() == neighborhoodId) {
            final resId = r['researcher_id'].toString();
            final resName = userNames[resId];
            if (resName != null) {
              researchersInGroup.add(resName);
            }
          }
        }

        // إضافة الباحثين المرتبطين مباشرة بالمشرف إن لم يظهروا في قائمة الحارة
        for (final p in List.from(profilesRows)) {
          if (p['supervisor_id']?.toString() == supervisorId) {
            final resName = userNames[p['user_id'].toString()];
            if (resName != null) {
              researchersInGroup.add(resName);
            }
          }
        }

        items.add(
          _AssignedGroupItem(
            id: sup['id'].toString(),
            supervisorName: userNames[supervisorId] ?? 'مشرف غير معروف',
            neighborhoodName: neighborhoodNames[neighborhoodId] ?? 'منطقة غير معروفة',
            researcherNames: researchersInGroup.toList(),
            assignedFrom: assignedFrom,
            assignedTo: (assignedTo == null || assignedTo.isEmpty) ? 'مفتوح' : assignedTo,
            isActiveNow: isCurrentlyActive,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _assignments = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddAssignmentDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddSupervisorAssignmentDialog(
        formatDate: _formatDate,
        friendlyError: _friendlyError,
      ),
    );

    if (created == true) {
      await _loadAssignedList();
      _showMessage('تم حفظ التكليف وعرضه في القائمة بنجاح.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'إسناد المشرفين والمناطق والباحثين',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث القائمة',
              onPressed: _loadAssignedList,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0288D1)),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddAssignmentDialog,
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة إسناد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0288D1)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 42),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loadAssignedList,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_assignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_ind, size: 42, color: Color(0xFF0288D1)),
              ),
              const SizedBox(height: 14),
              const Text(
                'لا توجد تكليفات مسندة حتى الآن',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'اضغط على زر "إضافة إسناد" بالأسفل لربط مشرف بمنطقة وباحثين.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0288D1),
      onRefresh: _loadAssignedList,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _assignments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _assignments[index];
          return _AssignmentCard(item: item);
        },
      ),
    );
  }
}

class _AssignedGroupItem {
  final String id;
  final String supervisorName;
  final String neighborhoodName;
  final List<String> researcherNames;
  final String assignedFrom;
  final String assignedTo;
  final bool isActiveNow;

  const _AssignedGroupItem({
    required this.id,
    required this.supervisorName,
    required this.neighborhoodName,
    required this.researcherNames,
    required this.assignedFrom,
    required this.assignedTo,
    required this.isActiveNow,
  });
}

class _AssignmentCard extends StatelessWidget {
  final _AssignedGroupItem item;

  const _AssignmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.supervisor_account_rounded,
                  color: Color(0xFF0288D1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.supervisorName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF0288D1)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.neighborhoodName,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: item.isActiveNow ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isActiveNow ? 'ساري' : 'منتهي',
                  style: TextStyle(
                    color: item.isActiveNow ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'من: ${item.assignedFrom}',
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5),
                ),
                const SizedBox(width: 16),
                Text(
                  'إلى: ${item.assignedTo}',
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'الباحثون المشرف عليهم:',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (item.researcherNames.isEmpty)
            const Text(
              'لا يوجد باحثون مسندون حالياً',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.researcherNames
                  .map(
                    (name) => Chip(
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      avatar: const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Color(0xFF0288D1),
                      ),
                      label: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AddSupervisorAssignmentDialog extends StatefulWidget {
  final String Function(DateTime) formatDate;
  final String Function(Object) friendlyError;

  const _AddSupervisorAssignmentDialog({
    required this.formatDate,
    required this.friendlyError,
  });

  @override
  State<_AddSupervisorAssignmentDialog> createState() => _AddSupervisorAssignmentDialogState();
}

class _AddSupervisorAssignmentDialogState extends State<_AddSupervisorAssignmentDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoadingData = true;
  bool _isSaving = false;
  String? _dialogError;

  List _supervisors = [];
  List _neighborhoods = [];
  List _researchers = [];

  String? _selectedSupervisorId;
  String? _selectedNeighborhoodId;
  final Set<String> _selectedResearcherIds = {};

  DateTime _assignedFrom = DateTime.now();
  DateTime? _assignedTo;

  @override
  void initState() {
    super.initState();
    _loadAvailableOptions();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assignedFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0288D1)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dialogError = null;
        _assignedFrom = picked;
        if (_assignedTo != null && _assignedTo!.isBefore(_assignedFrom)) {
          _assignedTo = _assignedFrom;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = _assignedTo ?? _assignedFrom;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_assignedFrom) ? _assignedFrom : initial,
      firstDate: _assignedFrom,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0288D1)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dialogError = null;
        _assignedTo = picked;
      });
    }
  }

  Future<void> _loadAvailableOptions() async {
    setState(() {
      _isLoadingData = true;
      _dialogError = null;
    });

    try {
      final todayStr = widget.formatDate(DateTime.now());

      final activeSupRows = await _supabase
          .from('supervisor_neighborhoods')
          .select('supervisor_id, neighborhood_id, assigned_to')
          .eq('is_active', true);

      final activeResRows = await _supabase
          .from('researcher_neighborhoods')
          .select('researcher_id, assigned_to')
          .eq('is_active', true);

      final Set<String> busySupervisorIds = {};
      final Set<String> busyNeighborhoodIds = {};
      final Set<String> busyResearcherIds = {};

      for (final row in List.from(activeSupRows)) {
        final assignedTo = row['assigned_to']?.toString();
        if (assignedTo == null || assignedTo.isEmpty || assignedTo.compareTo(todayStr) >= 0) {
          if (row['supervisor_id'] != null) busySupervisorIds.add(row['supervisor_id'].toString());
          if (row['neighborhood_id'] != null) {
            busyNeighborhoodIds.add(row['neighborhood_id'].toString());
          }
        }
      }

      for (final row in List.from(activeResRows)) {
        final assignedTo = row['assigned_to']?.toString();
        if (assignedTo == null || assignedTo.isEmpty || assignedTo.compareTo(todayStr) >= 0) {
          if (row['researcher_id'] != null) busyResearcherIds.add(row['researcher_id'].toString());
        }
      }

      final supervisorsRes = await _supabase
          .from('profiles')
          .select('user_id, full_name')
          .eq('role', 'supervisor')
          .eq('is_active', true);

      final neighborhoodsRes = await _supabase
          .from('neighborhoods')
          .select('id, name, region_name')
          .eq('is_active', true);

      final researchersRes = await _supabase
          .from('profiles')
          .select('user_id, full_name')
          .eq('role', 'researcher')
          .eq('is_active', true);

      final availableSupervisors = List.from(supervisorsRes)
          .where((s) => !busySupervisorIds.contains(s['user_id'].toString()))
          .toList();

      final availableNeighborhoods = List.from(neighborhoodsRes)
          .where((n) => !busyNeighborhoodIds.contains(n['id'].toString()))
          .toList();

      final availableResearchers = List.from(researchersRes)
          .where((r) => !busyResearcherIds.contains(r['user_id'].toString()))
          .toList();

      if (!mounted) return;
      setState(() {
        _supervisors = availableSupervisors;
        _neighborhoods = availableNeighborhoods;
        _researchers = availableResearchers;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dialogError = widget.friendlyError(e);
        _isLoadingData = false;
      });
    }
  }

  Future<void> _saveNewAssignment() async {
    setState(() => _dialogError = null);

    if (_selectedSupervisorId == null) {
      setState(() => _dialogError = 'يرجى اختيار المشرف أولاً.');
      return;
    }
    if (_selectedNeighborhoodId == null) {
      setState(() => _dialogError = 'يرجى اختيار المنطقة أو الحارة أولاً.');
      return;
    }
    if (_selectedResearcherIds.isEmpty) {
      setState(() => _dialogError = 'يرجى اختيار باحث واحد على الأقل.');
      return;
    }
    if (_assignedTo != null && _assignedTo!.isBefore(_assignedFrom)) {
      setState(
        () => _dialogError = 'تاريخ نهاية التكليف يجب أن يكون مساوياً أو بعد تاريخ البداية.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final startDateStr = widget.formatDate(_assignedFrom);
      final endDateStr = _assignedTo != null ? widget.formatDate(_assignedTo!) : null;

      await _supabase.from('supervisor_neighborhoods').upsert(
        {
          'supervisor_id': _selectedSupervisorId,
          'neighborhood_id': _selectedNeighborhoodId,
          'assigned_by': currentUserId,
          'assigned_from': startDateStr,
          'assigned_to': endDateStr,
          'is_active': true,
        },
        onConflict: 'supervisor_id,neighborhood_id,assigned_from',
      );

      for (final researcherId in _selectedResearcherIds) {
        await _supabase.from('researcher_neighborhoods').upsert(
          {
            'researcher_id': researcherId,
            'neighborhood_id': _selectedNeighborhoodId,
            'assigned_by': currentUserId,
            'assigned_from': startDateStr,
            'assigned_to': endDateStr,
            'is_active': true,
          },
          onConflict: 'researcher_id,neighborhood_id,assigned_from',
        );

        await _supabase
            .from('profiles')
            .update({'supervisor_id': _selectedSupervisorId})
            .eq('user_id', researcherId);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _dialogError = widget.friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إضافة إسناد جديد',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: _isLoadingData
            ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))),
              )
            : SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFFC62828), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dialogError!,
                                  style: const TextStyle(color: Color(0xFFC62828), fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        value: _selectedSupervisorId,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          labelText: _supervisors.isEmpty
                              ? 'لا يوجد مشرفون متاحون حالياً'
                              : 'اختر المشرف',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _supervisors.map((sup) {
                          return DropdownMenuItem<String>(
                            value: sup['user_id'].toString(),
                            child: Text(sup['full_name'] ?? 'مشرف'),
                          );
                        }).toList(),
                        onChanged: _supervisors.isEmpty
                            ? null
                            : (val) => setState(() {
                                  _dialogError = null;
                                  _selectedSupervisorId = val;
                                }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedNeighborhoodId,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          labelText: _neighborhoods.isEmpty
                              ? 'لا توجد مناطق متاحة حالياً'
                              : 'اختر المنطقة / الحارة',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _neighborhoods.map((neigh) {
                          final region = neigh['region_name']?.toString() ?? '';
                          final name = neigh['name']?.toString() ?? '';
                          return DropdownMenuItem<String>(
                            value: neigh['id'].toString(),
                            child: Text(region.isNotEmpty ? '$name ($region)' : name),
                          );
                        }).toList(),
                        onChanged: _neighborhoods.isEmpty
                            ? null
                            : (val) => setState(() {
                                  _dialogError = null;
                                  _selectedNeighborhoodId = val;
                                }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _pickStartDate,
                              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0288D1)),
                              label: Text(
                                'بداية: ${widget.formatDate(_assignedFrom)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _pickEndDate,
                              icon: const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFFEF6C00)),
                              label: Text(
                                _assignedTo == null
                                    ? 'نهاية: غير محدد'
                                    : 'نهاية: ${widget.formatDate(_assignedTo!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (_assignedTo != null)
                            IconButton(
                              tooltip: 'إلغاء تاريخ النهاية',
                              onPressed: () => setState(() => _assignedTo = null),
                              icon: const Icon(Icons.clear, color: Color(0xFFD32F2F), size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'اختر الباحثين التابعين لهذا التكليف:',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 190),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _researchers.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text(
                                    'لا يوجد باحثون متاحون حالياً.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _researchers.length,
                                itemBuilder: (context, index) {
                                  final res = _researchers[index];
                                  final id = res['user_id'].toString();
                                  final isChecked = _selectedResearcherIds.contains(id);
                                  return CheckboxListTile(
                                    value: isChecked,
                                    activeColor: const Color(0xFF0288D1),
                                    title: Text(
                                      res['full_name']?.toString() ?? 'باحث',
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                                    ),
                                    onChanged: (checked) {
                                      setState(() {
                                        _dialogError = null;
                                        if (checked == true) {
                                          _selectedResearcherIds.add(id);
                                        } else {
                                          _selectedResearcherIds.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSaving ? null : _saveNewAssignment,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}