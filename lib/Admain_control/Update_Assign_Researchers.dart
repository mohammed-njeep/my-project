import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageAssignmentsView extends StatefulWidget {
  const ManageAssignmentsView({super.key});

  @override
  State<ManageAssignmentsView> createState() => _ManageAssignmentsViewState();
}

class _ManageAssignmentsViewState extends State<ManageAssignmentsView> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<_EditableAssignmentItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str);
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
      return 'لا تملك الصلاحية الكافية لتعديل أو حذف هذا التكليف.';
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
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF0288D1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todayStr = _formatDate(DateTime.now());

      final supRows = await _supabase
          .from('supervisor_neighborhoods')
          .select('id, supervisor_id, neighborhood_id, assigned_from, assigned_to, is_active')
          .order('assigned_from', ascending: false);

      final resRows = await _supabase
          .from('researcher_neighborhoods')
          .select('researcher_id, neighborhood_id, assigned_from, assigned_to, is_active');

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

      final List<_EditableAssignmentItem> loaded = [];

      for (final sup in List.from(supRows)) {
        final supId = sup['supervisor_id'].toString();
        final neighId = sup['neighborhood_id'].toString();
        final fromStr = sup['assigned_from']?.toString() ?? _formatDate(DateTime.now());
        final toStr = sup['assigned_to']?.toString();
        final isActive = sup['is_active'] == true;

        final isExpiredByDate =
            toStr != null && toStr.isNotEmpty && toStr.compareTo(todayStr) < 0;

        final Set<String> researcherIdsInGroup = {};
        final List<String> researcherNamesInGroup = [];

        for (final r in List.from(resRows)) {
          if (r['neighborhood_id'].toString() == neighId && r['is_active'] == true) {
            final rId = r['researcher_id'].toString();
            if (researcherIdsInGroup.add(rId)) {
              researcherNamesInGroup.add(userNames[rId] ?? 'باحث');
            }
          }
        }

        for (final p in List.from(profilesRows)) {
          if (p['supervisor_id']?.toString() == supId) {
            final rId = p['user_id'].toString();
            if (researcherIdsInGroup.add(rId)) {
              researcherNamesInGroup.add(userNames[rId] ?? 'باحث');
            }
          }
        }

        loaded.add(
          _EditableAssignmentItem(
            id: sup['id'].toString(),
            supervisorId: supId,
            supervisorName: userNames[supId] ?? 'مشرف غير معروف',
            neighborhoodId: neighId,
            neighborhoodName: neighborhoodNames[neighId] ?? 'منطقة غير معروفة',
            researcherIds: researcherIdsInGroup,
            researcherNames: researcherNamesInGroup,
            assignedFrom: _parseDate(fromStr) ?? DateTime.now(),
            assignedTo: _parseDate(toStr),
            isActive: isActive && !isExpiredByDate,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _items = loaded;
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

  Future<void> _openEditDialog(_EditableAssignmentItem item) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditAssignmentDialog(
        item: item,
        formatDate: _formatDate,
        friendlyError: _friendlyError,
      ),
    );

    if (updated == true) {
      await _loadAssignments();
      _showMessage('تم تحديث بيانات التكليف بنجاح.');
    }
  }

  Future<void> _confirmAndDelete(_EditableAssignmentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
        
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تأكيد حذف التكليف',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف تكليف المشرف (${item.supervisorName}) في (${item.neighborhoodName})؟',
            style: const TextStyle(color: Color(0xFF334155), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase
          .from('researcher_neighborhoods')
          .delete()
          .eq('neighborhood_id', item.neighborhoodId);

      await _supabase
          .from('supervisor_neighborhoods')
          .delete()
          .eq('id', item.id);

      for (final rId in item.researcherIds) {
        await _supabase
            .from('profiles')
            .update({'supervisor_id': null})
            .eq('user_id', rId)
            .eq('supervisor_id', item.supervisorId);
      }

      await _loadAssignments();
      _showMessage('تم حذف التكليف بنجاح.');
    } catch (e) {
      _showMessage(_friendlyError(e), isError: true);
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
            'تعديل وحذف الإسناد',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loadAssignments,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0288D1)),
            ),
          ],
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
                  onPressed: _loadAssignments,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد تكليفات للتعديل أو الحذف.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0288D1),
      onRefresh: _loadAssignments,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _EditableAssignmentCard(
            item: item,
            formatDate: _formatDate,
            onEdit: () => _openEditDialog(item),
            onDelete: () => _confirmAndDelete(item),
          );
        },
      ),
    );
  }
}

class _EditableAssignmentItem {
  final String id;
  final String supervisorId;
  final String supervisorName;
  final String neighborhoodId;
  final String neighborhoodName;
  final Set<String> researcherIds;
  final List<String> researcherNames;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool isActive;

  const _EditableAssignmentItem({
    required this.id,
    required this.supervisorId,
    required this.supervisorName,
    required this.neighborhoodId,
    required this.neighborhoodName,
    required this.researcherIds,
    required this.researcherNames,
    required this.assignedFrom,
    required this.assignedTo,
    required this.isActive,
  });
}

class _EditableAssignmentCard extends StatelessWidget {
  final _EditableAssignmentItem item;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableAssignmentCard({
    required this.item,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fromText = formatDate(item.assignedFrom);
    final toText = item.assignedTo != null ? formatDate(item.assignedTo!) : 'غير محدد';

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'تعديل التكليف',
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE0F2FE),
                      foregroundColor: const Color(0xFF0288D1),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 19),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'حذف التكليف',
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFD32F2F),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  ),
                ],
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
                  'من: $fromText',
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5),
                ),
                const SizedBox(width: 14),
                Text(
                  'إلى: $toText',
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 12.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isActive ? 'نشط' : 'متوقف',
                    style: TextStyle(
                      color: item.isActive ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              'لا يوجد باحثون مرتبطون حالياً.',
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

class _EditAssignmentDialog extends StatefulWidget {
  final _EditableAssignmentItem item;
  final String Function(DateTime) formatDate;
  final String Function(Object) friendlyError;

  const _EditAssignmentDialog({
    required this.item,
    required this.formatDate,
    required this.friendlyError,
  });

  @override
  State<_EditAssignmentDialog> createState() => _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends State<_EditAssignmentDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorText;

  List _supervisors = [];
  List _neighborhoods = [];
  List _researchers = [];

  late String? _supervisorId;
  late String? _neighborhoodId;
  late Set<String> _selectedResearchers;
  late DateTime _assignedFrom;
  late DateTime? _assignedTo;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _supervisorId = widget.item.supervisorId;
    _neighborhoodId = widget.item.neighborhoodId;
    _selectedResearchers = Set<String>.from(widget.item.researcherIds);
    _assignedFrom = widget.item.assignedFrom;
    _assignedTo = widget.item.assignedTo;
    _isActive = widget.item.isActive;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final supRes = await _supabase
          .from('profiles')
          .select('user_id, full_name')
          .eq('role', 'supervisor')
          .eq('is_active', true);

      final neighRes = await _supabase
          .from('neighborhoods')
          .select('id, name, region_name')
          .eq('is_active', true);

      final resList = await _supabase
          .from('profiles')
          .select('user_id, full_name')
          .eq('role', 'researcher')
          .eq('is_active', true);

      if (!mounted) return;
      setState(() {
        _supervisors = List.from(supRes);
        _neighborhoods = List.from(neighRes);
        _researchers = List.from(resList);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = widget.friendlyError(e);
        _isLoading = false;
      });
    }
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
        _errorText = null;
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
        _errorText = null;
        _assignedTo = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _errorText = null);

    if (_supervisorId == null || _neighborhoodId == null) {
      setState(() => _errorText = 'يرجى اختيار المشرف والمنطقة.');
      return;
    }

    if (_assignedTo != null && _assignedTo!.isBefore(_assignedFrom)) {
      setState(
        () => _errorText = 'تاريخ نهاية التكليف يجب أن يكون مساوياً أو بعد تاريخ البداية.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final startStr = widget.formatDate(_assignedFrom);
      final endStr = _assignedTo != null ? widget.formatDate(_assignedTo!) : null;

      await _supabase
          .from('supervisor_neighborhoods')
          .update({
            'supervisor_id': _supervisorId,
            'neighborhood_id': _neighborhoodId,
            'assigned_from': startStr,
            'assigned_to': endStr,
            'is_active': _isActive,
          })
          .eq('id', widget.item.id);

      // إزالة ارتباط الباحثين السابقين بالحارة القديمة ثم إعادة ربط المختارين
      await _supabase
          .from('researcher_neighborhoods')
          .delete()
          .eq('neighborhood_id', widget.item.neighborhoodId);

      for (final oldResId in widget.item.researcherIds) {
        await _supabase
            .from('profiles')
            .update({'supervisor_id': null})
            .eq('user_id', oldResId)
            .eq('supervisor_id', widget.item.supervisorId);
      }

      for (final resId in _selectedResearchers) {
        await _supabase.from('researcher_neighborhoods').upsert(
          {
            'researcher_id': resId,
            'neighborhood_id': _neighborhoodId,
            'assigned_by': currentUserId,
            'assigned_from': startStr,
            'assigned_to': endStr,
            'is_active': _isActive,
          },
          onConflict: 'researcher_id,neighborhood_id,assigned_from',
        );

        await _supabase
            .from('profiles')
            .update({'supervisor_id': _isActive ? _supervisorId : null})
            .eq('user_id', resId);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = widget.friendlyError(e);
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
          'تعديل التكليف',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: _isLoading
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
                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF9A9A)),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(color: Color(0xFFC62828), fontSize: 12.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        value: _supervisors.any((s) => s['user_id'].toString() == _supervisorId)
                            ? _supervisorId
                            : null,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'المشرف',
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
                        onChanged: (val) => setState(() => _supervisorId = val),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _neighborhoods.any((n) => n['id'].toString() == _neighborhoodId)
                            ? _neighborhoodId
                            : null,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'المنطقة / الحارة',
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
                        onChanged: (val) => setState(() => _neighborhoodId = val),
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
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF0288D1),
                        title: const Text(
                          'حالة التكليف (نشط)',
                          style: TextStyle(color: Color(0xFF0F172A), fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'الباحثون التابعون للتكليف:',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 170),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _researchers.length,
                          itemBuilder: (context, index) {
                            final res = _researchers[index];
                            final id = res['user_id'].toString();
                            final checked = _selectedResearchers.contains(id);
                            return CheckboxListTile(
                              value: checked,
                              activeColor: const Color(0xFF0288D1),
                              title: Text(
                                res['full_name']?.toString() ?? 'باحث',
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedResearchers.add(id);
                                  } else {
                                    _selectedResearchers.remove(id);
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
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('حفظ التعديل', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}