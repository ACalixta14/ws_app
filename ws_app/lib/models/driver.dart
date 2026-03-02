class Driver {
  final String id;
  final String name;
  final int colorTag; // depois converter

  const Driver({
    required this.id,
    required this.name,
    required this.colorTag,
  });

//preparação para edição futura
  Driver copyWith({
    String? id,
    String? name,
    int? colorTag,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      colorTag: colorTag ?? this.colorTag,
    );
  }
}
