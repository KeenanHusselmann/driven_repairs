import 'user_role.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final String? passwordHash;
  final String? profileImageUrl;
  final String? phone;
  final String? department;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? createdBy;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.status = UserStatus.active,
    this.passwordHash,
    this.profileImageUrl,
    this.phone,
    this.department,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.createdBy,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  bool hasPermission(Permission permission) {
    return role.permissions.contains(permission);
  }

  bool canAccessFeature(String feature) {
    switch (feature) {
      case 'users':
        return hasPermission(Permission.viewUsers);
      case 'customers':
        return hasPermission(Permission.viewCustomers);
      case 'tickets':
        return hasPermission(Permission.viewTickets);
      case 'devices':
        return hasPermission(Permission.viewDevices);
      case 'parts':
        return hasPermission(Permission.viewParts);
      case 'reports':
        return hasPermission(Permission.viewReports);
      case 'settings':
        return hasPermission(Permission.viewSettings);
      default:
        return false;
    }
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    UserStatus? status,
    String? passwordHash,
    String? profileImageUrl,
    String? phone,
    String? department,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? createdBy,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.value,
      'status': status.value,
      'passwordHash': passwordHash,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'department': department,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.value == map['role'],
        orElse: () => UserRole.technician,
      ),
      status: UserStatus.values.firstWhere(
        (s) => s.value == map['status'],
        orElse: () => UserStatus.active,
      ),
      passwordHash: map['passwordHash'],
      profileImageUrl: map['profileImageUrl'],
      phone: map['phone'],
      department: map['department'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : null,
      createdBy: map['createdBy'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, fullName: $fullName, role: ${role.displayName}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
