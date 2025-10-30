class LoanResponse {
  final bool success;
  final ReaderSummary? reader;
  final PaginationInfo? pagination;
  final List<LoanItem> data;

  LoanResponse({
    required this.success,
    this.reader,
    this.pagination,
    required this.data,
  });

  factory LoanResponse.fromJson(Map<String, dynamic> json) {
    return LoanResponse(
      success: json['success'] == true,
      reader: json['reader'] != null
          ? ReaderSummary.fromJson(json['reader'])
          : null,
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'])
          : null,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => LoanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReaderSummary {
  final int readerId;
  final String fullName;
  ReaderSummary({required this.readerId, required this.fullName});
  factory ReaderSummary.fromJson(Map<String, dynamic> json) => ReaderSummary(
    readerId: json['readerId'],
    fullName: json['fullName'] ?? '',
  );
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
    page: json['page'] ?? 1,
    limit: json['limit'] ?? 0,
    total: json['total'] ?? 0,
    totalPages: json['totalPages'] ?? 0,
  );
}

class LoanItem {
  final int loanSlipId;
  final int readerId;
  final String loanDate; // 'YYYY-MM-DD'
  final String? dueDate;
  final String status;
  final List<LoanDetail> details;

  LoanItem({
    required this.loanSlipId,
    required this.readerId,
    required this.loanDate,
    required this.dueDate,
    required this.status,
    required this.details,
  });

  factory LoanItem.fromJson(Map<String, dynamic> json) {
    return LoanItem(
      loanSlipId: json['loanSlipId'],
      readerId: json['readerId'],
      loanDate: json['loanDate'] ?? '',
      dueDate: json['dueDate'],
      status: json['status'] ?? '',
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => LoanDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LoanDetail {
  final int loanDetailId;
  final String? returnDate; // có thể null
  final String status;
  final String? note;

  LoanDetail({
    required this.loanDetailId,
    required this.returnDate,
    required this.status,
    required this.note,
  });

  factory LoanDetail.fromJson(Map<String, dynamic> json) {
    return LoanDetail(
      loanDetailId: json['loanDetailId'],
      returnDate: json['returnDate'],
      status: json['status'] ?? '',
      note: json['note'],
    );
  }
}
