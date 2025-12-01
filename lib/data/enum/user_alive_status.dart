enum UserAliveStatus { 
  //User is in the store, app is open, ready for orders
  active,
  //User is already handling too many orders
  busy,
  //User is planned to join suefery
  planned,
  //User is closed or logged out
  inactive 
  }

  extension UserAliveStatusExtension on UserAliveStatus {
  String get name => toString().split('.').last;

  static UserAliveStatus fromString(String status) {
    return UserAliveStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => UserAliveStatus.inactive,
    );
  }
}