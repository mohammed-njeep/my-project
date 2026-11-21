import 'package:flutter/material.dart';

class RolesPermissionsView extends StatelessWidget {
  const RolesPermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    // تعريف القائمة هنا بداخل دالة build لمنع أي أخطاء في نوع البيانات أو الـ const
    final List rolesList = [
      {
        'role': 'مدير النظام (Admin)',
        'description': 'صلاحيات كاملة على كافة إعدادات النظام، الجداول، إدارة المستخدمين، وإسناد المناطق.',
        'color': const Color(0xFFD97706), // أصفر ذهبي رسمي
        'icon': Icons.admin_panel_settings_rounded,
        'permissions': [
          'إضافة، تعديل، وحذف المستخدمين وصلاحياتهم',
          'إدارة الحارات والمناطق الجغرافية (CRUD)',
          'تخصيص وإسناد الحارات للباحثين والمشرفين',
          'الاطلاع على سجلات التدقيق (Audit Logs)',
        ],
      },
      {
        'role': 'مشرف (Supervisor)',
        'description': 'إشراف ميداني على نطاق جغرافي محدد لمتابعة أداء الباحثين ومراجعة استمارات الأسر.',
        'color': const Color(0xFF059669), // أخضر رسمي
        'icon': Icons.supervisor_account_rounded,
        'permissions': [
          'متابعة حالة الإنجاز الميداني للباحثين التابعين له',
          'مراجعة وتدقيق بيانات الأسر المسجلة',
          'الاطلاع على الحارات والمناطق المسندة لنطاقه',
        ],
      },
      {
        'role': 'باحث ميداني (Researcher)',
        'description': 'المسؤول عن النزول الميداني وجمع بيانات الأسر وأفرادها وتسجيلها في النظام.',
        'color': const Color(0xFF0284C7), // أزرق رسمي
        'icon': Icons.person_pin_rounded,
        'permissions': [
          'إدخال بيانات الأسر الجديدة وأفرادها في الحارات المسندة إليه',
          'تحديث بيانات الإقامة والمستندات الثبوتية والمرفقات',
          'عرض الحارات والمناطق المصرح له بالعمل فيها فقط',
        ],
      },
      {
        'role': 'مشاهد / مدقق (Viewer)',
        'description': 'صلاحية استعراض البيانات والمؤشرات والإحصائيات دون القدرة على التعديل.',
        'color': const Color(0xFF7C3AED), // بنفسجي رسمي
        'icon': Icons.visibility_rounded,
        'permissions': [
          'استعراض تقارير وإحصائيات الحقول والسكان',
          'مراجعة كشوفات الأسر المسجلة للمدققين',
          'قراءة البيانات دون صلاحية الحذف أو التعديل المباشر',
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        title: const Text(
          'الصلاحيات والأدوار الوظيفية',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: ListView.builder(
        itemCount: rolesList.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final roleData = rolesList[index];
          final Color roleColor = roleData['color'];
          final List permissions = roleData['permissions'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(roleData['icon'], color: roleColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roleData['role'],
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roleData['description'],
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                  const Text(
                    'الصلاحيات المرتبطة:',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...permissions.map((perm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              perm,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}