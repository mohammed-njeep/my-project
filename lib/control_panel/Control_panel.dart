import 'package:flutter/material.dart';
import 'package:my_project/Login/LoginScreen.dart';

// ========================================== //
//  الشاشة الرئيسية للوحة التحكم (Control) //
// ========================================== //
class Control extends StatefulWidget {
  final String role;
  const Control({super.key, required this.role});

  @override
  State<Control> createState() => _ControlState();
}

class _ControlState extends State<Control> {
  int currentIndex = 0;
  late List<Widget> views;
  late List menuItems;

  @override
  void initState() {
    super.initState();

    // جميع الأقسام والوظائف في النظام
    final allViews = [
      const SystemManagementView(), // 0: وظائف مدير النظام
      const SupervisorReviewView(), // 1: وظائف المشرف
      const FieldSurveyView(), // 2: وظائف الباحث
      const ReportsAndAuditView(), // 3: التقارير والتدقيق
    ];

    final allMenu = [
      {
        "icon": Icons.admin_panel_settings_rounded,
        "text": "وظائف المدير",
        "index": 0,
      },
      {
        "icon": Icons.supervisor_account_rounded,
        "text": "وظائف المشرف",
        "index": 1,
      },
      {"icon": Icons.home_work_rounded, "text": "وظائف الباحث", "index": 2},
      {
        "icon": Icons.analytics_rounded,
        "text": "التقارير والتدقيق",
        "index": 3,
      },
    ];

    // التوجيه الديناميكي للتبويبات حسب الدور الذي يختاره المستخدم عند تسجيل الدخول
    if (widget.role == "مدير النظام") {
      views = [
        allViews[0],
        allViews[3],
      ]; // المدير يرى تبويب وظائف المدير والتقارير
      menuItems = [allMenu[0], allMenu[3]];
    } else if (widget.role == "المشرف") {
      views = [
        allViews[1],
        allViews[3],
      ]; // المشرف يرى تبويب وظائف المشرف والتقارير
      menuItems = [allMenu[1], allMenu[3]];
    } else if (widget.role == "الباحث") {
      views = [allViews[2]]; // الباحث يفتح تبويب وظائف الباحث مباشرة
      menuItems = [allMenu[2]];
    } else if (widget.role == "مشاهد / مدقق") {
      views = [allViews[3]]; // المشاهد يرى التقارير فقط
      menuItems = [allMenu[3]];
    } else {
      views = [];
      menuItems = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(
            0.2,
          ), // شريط شفاف احترافي مطابق لتصميمك
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // شعار واسم النظام
              Row(
                children: const [
                  Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFF00E5FF),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'نظام إدارة وتحصيل السكان (PDMS)',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // القائمة الأفقية للأقسام المخصصة للدور
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var item in menuItems)
                        buildAppBarItem(
                          icon: item["icon"],
                          text: item["text"],
                          isSelected: currentIndex == item["index"],
                          onPressed: () {
                            setState(() {
                              currentIndex = item["index"];
                              if (currentIndex >= views.length) {
                                currentIndex = 0;
                              }
                            });
                          },
                        ),
                      // زر تسجيل الخروج
                      buildAppBarItem(
                        icon: Icons.logout_rounded,
                        text: 'تسجيل خروج',
                        isSelected: false,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            // التدرج اللوني الأزرق الكحلي الاحترافي المطابق لهويتك الأصلية تماماً
            gradient: LinearGradient(
              colors: [Color(0xFF0A192F), Color(0xFF0F172A), Color(0xFF0288D1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.only(
            top: 100.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: (views.isNotEmpty && currentIndex < views.length)
              ? views[currentIndex]
              : const Center(
                  child: Text(
                    "لا توجد صلاحيات لعرض هذه القائمة",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
        ),
      ),
    );
  }
}

// عناصر التنقل في AppBar
Widget buildAppBarItem({
  required IconData icon,
  required String text,
  required bool isSelected,
  required VoidCallback onPressed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0),
    child: TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
        size: 20,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    ),
  );
}

// ========================================== //
// أزرار العمليات والوظائف (Glassmorphic Button) //
// ========================================== //
class ActionGlassmorphicButton extends StatefulWidget {
  final String titel;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  const ActionGlassmorphicButton({
    super.key,
    required this.titel,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  @override
  State<ActionGlassmorphicButton> createState() =>
      _ActionGlassmorphicButtonState();
}

class _ActionGlassmorphicButtonState extends State<ActionGlassmorphicButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 160.0,
          height: 110.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
              colors: widget.colors
                  .map((color) => color.withOpacity(0.25))
                  .toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 36.0, color: widget.colors.first),
                const SizedBox(height: 10.0),
                Text(
                  widget.titel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================== //
//  واجهة وظائف مدير النظام (System Management) //
// ========================================== //
class SystemManagementView extends StatelessWidget {
  const SystemManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة تحكم مدير النظام',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ActionGlassmorphicButton(
                titel: 'إدارة المستخدمين',
                icon: Icons.manage_accounts_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'الصلاحيات والأدوار',
                icon: Icons.admin_panel_settings_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'إدارة الحارات',
                icon: Icons.map_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'إسناد الباحثين',
                icon: Icons.assignment_ind_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'سياسات RLS',
                icon: Icons.security_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'سجل التدقيق',
                icon: Icons.history_edu_rounded,
                colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================== //
// واجهة وظائف المشرف (Supervisor Review) //
// ========================================== //
class SupervisorReviewView extends StatelessWidget {
  const SupervisorReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة تحكم المشرف والمتابعة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ActionGlassmorphicButton(
                titel: 'إنجاز الباحثين',
                icon: Icons.insights_rounded,
                colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'مراجعة السجلات',
                icon: Icons.rate_review_rounded,
                colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'معالجة التعارضات',
                icon: Icons.compare_arrows_rounded,
                colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'إرجاع للتصحيح',
                icon: Icons.assignment_return_rounded,
                colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================== //
//  واجهة وظائف الباحث (Field Survey) //
// ========================================== //
class FieldSurveyView extends StatelessWidget {
  const FieldSurveyView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تطبيق المسح الميداني (للباحث)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ActionGlassmorphicButton(
                titel: 'إضافة أسرة جديدة',
                icon: Icons.person_add_alt_1_rounded,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'السجلات المحلية',
                icon: Icons.phone_android_rounded,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'طابور المزامنة',
                icon: Icons.sync_rounded,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'البحث عن الأسر',
                icon: Icons.search_rounded,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================== //
//  واجهة التقارير والتدقيق (Reports & Audit) //
// ========================================== //
class ReportsAndAuditView extends StatelessWidget {
  const ReportsAndAuditView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التقارير والإحصاءات العامة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ActionGlassmorphicButton(
                titel: 'إجمالي السكان',
                icon: Icons.pie_chart_rounded,
                colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'تصدير PDF / Excel',
                icon: Icons.file_download_rounded,
                colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                onPressed: () {},
              ),
              ActionGlassmorphicButton(
                titel: 'سجل التدقيق',
                icon: Icons.history_edu_rounded,
                colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
