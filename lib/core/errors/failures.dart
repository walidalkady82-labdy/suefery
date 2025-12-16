import 'package:equatable/equatable.dart';

/// An enum that defines all possible high-level failure types.
enum FailureType {
  server,
  cache,
  network,
  authentication,
  database,
  storage,
  unexpected,
}

/// A single, unified class to represent a high-level failure in the application.
/// This is returned from the data layer to the presentation layer.
class Failure extends Equatable {
  /// The specific category of the failure.
  final FailureType type;

  /// A user-friendly message describing the failure.
  final String message;
  
  /// Optional: The original low-level exception/error for logging purposes.
  final dynamic originalError;

  const Failure({
    this.type = FailureType.unexpected,
    required this.message,
    this.originalError,
  });

  @override
  List<Object?> get props => [type, message, originalError];
}