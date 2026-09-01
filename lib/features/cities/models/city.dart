class City {
  const City({required this.id, required this.slug, required this.name});

  final String id;
  final String slug;
  final String name;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
      );
}
