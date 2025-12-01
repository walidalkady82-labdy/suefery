enum UserRole { customer, partner , rider , admin, unknown }

  extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  static UserRole fromString(String status) {
    return UserRole.values.firstWhere(
      (e) => e.name == status,
      orElse: () => UserRole.unknown,
    );
  }
}