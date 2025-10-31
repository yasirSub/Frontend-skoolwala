import 'package:flutter/material.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';
import 'package:skoolwala/shared/widgets/custom_bottom_nav_bar.dart';

/// Demo screen showing how to use CustomAppBar and CustomBottomNavBar
/// This is a reference implementation
class NavigationDemoScreen extends StatefulWidget {
  const NavigationDemoScreen({super.key});

  @override
  State<NavigationDemoScreen> createState() => _NavigationDemoScreenState();
}

class _NavigationDemoScreenState extends State<NavigationDemoScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using CustomAppBar - fully customizable
      appBar: CustomAppBar(
        title: 'Navigation Demo',
        showThemeToggle: true,
        primaryColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Search tapped')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications tapped')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      // Using CustomBottomNavBar - reusable across the app
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: BottomNavConfigs.dashboardItems,
        primaryColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeTabContent();
      case 1:
        return const AttendanceTabContent();
      case 2:
        return const ClassesTabContent();
      case 3:
        return const StudentsTabContent();
      case 4:
        return const ProfileTabContent();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }
}

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Home Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildExampleCard('Custom App Bar', Icons.view_quilt),
        _buildExampleCard('Custom Bottom Nav', Icons.navigation),
        _buildExampleCard('Reusable Components', Icons.widgets),
      ],
    );
  }

  Widget _buildExampleCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class AttendanceTabContent extends StatelessWidget {
  const AttendanceTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Attendance Tab', style: TextStyle(fontSize: 24)),
    );
  }
}

class ClassesTabContent extends StatelessWidget {
  const ClassesTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Classes Tab', style: TextStyle(fontSize: 24)),
    );
  }
}

class StudentsTabContent extends StatelessWidget {
  const StudentsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Students Tab', style: TextStyle(fontSize: 24)),
    );
  }
}

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab', style: TextStyle(fontSize: 24)),
    );
  }
}

/// Example of using CustomBottomNavBar with different configurations
class CustomNavigationExample extends StatefulWidget {
  const CustomNavigationExample({super.key});

  @override
  State<CustomNavigationExample> createState() =>
      _CustomNavigationExampleState();
}

class _CustomNavigationExampleState extends State<CustomNavigationExample> {
  int _currentIndex = 0;
  final List<Color> _colors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.orange,
    Colors.teal,
  ];
  Color _selectedColor = Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customizable Navigation'),
        actions: [
          DropdownButton<Color>(
            value: _selectedColor,
            items: _colors.map((color) {
              return DropdownMenuItem(
                value: color,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
            onChanged: (color) {
              if (color != null) {
                setState(() {
                  _selectedColor = color;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Text(_getCurrentTabName(), style: const TextStyle(fontSize: 24)),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: BottomNavConfigs.dashboardItems,
        primaryColor: _selectedColor,
      ),
    );
  }

  String _getCurrentTabName() {
    return BottomNavConfigs.dashboardItems[_currentIndex].label;
  }
}
