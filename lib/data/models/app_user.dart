import 'package:firebase_auth/firebase_auth.dart' show User;

class AppUser {
  final String id;
  final String name;
  final String email;
  final String specificPersonaGoal; // Directly links model to the Persona's motivation
  final bool isVerified;
  final String creationTimestamp;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.specificPersonaGoal,
    this.isVerified =  false, 
    creationTimestamp,
  }):creationTimestamp = DateTime.now().toIso8601String();
  
  factory AppUser.fromFirebaseUser(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? "",
      email: firebaseUser.email ?? "",
      specificPersonaGoal: "", // You would load this from Firestore/DB
    );
  }
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      specificPersonaGoal: map['specificPersonaGoal'],
      isVerified: map['isVerified'],
      creationTimestamp: map['creationTimestamp'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specificPersonaGoal': specificPersonaGoal,
      'isVerified': isVerified,
      'creationTimestamp': creationTimestamp,
    };
  }
  
  // Create a copy with an updated verification status
  AppUser copyWith({bool? isVerified}) {
    return AppUser(
      id: id, 
      name: name, 
      email: email, 
      specificPersonaGoal: specificPersonaGoal,
      isVerified: isVerified ?? this.isVerified, 
    );
  }
  // Helper method to get a strategically relevant welcome message
  String get welcomeMessage => 'Welcome Customer! Start your **Conversational Order (S1)**. Your goal: **$specificPersonaGoal**';
  }