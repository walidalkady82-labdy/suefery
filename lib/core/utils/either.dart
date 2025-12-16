/// A custom implementation of the Either type, representing a value that can be
/// one of two types: a `Left` (typically for failures) or a `Right` (for successes).
/// This avoids an external dependency on packages like dartz.
abstract class Either<L, R> {
  const Either();

  /// Applies either the [ifLeft] function or the [ifRight] function.
  ///
  /// This is the core method for handling the value inside Either. It allows
  /// you to provide two functions, one to execute if the value is a Left, and
  /// one to execute if it is a Right.
  ///
  /// Returns the result of the function that was executed.
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight);

  /// A convenience property to check if the value is a `Right`.
  bool get isRight => this is Right<L, R>;

  /// A convenience property to check if the value is a `Left`.
  bool get isLeft => this is Left<L, R>;
}

/// Represents the `Left` side of an [Either], typically used for failures.
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) => ifLeft(value);
}

/// Represents the `Right` side of an [Either], typically used for successes.
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) => ifRight(value);
}
