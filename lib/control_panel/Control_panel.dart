import 'package:flutter/material.dart';
import 'package:untitled1/Admain_control/managment_user.dart';
import '../Login/LoginScreen.dart';

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
      const SystemManagementView(),      // 0: وظائف مدير النظام
      const SupervisorReviewView(),      // 1: وظائف المشرف
      const FieldSurveyView(),           // 2: وظائف الباحث
      const ReportsAndAuditView(),       // 3: التقارير والتدقيق
    ];

    final allMenu = [
      {"icon": Icons.admin_panel_settings_rounded, "text": "وظائف المدير", "index": 0},
      {"icon": Icons.supervisor_account_rounded, "text": "وظائف المشرف", "index": 1},
      {"icon": Icons.home_work_rounded, "text": "وظائف الباحث", "index": 2},
      {"icon": Icons.analytics_rounded, "text": "التقارير", "index": 3},
    ];

    // التوجيه الديناميكي للتبويبات حسب الدور الذي يختاره المستخدم عند تسجيل الدخول
    if (widget.role == "مدير النظام") {
      views = [allViews[0], allViews[3]]; 
      menuItems = [allMenu[0], allMenu[3]];
    } else if (widget.role == "المشرف") {
      views = [allViews[1], allViews[3]]; 
      menuItems = [allMenu[1], allMenu[3]];
    } else if (widget.role == "الباحث") {
      views = [allViews[2]]; 
      menuItems = [allMenu[2]];
    } else if (widget.role == "مشاهد / مدقق") {
      views = [allViews[3]]; 
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A192F),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: const [
              Icon(Icons.people_alt_rounded, color: Color(0xFF00E5FF), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نظام إدارة وتحصيل السكان (PDMS)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // زر تسجيل خروج 
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'تسجيل خروج',
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A192F), Color(0xFF0F172A), Color(0xFF0288D1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: (views.isNotEmpty && currentIndex < views.length)
              ? views[currentIndex]
              : const Center(
                  child: Text(
                    "لا توجد صلاحيات لعرض هذه القائمة",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
        ),
        // شريط تنقل سفلي 
        bottomNavigationBar: menuItems.length > 1
            ? BottomNavigationBar(
                currentIndex: currentIndex,
                backgroundColor: const Color(0xFF0A192F),
                selectedItemColor: const Color(0xFF00E5FF),
                unselectedItemColor: Colors.white60,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                items: menuItems.map((item) {
                  return BottomNavigationBarItem(
                    icon: Icon(item["icon"]),
                    label: item["text"],
                  );
                }).toList(),
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
              )
            : null,
      ),
    );
  }
}

// ========================================== //
//        أزرار العمليات والوظائف          //
// ========================================== //
class ActionGlassmorphicButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 105.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            colors: colors.map((color) => color.withOpacity(0.25)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32.0,
                  color: colors.first,
                ),
                const SizedBox(height: 8.0),
                Text(
                  titel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
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

// دالة لتوزيع الأزرار  
Widget buildActionGrid(List<Widget> buttons) {
  return GridView.count(
    crossAxisCount: 2, 
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.4, 
    children: buttons,
  );
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildActionGrid([
            ActionGlassmorphicButton(
              titel: 'إدارة المستخدمين',
              icon: Icons.manage_accounts_rounded,
              colors: const [Color(0xFF00E5FF), Color(0xFF0288D1)],
              onPressed: () {
                Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UsersManagementView(),
      ),
    );
              },
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
          ]),
          const SizedBox(height: 20),
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildActionGrid([
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
          ]),
          const SizedBox(height: 20),
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildActionGrid([
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
          ]),
          const SizedBox(height: 20),
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          buildActionGrid([
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
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}