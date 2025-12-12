import 'package:flutter/material.dart';

/// A reusable ListTile widget with common styling and functionality
class ListItemExample extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? accentColor;

  const ListItemExample({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onTap,
    this.isSelected = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: leadingIcon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(leadingIcon, color: color, size: 24),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              )
            : null,
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: color.withOpacity(0.05),
      ),
    );
  }
}

/// Example usage in a list view
class ExampleListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items = [
    {
      'title': 'Item 1',
      'subtitle': 'This is the first item',
      'icon': Icons.home,
    },
    {
      'title': 'Item 2',
      'subtitle': 'This is the second item',
      'icon': Icons.settings,
    },
    {
      'title': 'Item 3',
      'subtitle': 'This is the third item',
      'icon': Icons.person,
    },
    {
      'title': 'Item 4',
      'subtitle': 'This is the fourth item',
      'icon': Icons.email,
    },
    {
      'title': 'Item 5',
      'subtitle': 'This is the fifth item',
      'icon': Icons.phone,
    },
  ];

  ExampleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListTile Example')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListItemExample(
            title: item['title'],
            subtitle: item['subtitle'],
            leadingIcon: item['icon'],
            onTap: () => print('Tapped item $index: ${item['title']}'),
            accentColor: Colors.blue,
          );
        },
      ),
    );
  }
}
