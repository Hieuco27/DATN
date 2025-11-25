import 'package:flutter/material.dart';
import 'package:book_tech/core/theme/app_palette.dart';
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
  late final LoanRepository _repo;
  List<LoanItem> _allItems = [];
  List<LoanItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  DateTime? _selectedMonth;
  DateTime? _selectedDate;
  bool _isFilterByMonth = false;
  bool _isFilterByDate = false;

  @override
  void initState() {
    super.initState();
    final local = LocalStorageDataSourceImpl();
    _repo = LoanRepository(remote: LoanRemoteDataSourceImpl.create(local));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repo.getMyLoans(page: 1, limit: 100);
      setState(() {
        _allItems = response.data;
        _filteredItems = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<LoanItem> filtered = List.from(_allItems);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((loan) {
        final query = _searchQuery.toLowerCase();
        return loan.loanSlipId.toString().contains(query) ||
            loan.status.toLowerCase().contains(query) ||
            _formatDate(loan.loanDate).toLowerCase().contains(query);
      }).toList();
    }

    // Filter by month
    if (_isFilterByMonth && _selectedMonth != null) {
      filtered = filtered.where((loan) {
        final loanDate = _parseDate(loan.loanDate);
        if (loanDate == null) return false;
        return loanDate.year == _selectedMonth!.year &&
            loanDate.month == _selectedMonth!.month;
      }).toList();
    }

    // Filter by specific date
    if (_isFilterByDate && _selectedDate != null) {
      filtered = filtered.where((loan) {
        final loanDate = _parseDate(loan.loanDate);
        if (loanDate == null) return false;
        return loanDate.year == _selectedDate!.year &&
            loanDate.month == _selectedDate!.month &&
            loanDate.day == _selectedDate!.day;
      }).toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final parts = iso.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Chọn tháng',
      initialDatePickerMode: DatePickerMode.year,
      selectableDayPredicate: (date) => date.day == 1,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPalette.gradient1,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedDate = null;
        _isFilterByMonth = true;
        _isFilterByDate = false;
      });
      _applyFilters();
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Chọn ngày',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPalette.gradient1,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = null;
        _isFilterByDate = true;
        _isFilterByMonth = false;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedMonth = null;
      _selectedDate = null;
      _isFilterByMonth = false;
      _isFilterByDate = false;
      _filteredItems = _allItems;
    });
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String _formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return 'Tháng ${date.month}/${date.year}';
  }

  String _formatDateOnly(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'WAITING_FOR_PICKUP':
      case 'APPROVED':
        return Colors.purple;
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

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return Icons.pending_outlined;
      case 'WAITING_FOR_PICKUP':
      case 'APPROVED':
        return Icons.task_alt_outlined;
      case 'BORROWING':
        return Icons.book_outlined;
      case 'RETURNED':
        return Icons.check_circle_outline;
      case 'OVERDUE':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'WAITING_FOR_PICKUP':
      case 'APPROVED':
        return 'Chờ lấy sách';
      case 'BORROWING':
        return 'Đang mượn';
      case 'RETURNED':
        return 'Đã trả';
      case 'OVERDUE':
        return 'Quá hạn';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Lịch sử mượn trả',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isFilterByMonth || _isFilterByDate || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.black87),
              onPressed: _clearFilters,
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã phiếu, trạng thái...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          // Filter buttons
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_month,
                  label: _isFilterByMonth
                      ? _formatMonthYear(_selectedMonth)
                      : 'Lọc theo tháng',
                  isActive: _isFilterByMonth,
                  
                  onTap: _selectMonth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_today,
                  label: _isFilterByDate
                      ? _formatDateOnly(_selectedDate)
                      : 'Lọc theo ngày',
                  isActive: _isFilterByDate,
                  
                  onTap: _selectDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 160;
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppPalette.gradient1.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppPalette.gradient1 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isSmallScreen ? 16 : 18,
                  color: isActive ? AppPalette.gradient1 : Colors.grey[700],
                ),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppPalette.gradient1 : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppPalette.gradient1),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.gradient1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _allItems.isEmpty
                    ? Icons.history_outlined
                    : Icons.filter_alt_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _allItems.isEmpty
                  ? 'Chưa có lịch sử mượn trả'
                  : 'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_allItems.isNotEmpty)
              Text(
                'Thử thay đổi bộ lọc',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppPalette.gradient1,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _buildLoanCard(_filteredItems[i]),
      ),
    );
  }

  Widget _buildLoanCard(LoanItem loan) {
    final statusColor = _statusColor(loan.status);
    final statusIcon = _statusIcon(loan.status);
    final detailsCount = loan.details.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phiếu #${loan.loanSlipId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusLabel(loan.status),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.event_note_outlined,
                  'Ngày mượn',
                  _formatDate(loan.loanDate),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.assignment_return_outlined,
                  'Hẹn trả',
                  _formatDate(loan.dueDate),
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.library_books_outlined,
                  'Số đầu sách',
                  '$detailsCount',
                  AppPalette.gradient1,
                ),
                if (loan.details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Chi tiết sách:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: loan.details.map((d) {
                      final note = d.note ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 14,
                              color: AppPalette.gradient1,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                note.isEmpty
                                    ? 'Mã: ${d.loanDetailId}'
                                    : note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
