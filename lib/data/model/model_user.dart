import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suefery/core/extensions/is_not_null_or_empty.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';

class ModelUser extends Equatable {
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
  final String? bio;

  final bool isVerified;
  final DateTime? creationTimestamp;
   final UserRole role;
  final String? photoUrl;
  final UserAliveStatus userAliveStatus;
  final String? lastSeen;
  final double? lat;
  final double? lng;
  final String? geohash;
  final String? fcmToken;

  const ModelUser({
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
    this.photoUrl,
    this.userAliveStatus = UserAliveStatus.inactive,
    this.lastSeen,
    this.lat,
    this.lng,
    this.geohash,
    this.fcmToken,
    this.bio,
    this.role = UserRole.customer,
  });

  /// A computed property for the user's full name.
  String get name => '$firstName $lastName'.trim();

  factory ModelUser.fromFirebaseUser(User firebaseUser) {
    final displayName = firebaseUser.displayName ?? "";
    final names = displayName.split(' ');
    
    return ModelUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? "",
      phone: firebaseUser.phoneNumber,
      firstName: names.isNotEmpty ? names.first : "",
      lastName: names.length > 1 ? names.sublist(1).join(' ') : "",
      isVerified: firebaseUser.emailVerified,
      creationTimestamp: firebaseUser.metadata.creationTime,
      role: UserRole.customer,
      userAliveStatus: UserAliveStatus.inactive,
      lastSeen: "",
      photoUrl: firebaseUser.photoURL,
      bio: "",
      address: "",
      city: "",
      country: "",
      postalCode: "",
      state: "",
      specificPersonaGoal: "",
      lat: 0.0,
      lng: 0.0,
      geohash: "",
      fcmToken: "",
    );
  }

  factory ModelUser.fromMap(Map<String, dynamic> map) {
    return ModelUser(
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
      role: UserRole.values.firstWhere((role) => role.name == map['role']),
      photoUrl: map['photoUrl'] as String?,
      userAliveStatus: UserAliveStatus.values.firstWhere((status) => status.name == map['userAliveStatus']),
      lastSeen: map['lastSeen'] as String?,
      lat: map['lat'] as double?,
      lng: map['lng'] as double?,
      geohash: map['geohash'] as String?,
      fcmToken: map['fcmToken'] as String?,
      bio: map['bio'] as String?,

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
      'role': role.name,
      'photoUrl': photoUrl,
      'userAliveStatus': userAliveStatus.name,
      'lastSeen': lastSeen,
      'lat': lat,
      'lng': lng,
      'geohash': geohash,
      'fcmToken': fcmToken,
      'bio': bio,
    };
  }

  ModelUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    bool? isVerified,
    DateTime? creationTimestamp,
    UserRole? role,
    String? photoUrl,
    UserAliveStatus? userAliveStatus,
    String? lastSeen,
    double? lat,
    double? lng,
    String? geohash,
    String? fcmToken,
    String? bio,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? state,
    String? specificPersonaGoal,

  }) {
    return ModelUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isVerified: isVerified ?? this.isVerified,
      creationTimestamp: creationTimestamp ?? this.creationTimestamp,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      userAliveStatus: userAliveStatus ?? this.userAliveStatus,
      lastSeen: lastSeen ?? this.lastSeen,  
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      geohash: geohash ?? this.geohash,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      specificPersonaGoal:  specificPersonaGoal ?? this.specificPersonaGoal,  

    );
  }

  bool get isSetupComplete {
    return address.isNotNullOrEmpty && city.isNotNullOrEmpty;
  }

  @override
  List<Object?> get props => [id, email, phone, firstName, lastName, isVerified,
  creationTimestamp, role, photoUrl, userAliveStatus, lastSeen, lat, lng, geohash, fcmToken, bio, address, city, country, postalCode, state, specificPersonaGoal,
  ];
}