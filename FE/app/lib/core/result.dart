class Result<T> {
  final T? data;
  final Exception? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  factory Result.ok(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.fail(Exception error) {
    return Result._(error: error, isSuccess: false);
  }

  bool get isFailure => !isSuccess;

  T get value {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception('Cannot get value from failed result');
  }

  Exception get errorValue {
    if (isFailure && error != null) {
      return error!;
    }
    throw Exception('Cannot get error from successful result');
  }
}
