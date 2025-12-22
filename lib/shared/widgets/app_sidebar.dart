import 'package:flutter/material.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/attendance/screens/quick_attendance_screen.dart';
import '../../features/teacher/screens/teacher_self_attendance_screen.dart';
import '../../features/attendance/screens/weekend_attendance_inspection_screen.dart';
import '../../features/teacher/screens/teacher_timetable_screen.dart';
import '../../features/teacher/screens/homework_list_screen.dart';
import '../../features/teacher/screens/create_homework_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/messages/screens/message_screen.dart';
import '../../features/students/screens/students_list_screen.dart'; // Import Students List
import '../../features/hr/screens/employee_list_screen.dart'; // Import Employee List
import '../../features/hr/screens/add_employee_screen.dart';
import '../../features/fees/screens/fees_invoice_list_screen.dart'; // Import Fees Invoice List
import '../../features/exam/screens/exam_list_screen.dart'; // Import Exam List
import '../../features/inventory/screens/product_list_screen.dart';
import '../../features/inventory/screens/category_list_screen.dart';
import '../../features/inventory/screens/store_list_screen.dart';
import '../../features/inventory/screens/supplier_list_screen.dart';
import '../../features/inventory/screens/unit_list_screen.dart';
import '../../features/inventory/screens/purchase_list_screen.dart';
import '../../features/inventory/screens/sales_list_screen.dart';
import '../../features/inventory/screens/issue_list_screen.dart';
import '../../features/custom_domain/screens/custom_domain_list_screen.dart';
import '../screens/feature_under_construction_screen.dart'; // Import Placeholder
import '../services/session_manager.dart';
import '../services/menu_service.dart';
import '../models/menu_item.dart';

/// App Sidebar Menu
/// Loads menu items dynamically from API based on user permissions
class AppSidebar extends StatefulWidget {
  final String? currentRoute;

  const AppSidebar({super.key, this.currentRoute});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final MenuService _menuService = MenuService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      print('\n🔷 ============ SIDEBAR MENU LOADING ============');
      print(
        '🔷 Current Teacher: ${SessionManager.instance.currentTeacher?.name}',
      );
      print('🔷 Current Role: ${SessionManager.instance.currentTeacher?.role}');

      final items = await _menuService.fetchMenuItems();

      print('\n🔷 📋 RAW MENU ITEMS FROM API (${items.length} items):');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print(
          '   [$i] ID: ${item.id}, Title: ${item.title}, Type: ${item.type}, Icon: ${item.icon}',
        );
        if (item.isParent && item.children != null) {
          for (int j = 0; j < item.children!.length; j++) {
            print('       └─ [${j}] ${item.children![j].title}');
          }
        }
      }

      setState(() {
        _menuItems = items;
        _isLoading = false;
        // Initialize expanded state for parent items
        for (var item in items) {
          if (item.isParent) {
            _expandedItems[item.id] = false;
          }
        }
      });

      print('\n🔷 ✅ Menu items loaded successfully');
      print('🔷 ============================================\n');
    } catch (e) {
      print('\n🔷 ❌ AppSidebar: Error loading menu items: $e');
      print('🔷 ============================================\n');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleExpansion(String key) {
    setState(() {
      _expandedItems[key] = !(_expandedItems[key] ?? false);
    });
  }

  bool _isActive(String route) {
    return widget.currentRoute == route;
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Material Icons
    final iconMap = {
      'dashboard': Icons.dashboard,
      'people': Icons.people,
      'event_available': Icons.event_available,
      'assignment': Icons.assignment,
      'schedule': Icons.schedule,
      'quiz': Icons.quiz,
      'person': Icons.person,
      'settings': Icons.settings,
      'list': Icons.list,
      'add': Icons.add,
      'assessment': Icons.assessment,
      'check_circle': Icons.check_circle,
      'class': Icons.class_,
      'shopping_cart': Icons.shopping_cart,
      'mail': Icons.mail,
      // Inventory Icons
      'inventory': Icons.inventory,
      'shopping_bag': Icons.shopping_bag,
      'category': Icons.category,
      'store': Icons.store,
      'local_shipping': Icons.local_shipping,
      'straighten': Icons.straighten,
      'receipt': Icons.receipt,
      'outbox': Icons.outbox,
      // Other Icons
      'monetization_on': Icons.monetization_on,
      'block': Icons.block,
      'person_add': Icons.person_add,
      'school': Icons.school,
      'assignment_turned_in': Icons.assignment_turned_in,
      'language': Icons.language,
      'today': Icons.today,
      // Support/Help icons
      'support': Icons.support_agent,
      'help': Icons.help_outline,
    };
    return iconMap[iconName] ?? Icons.menu;
  }

  void _handleMenuTap(MenuItem item) {
    Navigator.pop(context);

    // Handle navigation based on route
    if (item.route != null) {
      _navigateToRoute(item.route!);
    }
  }

  void _navigateToRoute(String route) {
    // Map routes to actual screens
    switch (route) {
      case '/dashboard':
        final username = SessionManager.instance.currentUsername ?? '';
        final password = SessionManager.instance.currentPassword ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(username: username, password: password),
          ),
        );
        break;
      case '/profile':
        final teacher = SessionManager.instance.currentTeacher;
        if (teacher != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(teacher: teacher)),
          );
        }
        break;

      // --- Attendance ---
      case '/attendance/student':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeatureUnderConstructionScreen(
              title: 'Student Attendance',
            ),
          ),
        );
        break;
      case '/attendance/mark':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuickAttendanceScreen()),
        );
        break;
      case '/attendance/report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WeekendAttendanceInspectionScreen(),
          ),
        );
        break;
      case '/attendance/teacher':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherSelfAttendanceScreen(),
          ),
        );
        break;

      // --- Homework ---
      case '/homework/list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeworkListScreen()),
        );
        break;
      case '/homework/add':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateHomeworkScreen()),
        );
        break;

      // --- Academic ---
      case '/timetable/teacher':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherTimetableScreen()),
        );
        break;
      case '/timetable/class':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Class Timetable'),
          ),
        );
        break;

      // --- Student ---
      case '/student/list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentsListScreen()),
        );
        break;
      case '/student/add':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeatureUnderConstructionScreen(
              title: 'Student Admission',
            ),
          ),
        );
        break;
      case '/student/promotion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeatureUnderConstructionScreen(
              title: 'Student Promotion',
            ),
          ),
        );
        break;
      case '/student/disable':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Disable Student'),
          ),
        );
        break;

      // --- Parents ---
      case '/parents':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Parents'),
          ),
        );
        break;

      // --- HR ---
      case '/employee/list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
        );
        break;
      case '/employee/add':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
        );
        break;
      case '/employee/department':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Department'),
          ),
        );
        break;
      case '/employee/designation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Designation'),
          ),
        );
        break;
      case '/employee/disable_authentication':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeatureUnderConstructionScreen(
              title: 'Disable Authentication',
            ),
          ),
        );
        break;
      case '/employee/payroll':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Payroll'),
          ),
        );
        break;
      case '/employee/leave':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Leave Management'),
          ),
        );
        break;

      // --- Exam ---
      case '/exam/list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamListScreen()),
        );
        break;

      // --- Fees ---
      case '/fees/invoice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeesInvoiceListScreen()),
        );
        break;

      case '/subscription':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Subscription'),
          ),
        );
        break;

      case '/messages':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessageScreen()),
        );
        break;

      // --- Settings ---
      case '/settings/school':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'School Settings'),
          ),
        );
        break;
      case '/settings/global':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Global Settings'),
          ),
        );
        break;

      // --- Support / Help ---
      case '/support':
      case '/help':
      case '/need-support':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FeatureUnderConstructionScreen(title: 'Need Support'),
          ),
        );
        break;

      // --- Inventory ---
      case '/inventory/product':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListScreen()),
        );
        break;
      case '/inventory/category':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryListScreen()),
        );
        break;
      case '/inventory/store':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreListScreen()),
        );
        break;
      case '/inventory/supplier':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupplierListScreen()),
        );
        break;
      case '/inventory/unit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UnitListScreen()),
        );
        break;
      case '/inventory/purchase':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseListScreen()),
        );
        break;
      case '/inventory/sales':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesListScreen()),
        );
        break;
      case '/inventory/issue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IssueListScreen()),
        );
        break;

      // --- Custom Domain ---
      case '/custom_domain/list':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FeatureUnderConstructionScreen(
              title: 'Custom Domain List',
            ),
          ),
        );
        break;
      case '/custom_domain/mylist':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomDomainListScreen()),
        );
        break;

      default:
        print('⚠️ Unknown route: $route');
        // Fallback for any unmapped route
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FeatureUnderConstructionScreen(title: 'Menu Item ($route)'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Container(
            color: const Color(
              0xFF2C3E50,
            ), // Dark background similar to website
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header with logo and support
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF34495E),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1A252F), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'SW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SKOOLWALA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Support link
                      InkWell(
                        onTap: () {
                          // Handle support link
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.headset,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Need Support | SkoolWala',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu Items - Loaded dynamically from API
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  )
                else
                  ..._buildMenuItems(),
              ],
            ),
          ),
          // WhatsApp Floating Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Open WhatsApp support
                // You can use url_launcher package to open WhatsApp
              },
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
              child: const Icon(Icons.chat, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String key,
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFFFFA07A),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required String key,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final isExpanded = _expandedItems[key] ?? false;
    final isActive = widget.currentRoute?.startsWith('/$key') ?? false;

    return Column(
      children: [
        Container(
          color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
          child: ListTile(
            leading: Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFFFFA07A),
              size: 20,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.remove : Icons.add,
              color: Colors.white70,
              size: 18,
            ),
            onTap: () => _toggleExpansion(key),
          ),
        ),
        if (isExpanded)
          Container(
            color: const Color(0xFF1A252F),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const SizedBox(width: 20),
      title: Row(
        children: [
          const Icon(Icons.chevron_right, size: 14, color: Colors.white54),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  List<Widget> _buildMenuItems() {
    if (_menuItems.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No menu items available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    // Get current user role from SessionManager
    final currentUserRole = SessionManager.instance.currentTeacher?.role;

    print('\n🔶 ============ SIDEBAR FILTERING ============');
    print('🔶 Current user role: $currentUserRole');
    print('🔶 Total menu items from API: ${_menuItems.length}');
    print('\n🔶 📊 FILTERING RESULTS:');

    int shownCount = 0;
    int hiddenCount = 0;

    for (var item in _menuItems) {
      // All items from API are already filtered by backend based on admin permissions
      print('   ✅ SHOW: "${item.title}" (ID: ${item.id})');
      shownCount++;

      if (item.isParent && item.children != null && item.children!.isNotEmpty) {
        // Parent menu item with children
        widgets.add(_buildExpandableMenuItemFromApi(item));
      } else {
        // Single menu item
        widgets.add(_buildMenuItemFromApi(item));
      }
    }

    print('\n🔶 📈 SUMMARY:');
    print('   Total shown: $shownCount');
    print('   Total hidden: $hiddenCount');
    print('🔶 ==========================================\n');

    // Add divider before profile if profile exists
    final profileIndex = _menuItems.indexWhere((item) => item.id == 'profile');
    if (profileIndex != -1 && profileIndex < _menuItems.length - 1) {
      final profileWidgetIndex =
          widgets.length - (_menuItems.length - profileIndex);
      if (profileWidgetIndex >= 0 && profileWidgetIndex < widgets.length) {
        widgets.insert(
          profileWidgetIndex,
          const Divider(color: Color(0xFF1A252F)),
        );
      }
    }

    return widgets;
  }

  Widget _buildMenuItemFromApi(MenuItem item) {
    final isActive = widget.currentRoute == item.route;

    return Container(
      color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          _getIconData(item.icon),
          color: isActive ? Colors.white : const Color(0xFFFFA07A),
          size: 20,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => _handleMenuTap(item),
      ),
    );
  }

  Widget _buildExpandableMenuItemFromApi(MenuItem item) {
    final isExpanded = _expandedItems[item.id] ?? false;
    final isActive = widget.currentRoute?.startsWith(item.route ?? '') ?? false;

    return Column(
      children: [
        Container(
          color: isActive ? const Color(0xFFFF6B35) : Colors.transparent,
          child: ListTile(
            leading: Icon(
              _getIconData(item.icon),
              color: isActive ? Colors.white : const Color(0xFFFFA07A),
              size: 20,
            ),
            title: Text(
              item.title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.remove : Icons.add,
              color: Colors.white70,
              size: 18,
            ),
            onTap: () => _toggleExpansion(item.id),
          ),
        ),
        if (isExpanded && item.children != null)
          Container(
            color: const Color(0xFF1A252F),
            child: Column(
              children: item.children!
                  .map((child) => _buildSubMenuItemFromApi(child))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItemFromApi(MenuItem item) {
    return ListTile(
      leading: const SizedBox(width: 20),
      title: Row(
        children: [
          const Icon(Icons.chevron_right, size: 14, color: Colors.white54),
          const SizedBox(width: 8),
          Icon(_getIconData(item.icon), size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(
            item.title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
      onTap: () => _handleMenuTap(item),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
