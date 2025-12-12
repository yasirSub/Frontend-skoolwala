class MenuItem {
  final String id;
  final String title;
  final String icon;
  final String? route;
  final String type; // 'item' or 'parent'
  final String? permission;
  final List<MenuItem>? children;

  const MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.route,
    required this.type,
    this.permission,
    this.children,
  });

  factory MenuItem.fromApiResponse(Map<String, dynamic> data) {
    return MenuItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      icon: data['icon']?.toString() ?? '',
      route: data['route']?.toString(),
      type: data['type']?.toString() ?? 'item',
      permission: data['permission']?.toString(),
      children: data['children'] != null
          ? (data['children'] as List<dynamic>)
              .map((child) => MenuItem.fromApiResponse(child as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'route': route,
      'type': type,
      'permission': permission,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }

  bool get isParent => type == 'parent' && children != null && children!.isNotEmpty;
  bool get isItem => type == 'item';
}

