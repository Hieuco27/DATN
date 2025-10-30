import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/datasources/loan_remote_data_source.dart';
import 'package:book_tech/features/auth/data/repositories/loan_repository.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/data/models/loan_history_models.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({super.key});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  late final LocalStorageDataSource _local;
  late final LoanRepository _repo;
  @override
  void initState() {
    super.initState();
    final local = LocalStorageDataSourceImpl();
    _repo = LoanRepository(remote: LoanRemoteDataSourceImpl.create(local));
  }

  Future<LoanResponse> _fetch({required int page, required int limit}) {
    return _repo.getMyLoans(page: page, limit: limit);
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    // server trả 'YYYY-MM-DD' -> hiển thị 'DD/MM/YYYY'
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'BORROWING':
        return Colors.blue;
      case 'RETURNED':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lịch sử mượn trả',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<LoanResponse>(
        future: _fetch(page: 1, limit: 20),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
          }
          final items = snap.data?.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử mượn trả'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final loan = items[i];
              final detailsCount = loan.details.length;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Phiếu mượn #${loan.loanSlipId}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(loan.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loan.status,
                            style: TextStyle(
                              color: _statusColor(loan.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_note,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text('Ngày mượn: ${_formatDate(loan.loanDate)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_return,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text('Hẹn trả: ${_formatDate(loan.dueDate)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Số đầu sách: $detailsCount',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (loan.details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: loan.details.map((d) {
                          final note = d.note ?? '';
                          // Thường note có dạng: REQUEST_DOCUMENT_ID=xxxxx
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEAEAEA),
                              ),
                            ),
                            child: Text(
                              note.isEmpty
                                  ? 'Chi tiết: ${d.loanDetailId}'
                                  : note,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
