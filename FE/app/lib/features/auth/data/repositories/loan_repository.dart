// FE/app/lib/features/auth/data/repositories/loan_repository.dart
import 'package:book_tech/features/auth/data/datasources/loan_remote_data_source.dart';
import 'package:book_tech/features/auth/data/models/loan_history_models.dart';

class LoanRepository {
  final LoanRemoteDataSource remote;
  LoanRepository({required this.remote});

  Future<LoanResponse> getMyLoans({required int page, required int limit}) {
    return remote.getMyLoans(page: page, limit: limit);
  }
}
