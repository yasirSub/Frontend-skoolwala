class School {
  final String id;
  final String name;
  final String url;

  const School({required this.id, required this.name, required this.url});

  factory School.fromApiResponse(Map<String, dynamic> data) {
    return School(
      id: data['school_id']?.toString() ?? '',
      name: data['school_name']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'school_id': id, 'school_name': name, 'url': url};
  }

  @override
  String toString() {
    return 'School(id: $id, name: $name, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is School && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
