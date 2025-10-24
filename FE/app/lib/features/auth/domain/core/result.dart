class Result<T> {
  final T? value;
  final Object? error; // Prefer Failure, but keep Object for flexibility

  const Result._(this.value, this.error);

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  static Result<T> ok<T>(T value) => Result._(value, null);
  static Result<T> fail<T>(Object error) => Result._(null, error);
}


