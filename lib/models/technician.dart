enum TechnicianStatus {
  active,
  inactive,
  onLeave,
  busy;

  String get displayName {
    switch (this) {
      case TechnicianStatus.active:
        return 'Active';
      case TechnicianStatus.inactive:
        return 'Inactive';
      case TechnicianStatus.onLeave:
        return 'On Leave';
      case TechnicianStatus.busy:
        return 'Busy';
    }
  }
}

class Technician {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final TechnicianStatus status;
  final List<String> skills;
  final String? certifications;
  final double hourlyRate;
  final int maxActiveTickets;
  final String? notes;
  final DateTime hireDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Technician({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.skills,
    this.certifications,
    required this.hourlyRate,
    this.maxActiveTickets = 5,
    this.notes,
    required this.hireDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  bool get isAvailable {
    return status == TechnicianStatus.active;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'skills': skills.join(','),
      'certifications': certifications,
      'hourlyRate': hourlyRate,
      'maxActiveTickets': maxActiveTickets,
      'notes': notes,
      'hireDate': hireDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Technician.fromMap(Map<String, dynamic> map) {
    return Technician(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      status: TechnicianStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TechnicianStatus.active,
      ),
      skills: map['skills'] != null && map['skills'].isNotEmpty
          ? map['skills'].split(',')
          : [],
      certifications: map['certifications'],
      hourlyRate: map['hourlyRate']?.toDouble() ?? 0.0,
      maxActiveTickets: map['maxActiveTickets'] ?? 5,
      notes: map['notes'],
      hireDate: DateTime.fromMillisecondsSinceEpoch(map['hireDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Technician copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    TechnicianStatus? status,
    List<String>? skills,
    String? certifications,
    double? hourlyRate,
    int? maxActiveTickets,
    String? notes,
    DateTime? hireDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Technician(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      maxActiveTickets: maxActiveTickets ?? this.maxActiveTickets,
      notes: notes ?? this.notes,
      hireDate: hireDate ?? this.hireDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Technician(id: $id, name: $fullName, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Technician && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
