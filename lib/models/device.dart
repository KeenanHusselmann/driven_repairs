enum DeviceType {
  laptop,
  desktop,
  tablet,
  smartphone,
  server,
  printer,
  monitor,
  accessory,
  other;

  String get displayName {
    switch (this) {
      case DeviceType.laptop:
        return 'Laptop';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.smartphone:
        return 'Smartphone';
      case DeviceType.server:
        return 'Server';
      case DeviceType.printer:
        return 'Printer';
      case DeviceType.monitor:
        return 'Monitor';
      case DeviceType.accessory:
        return 'Accessory';
      case DeviceType.other:
        return 'Other';
    }
  }
}

class Device {
  final String id;
  final String customerId;
  final DeviceType type;
  final String brand;
  final String model;
  final String? serialNumber;
  final String? operatingSystem;
  final String? specifications;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    required this.customerId,
    required this.type,
    required this.brand,
    required this.model,
    this.serialNumber,
    this.operatingSystem,
    this.specifications,
    this.purchaseDate,
    this.warrantyExpiry,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$brand $model';

  bool get isUnderWarranty {
    if (warrantyExpiry == null) return false;
    return warrantyExpiry!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'type': type.name,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'operatingSystem': operatingSystem,
      'specifications': specifications,
      'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
      'warrantyExpiry': warrantyExpiry?.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      type: DeviceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DeviceType.other,
      ),
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      serialNumber: map['serialNumber'],
      operatingSystem: map['operatingSystem'],
      specifications: map['specifications'],
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchaseDate'])
          : null,
      warrantyExpiry: map['warrantyExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['warrantyExpiry'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Device copyWith({
    String? id,
    String? customerId,
    DeviceType? type,
    String? brand,
    String? model,
    String? serialNumber,
    String? operatingSystem,
    String? specifications,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      specifications: specifications ?? this.specifications,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, displayName: $displayName, type: ${type.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
