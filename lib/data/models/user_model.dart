import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String state;
  final String specificPersonaGoal;
  final bool isVerified;
  final DateTime? creationTimestamp;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.address = "",
    this.city = "",
    this.country = "",
    this.postalCode = "",
    this.state = "",
    this.specificPersonaGoal = "",
    this.isVerified = false,
    this.creationTimestamp,
  });

  /// A computed property for the user's full name.
  String get name => '$firstName $lastName'.trim();

  factory UserModel.fromFirebaseUser(User firebaseUser) {
    final displayName = firebaseUser.displayName ?? "";
    final names = displayName.split(' ');
    
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? "",
      phone: firebaseUser.phoneNumber,
      firstName: names.isNotEmpty ? names.first : "",
      lastName: names.length > 1 ? names.sublist(1).join(' ') : "",
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      country: map['country'] as String,
      postalCode: map['postalCode'] as String,
      state: map['state'] as String,
      specificPersonaGoal: map['specificPersonaGoal'] as String,
      isVerified: map['isVerified'] as bool,
      creationTimestamp: (map['creationTimestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'state': state,
      'specificPersonaGoal': specificPersonaGoal,
      'isVerified': isVerified,
      'creationTimestamp': creationTimestamp != null
          ? Timestamp.fromDate(creationTimestamp!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    // ... other fields
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      // ...
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [id, email, phone, firstName, lastName, isVerified];
}