// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class AssignmentPage extends StatefulWidget {
//   const AssignmentPage({super.key});

//   @override
//   State<AssignmentPage> createState() => _AssignmentPageState();
// }

// class _AssignmentPageState extends State<AssignmentPage> {
//   final supabase = Supabase.instance.client;

//   List<Map<String, dynamic>> researchers = [];
//   List<Map<String, dynamic>> neighborhoods = [];
//   List<Map<String, dynamic>> assignments = [];

//   String? selectedResearcher;
//   String? selectedNeighborhood;

//   DateTime startDate = DateTime.now();
//   DateTime? endDate;

//   bool loading = true;
//   bool saving = false;

//   @override
//   void initState() {
//     super.initState();
//     print("//////////////////////////////////////////////////////////////");
//     print(llll());
//     print("//////////////////////////////////////////////////////////////");
//     loadData();
//   }

//   String formatDate(DateTime date) {
//     return '${date.year}-'
//         '${date.month.toString().padLeft(2, '0')}-'
//         '${date.day.toString().padLeft(2, '0')}';
//   }

//   String displayDate(String? value) {
//     if (value == null || value.isEmpty) return 'مفتوح';
//     return value;
//   }

//   llll() async {
//     await supabase.from("profiles").select();
//   }

//   Future<void> loadData() async {
//     if (mounted) setState(() => loading = true);

//     try {
//       final results = await Future.wait([
//         supabase
//             .from('profiles')
//             .select('user_id, full_name')
//             .eq('role', 'researcher')
//             .eq('is_active', true)
//             .order('full_name'),
//         supabase
//             .from('neighborhoods')
//             .select('id, name ')
//             .eq('is_active', true)
//             .order('name'),
//         supabase
//             .from('researcher_neighborhoods')
//             .select('''
//               id,
//               researcher_id,
//               neighborhood_id,
//               assigned_from,
//               assigned_to,

//               profiles!researcher_neighborhoods_researcher_id_fkey(
//                 full_name
//               ),
//               neighborhoods!researcher_neighborhoods_neighborhood_id_fkey(
//                 name
//               )
//             ''')
//             .order('created_at', ascending: false),
//       ]);

//       if (!mounted) return;

//       setState(() {
//         researchers = List<Map<String, dynamic>>.from(results[0]);
//         neighborhoods = List<Map<String, dynamic>>.from(results[1]);
//         assignments = List<Map<String, dynamic>>.from(results[2]);
//         loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() => loading = false);
//       showMessage('تعذر تحميل البيانات: $e', error: true);
//     }
//   }

//   void showMessage(String message, {bool error = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: error ? Colors.red : Colors.green,
//       ),
//     );
//   }

//   Future<DateTime?> pickDate(DateTime initial) async {
//     return showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//       locale: const Locale('ar'),
//       builder: (context, child) {
//         return Directionality(textDirection: TextDirection.rtl, child: child!);
//       },
//     );
//   }

//   Future<void> chooseStartDate() async {
//     final date = await pickDate(startDate);
//     if (date == null || !mounted) return;

//     setState(() => startDate = date);
//   }

//   Future<void> chooseEndDate() async {
//     final date = await pickDate(endDate ?? startDate);
//     if (date == null || !mounted) return;

//     setState(() => endDate = date);
//   }

//   Future<void> saveAssignment() async {
//     if (selectedResearcher == null || selectedNeighborhood == null) {
//       showMessage('اختر الباحث والحارة أولاً', error: true);
//       return;
//     }

//     if (endDate != null &&
//         endDate!.isBefore(
//           DateTime(startDate.year, startDate.month, startDate.day),
//         )) {
//       showMessage(
//         'تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو مساويًا له',
//         error: true,
//       );
//       return;
//     }

//     final userId = supabase.auth.currentUser?.id;

//     if (userId == null) {
//       showMessage('يجب تسجيل الدخول أولاً', error: true);
//       return;
//     }

//     setState(() => saving = true);

//     try {
//       await supabase.from('researcher_neighborhoods').insert({
//         'researcher_id': selectedResearcher,
//         'neighborhood_id': selectedNeighborhood,
//         'assigned_by': userId,
//         'assigned_from': formatDate(startDate),
//         'assigned_to': endDate == null ? null : formatDate(endDate!),
//         'is_active': true,
//       });

//       if (!mounted) return;

//       setState(() {
//         selectedResearcher = null;
//         selectedNeighborhood = null;
//         startDate = DateTime.now();
//         endDate = null;
//       });

//       showMessage('تم إسناد الحارة بنجاح');
//       await loadData();
//     } on PostgrestException catch (e) {
//       if (!mounted) return;
//       showMessage('فشل الحفظ: ${e.message}', error: true);
//     } catch (e) {
//       if (!mounted) return;
//       showMessage('حدث خطأ: $e', error: true);
//     } finally {
//       if (mounted) setState(() => saving = false);
//     }
//   }

//   Future<void> endAssignment(Map<String, dynamic> assignment) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('إنهاء التكليف'),
//         content: const Text('هل تريد إنهاء إسناد هذه الحارة؟'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('إلغاء'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('إنهاء'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true || !mounted) return;

//     try {
//       await supabase
//           .from('researcher_neighborhoods')
//           .update({
//             'is_active': false,
//             'assigned_to': formatDate(DateTime.now()),
//           })
//           .eq('id', assignment['id']);

//       if (!mounted) return;
//       showMessage('تم إنهاء التكليف');
//       await loadData();
//     } on PostgrestException catch (e) {
//       if (!mounted) return;
//       showMessage('تعذر إنهاء التكليف: ${e.message}', error: true);
//     } catch (e) {
//       if (!mounted) return;
//       showMessage('حدث خطأ: $e', error: true);
//     }
//   }

//   Widget dateField(String label, String value, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: InputDecorator(
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           suffixIcon: const Icon(Icons.calendar_month),
//         ),
//         child: Text(value),
//       ),
//     );
//   }

//   Widget buildAssignmentForm() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'إسناد حارة جديدة',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),

//             DropdownButtonFormField<String>(
//               value: selectedResearcher,
//               isExpanded: true,
//               decoration: const InputDecoration(
//                 labelText: 'الباحث',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.person),
//               ),
//               items: researchers.map((researcher) {
//                 return DropdownMenuItem<String>(
//                   value: researcher['user_id'] as String,
//                   child: Text(researcher['full_name'] as String),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() => selectedResearcher = value);
//               },
//             ),

//             const SizedBox(height: 16),

//             DropdownButtonFormField<String>(
//               value: selectedNeighborhood,
//               isExpanded: true,
//               decoration: const InputDecoration(
//                 labelText: 'الحارة',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.location_on),
//               ),
//               items: neighborhoods.map((neighborhood) {
//                 final region = neighborhood['region_name'] as String?;
//                 final name = neighborhood['name'] as String;

//                 return DropdownMenuItem<String>(
//                   value: neighborhood['id'] as String,
//                   child: Text(
//                     region == null || region.isEmpty ? name : '$name - $region',
//                   ),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() => selectedNeighborhood = value);
//               },
//             ),

//             const SizedBox(height: 16),

//             dateField(
//               'تاريخ بداية التكليف',
//               formatDate(startDate),
//               chooseStartDate,
//             ),

//             const SizedBox(height: 16),

//             Row(
//               children: [
//                 Expanded(
//                   child: dateField(
//                     'تاريخ النهاية',
//                     endDate == null ? 'بدون تاريخ نهاية' : formatDate(endDate!),
//                     chooseEndDate,
//                   ),
//                 ),
//                 IconButton(
//                   tooltip: 'إلغاء تاريخ النهاية',
//                   onPressed: () => setState(() => endDate = null),
//                   icon: const Icon(Icons.clear),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             FilledButton.icon(
//               onPressed: saving ? null : saveAssignment,
//               icon: saving
//                   ? const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.assignment_turned_in),
//               label: Text(saving ? 'جارٍ الحفظ...' : 'إسناد الحارة'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildAssignmentList() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               'قائمة التكليفات',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),

//             if (assignments.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.all(24),
//                 child: Text(
//                   'لا توجد تكليفات مسجلة حتى الآن',
//                   textAlign: TextAlign.center,
//                 ),
//               ),

//             ...assignments.map((item) {
//               final profile = item['profiles'] as Map<String, dynamic>?;
//               final neighborhood =
//                   item['neighborhoods'] as Map<String, dynamic>?;

//               final researcherName = profile?['full_name'] ?? 'باحث غير معروف';
//               final neighborhoodName =
//                   neighborhood?['name'] ?? 'حارة غير معروفة';

//               final active = item['is_active'] == true;

//               return Card(
//                 color: active
//                     ? Colors.green.withValues(alpha: 0.06)
//                     : Colors.grey.withValues(alpha: 0.08),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     child: Icon(active ? Icons.person : Icons.person_off),
//                   ),
//                   title: Text(
//                     researcherName.toString(),
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(
//                     'الحارة: $neighborhoodName\n'
//                     'من: ${displayDate(item['assigned_from']?.toString())}\n'
//                     'إلى: ${displayDate(item['assigned_to']?.toString())}',
//                   ),
//                   isThreeLine: true,
//                   trailing: active
//                       ? IconButton(
//                           tooltip: 'إنهاء التكليف',
//                           onPressed: () => endAssignment(item),
//                           icon: const Icon(
//                             Icons.stop_circle_outlined,
//                             color: Colors.red,
//                           ),
//                         )
//                       : const Chip(label: Text('منتهٍ')),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('إسناد الحارات للباحثين'),
//           actions: [
//             IconButton(
//               tooltip: 'تحديث البيانات',
//               onPressed: loadData,
//               icon: const Icon(Icons.refresh),
//             ),
//           ],
//         ),
//         body: loading
//             ? const Center(child: CircularProgressIndicator())
//             : RefreshIndicator(
//                 onRefresh: loadData,
//                 child: ListView(
//                   padding: const EdgeInsets.all(16),
//                   children: [
//                     Text('الباحثون النشطون: ${researchers.length}'),
//                     Text('الحارات النشطة: ${neighborhoods.length}'),
//                     const SizedBox(height: 12),
//                     buildAssignmentForm(),
//                     const SizedBox(height: 16),
//                     buildAssignmentList(),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:my_project/service/assignment_service.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final AssignmentService assignmentService = AssignmentService();

  List<Map<String, dynamic>> researchers = [];
  List<Map<String, dynamic>> neighborhoods = [];
  List<Map<String, dynamic>> assignments = [];

  String? selectedResearcher;
  String? selectedNeighborhood;

  DateTime startDate = DateTime.now();
  DateTime? endDate;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        assignmentService.getResearchers(),
        assignmentService.getNeighborhoods(),
        assignmentService.getAssignments(),
      ]);

      if (!mounted) return;

      setState(() {
        researchers = results[0];
        neighborhoods = results[1];
        assignments = results[2];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('تعذر تحميل البيانات: $e', error: true);
    }
  }

  Future<DateTime?> pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }

  Future<void> chooseStartDate() async {
    final date = await pickDate(startDate);
    if (date == null || !mounted) return;

    setState(() => startDate = date);
  }

  Future<void> chooseEndDate() async {
    final date = await pickDate(endDate ?? startDate);
    if (date == null || !mounted) return;

    setState(() => endDate = date);
  }

  Future<void> saveAssignment() async {
    if (selectedResearcher == null || selectedNeighborhood == null) {
      showMessage('اختر الباحث والحارة أولاً', error: true);
      return;
    }

    if (endDate != null &&
        endDate!.isBefore(
          DateTime(startDate.year, startDate.month, startDate.day),
        )) {
      showMessage(
        'تاريخ النهاية يجب أن يكون بعد تاريخ البداية أو مساويًا له',
        error: true,
      );
      return;
    }

    setState(() => saving = true);

    try {
      await assignmentService.createAssignment(
        researcherId: selectedResearcher!,
        neighborhoodId: selectedNeighborhood!,
        assignedFrom: startDate,
        assignedTo: endDate,
      );

      if (!mounted) return;

      setState(() {
        selectedResearcher = null;
        selectedNeighborhood = null;
        startDate = DateTime.now();
        endDate = null;
      });

      showMessage('تم إسناد الحارة بنجاح');

      await loadData();
    } catch (e) {
      showMessage('فشل إسناد الحارة: $e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> endAssignment(Map<String, dynamic> assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء التكليف'),
        content: const Text('هل تريد إنهاء إسناد هذه الحارة للباحث؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إنهاء التكليف'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await assignmentService.endAssignment(assignment['id'].toString());

      if (!mounted) return;

      showMessage('تم إنهاء التكليف بنجاح');
      await loadData();
    } catch (e) {
      showMessage('تعذر إنهاء التكليف: $e', error: true);
    }
  }

  Widget dateField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(value),
      ),
    );
  }

  Widget buildAssignmentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إسناد حارة جديدة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedResearcher,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'اختر الباحث',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: researchers.map((researcher) {
                return DropdownMenuItem<String>(
                  value: researcher['user_id'].toString(),
                  child: Text(researcher['full_name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedResearcher = value);
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedNeighborhood,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'اختر الحارة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: neighborhoods.map((neighborhood) {
                final name = neighborhood['name']?.toString() ?? '';
                final region = neighborhood['region_name']?.toString();

                return DropdownMenuItem<String>(
                  value: neighborhood['id'].toString(),
                  child: Text(
                    region == null || region.isEmpty ? name : '$name - $region',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedNeighborhood = value);
              },
            ),

            const SizedBox(height: 16),

            dateField(
              'تاريخ بداية التكليف',
              formatDate(startDate),
              chooseStartDate,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: dateField(
                    'تاريخ نهاية التكليف',
                    endDate == null ? 'مفتوح' : formatDate(endDate!),
                    chooseEndDate,
                  ),
                ),
                IconButton(
                  tooltip: 'إلغاء تاريخ النهاية',
                  onPressed: () => setState(() => endDate = null),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: saving ? null : saveAssignment,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in),
              label: Text(saving ? 'جارٍ الحفظ...' : 'إسناد الحارة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAssignmentList() {
    if (assignments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('لا توجد تكليفات مسجلة', textAlign: TextAlign.center),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'قائمة التكليفات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...assignments.map((item) {
              final profile = item['profiles'] as Map<String, dynamic>?;
              final neighborhood =
                  item['neighborhoods'] as Map<String, dynamic>?;

              final researcherName = profile?['full_name'] ?? 'باحث غير معروف';
              final neighborhoodName =
                  neighborhood?['name'] ?? 'حارة غير معروفة';

              final active = item['is_active'] == true;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(active ? Icons.person : Icons.person_off),
                  ),
                  title: Text(researcherName.toString()),
                  subtitle: Text(
                    'الحارة: $neighborhoodName\n'
                    'البداية: ${item['assigned_from'] ?? '-'}\n'
                    'النهاية: ${item['assigned_to'] ?? 'مفتوح'}',
                  ),
                  isThreeLine: true,
                  trailing: active
                      ? IconButton(
                          tooltip: 'إنهاء التكليف',
                          onPressed: () => endAssignment(item),
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red,
                          ),
                        )
                      : const Chip(label: Text('منتهٍ')),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إسناد الحارات للباحثين'),
          actions: [
            IconButton(
              onPressed: loadData,
              tooltip: 'تحديث البيانات',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.people),
                                Text(
                                  '${researchers.length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('الباحثون'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.location_on),
                                Text(
                                  '${neighborhoods.length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('الحارات'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.assignment),
                                Text(
                                  '${assignments.where((a) => a['is_active'] == true).length}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('تكليفات نشطة'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildAssignmentForm(),
                    const SizedBox(height: 16),
                    buildAssignmentList(),
                  ],
                ),
              ),
      ),
    );
  }
}
