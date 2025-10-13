class Part {
  final String id;
  final String name;
  final String? partNumber;
  final String? manufacturer;
  final String? category;
  final String? description;
  final double cost;
  final int quantityInStock;
  final int minimumStock;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  Part({
    required this.id,
    required this.name,
    this.partNumber,
    this.manufacturer,
    this.category,
    this.description,
    required this.cost,
    required this.quantityInStock,
    this.minimumStock = 0,
    this.supplier,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantityInStock <= minimumStock;
  bool get isOutOfStock => quantityInStock <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'partNumber': partNumber,
      'manufacturer': manufacturer,
      'category': category,
      'description': description,
      'cost': cost,
      'quantityInStock': quantityInStock,
      'minimumStock': minimumStock,
      'supplier': supplier,
      'location': location,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      partNumber: map['partNumber'],
      manufacturer: map['manufacturer'],
      category: map['category'],
      description: map['description'],
      cost: map['cost']?.toDouble() ?? 0.0,
      quantityInStock: map['quantityInStock'] ?? 0,
      minimumStock: map['minimumStock'] ?? 0,
      supplier: map['supplier'],
      location: map['location'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Part copyWith({
    String? id,
    String? name,
    String? partNumber,
    String? manufacturer,
    String? category,
    String? description,
    double? cost,
    int? quantityInStock,
    int? minimumStock,
    String? supplier,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      minimumStock: minimumStock ?? this.minimumStock,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Part(id: $id, name: $name, stock: $quantityInStock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Part && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
