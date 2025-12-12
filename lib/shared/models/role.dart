class Role {
  final String id;
  final String name;
  final String slug; // e.g., 'admin', 'teacher', 'student', 'parent'
  final String? description;

  const Role({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory Role.fromApiResponse(Map<String, dynamic> data) {
    return Role(
      id: data['role_id']?.toString() ?? data['id']?.toString() ?? '',
      name: data['role_name']?.toString() ?? data['name']?.toString() ?? '',
      slug: data['role_slug']?.toString() ?? 
            data['slug']?.toString() ?? 
            (data['role_name']?.toString() ?? data['name']?.toString() ?? '').toLowerCase(),
      description: data['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': id,
      'role_name': name,
      'role_slug': slug,
      'description': description,
    };
  }

  @override
  String toString() => 'Role(id: $id, name: $name, slug: $slug)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
