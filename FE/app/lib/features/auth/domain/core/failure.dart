abstract class Failure {
  final String message;
  const Failure(this.message);
  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}


