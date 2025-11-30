import 'package:flutter/material.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/data/datasources/loan_remote_data_source.dart';
import 'package:book_tech/features/auth/data/repositories/loan_repository.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/data/models/loan_history_models.dart';
import 'package:book_tech/core/services/socket_service.dart';

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
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterByMonth = false;
  bool _isFilterByDate = false;
  bool _isFilterByDateRange = false;
  int? _readerId;
  bool _socketListenerInitialized = false;

  @override
  void initState() {
    super.initState();
    final local = LocalStorageDataSourceImpl();
    _repo = LoanRepository(remote: LoanRemoteDataSourceImpl.create(local));
    _loadData();
  }

  @override
  void dispose() {
    SocketService().off('loan_status_updated');
    super.dispose();
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
        _readerId = response.reader?.readerId;
        _isLoading = false;
      });

      if (_readerId != null && !_socketListenerInitialized) {
        _setupSocketListener();
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _setupSocketListener() {
    if (_readerId == null) return;

    try {
      SocketService().initSocket(userId: _readerId);
      SocketService().off('loan_status_updated');
      SocketService().on('loan_status_updated', (data) {
        if (!mounted) return;

        try {
          final loanSlipId = data?['loanSlipId'];
          final status = data?['status'];

          if (loanSlipId == null || status == null) {
            return;
          }

          setState(() {
            _allItems = _allItems.map((loan) {
              if (loan.loanSlipId == loanSlipId) {
                return LoanItem(
                  loanSlipId: loan.loanSlipId,
                  readerId: loan.readerId,
                  loanDate: loan.loanDate,
                  dueDate: loan.dueDate,
                  status: status.toString(),
                  details: loan.details,
                );
              }
              return loan;
            }).toList();

            _applyFilters();
          });
        } catch (_) {}
      });

      _socketListenerInitialized = true;
    } catch (_) {}
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

    // Filter by date range
    if (_isFilterByDateRange && _startDate != null && _endDate != null) {
      filtered = filtered.where((loan) {
        final loanDate = _parseDate(loan.loanDate);
        if (loanDate == null) return false;
        return loanDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            loanDate.isBefore(_endDate!.add(const Duration(days: 1)));
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
        _startDate = null;
        _endDate = null;
        _isFilterByDate = true;
        _isFilterByMonth = false;
        _isFilterByDateRange = false;
      });
      _applyFilters();
    }
  }

  Future<void> _selectDateRange() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDateRangeBottomSheet(),
    );
  }

  Widget _buildDateRangeBottomSheet() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppPalette.gradient1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.date_range,
                        color: AppPalette.gradient1,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width:12),
                    const Text(
                      'Chọn khoảng thời gian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Start Date Button
                    _buildDateSelectionCard(
                      icon: Icons.calendar_today,
                      label: 'Từ ngày',
                      date: tempStartDate,
                      color: Colors.blue,
                      onTap: () async {
                        final picked = await _showDatePickerDialog(
                          initialDate: tempStartDate,
                          lastDate: tempEndDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempStartDate = picked;
                            if (tempEndDate != null && picked.isAfter(tempEndDate!)) {
                              tempEndDate = picked;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Arrow indicator
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(height: 12),
                    // End Date Button
                    _buildDateSelectionCard(
                      icon: Icons.event,
                      label: 'Đến ngày',
                      date: tempEndDate,
                      color: Colors.orange,
                      onTap: () async {
                        final picked = await _showDatePickerDialog(
                          initialDate: tempEndDate,
                          firstDate: tempStartDate,
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempEndDate = picked;
                            if (tempStartDate != null && picked.isBefore(tempStartDate!)) {
                              tempStartDate = picked;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: tempStartDate != null && tempEndDate != null
                                ? () {
                                    setState(() {
                                      _startDate = tempStartDate;
                                      _endDate = tempEndDate;
                                      _selectedMonth = null;
                                      _selectedDate = null;
                                      _isFilterByDateRange = true;
                                      _isFilterByMonth = false;
                                      _isFilterByDate = false;
                                    });
                                    _applyFilters();
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.gradient1,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelectionCard({
    required IconData icon,
    required String label,
    required DateTime? date,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? color.withOpacity(0.3) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _formatDateOnly(date) : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: date != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showDatePickerDialog({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? now,
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
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedMonth = null;
      _selectedDate = null;
      _startDate = null;
      _endDate = null;
      _isFilterByMonth = false;
      _isFilterByDate = false;
      _isFilterByDateRange = false;
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

  String _formatDateRange() {
    if (_startDate == null || _endDate == null) return '';
    return '${_formatDateOnly(_startDate)} - ${_formatDateOnly(_endDate)}';
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

  void _showCancelDialog(LoanItem loan) {
    if (loan.status.toUpperCase() == 'PENDING') {
      _showPendingCancelDialog(loan);
    } else if (loan.status.toUpperCase() == 'WAITING_FOR_PICKUP') {
      _showWaitingForPickupCancelDialog(loan);
    }
  }

  void _showPendingCancelDialog(LoanItem loan) {
    final selectedDetails = <int>{}; // Set of selected loanDetailIds
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hủy đặt mượn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn tài liệu muốn hủy:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phiếu đang ở trạng thái chờ duyệt, bạn có thể hủy trực tiếp.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: loan.details.length,
                  itemBuilder: (context, index) {
                    final detail = loan.details[index];
                    final bookTitle = detail.bookInfo?.title ?? 'Sách không xác định';
                    final isSelected = selectedDetails.contains(detail.loanDetailId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppPalette.gradient1 : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDetails.add(detail.loanDetailId);
                            } else {
                              selectedDetails.remove(detail.loanDetailId);
                            }
                          });
                        },
                        title: Text(
                          bookTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // subtitle: Text(
                        //   _statusLabel(detail.status),
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.black87,
                        //   ),
                        // ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppPalette.gradient1,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedDetails.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Đã chọn ${selectedDetails.length} tài liệu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.gradient1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Không',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: selectedDetails.isEmpty
                ? null
                : () {
                    Navigator.pop(context);
                    _cancelLoans(loan.loanSlipId, selectedDetails.toList(), null);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(selectedDetails.isEmpty 
                ? 'Chọn tài liệu' 
                : 'Hủy ${selectedDetails.length} tài liệu'),
          ),
        ],
        ),
      ),
    );
  }

  void _showWaitingForPickupCancelDialog(LoanItem loan) {
    final reasonController = TextEditingController();
    final selectedDetails = <int>{}; // Set of selected loanDetailIds
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yêu cầu hủy phiếu #${loan.loanSlipId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn tài liệu muốn yêu cầu hủy:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phiếu đang chờ lấy sách. Thủ thư sẽ xem xét và xử lý yêu cầu.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: loan.details.length,
                  itemBuilder: (context, index) {
                    final detail = loan.details[index];
                    final bookTitle = detail.bookInfo?.title ?? 'Sách không xác định';
                    final isSelected = selectedDetails.contains(detail.loanDetailId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppPalette.gradient1 : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDetails.add(detail.loanDetailId);
                            } else {
                              selectedDetails.remove(detail.loanDetailId);
                            }
                          });
                        },
                        title: Text(
                          bookTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // subtitle: Text(
                        //   _statusLabel(detail.status),
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.black87,
                        //   ),
                        // ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppPalette.gradient1,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (selectedDetails.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Đã chọn ${selectedDetails.length} tài liệu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.gradient1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Lý do hủy',
                  labelStyle: const TextStyle(fontSize: 13),

                  hintText: 'Nhập lý do muốn hủy phiếu...',
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppPalette.gradient1, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                maxLines: 2,
                maxLength: 150,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: selectedDetails.isEmpty
                ? null
                : () {
                    Navigator.pop(context);
                    _cancelLoans(loan.loanSlipId, selectedDetails.toList(), reasonController.text);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.gradient1,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(selectedDetails.isEmpty 
                ? 'Chọn tài liệu' 
                : 'Gửi yêu cầu (${selectedDetails.length})'),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _cancelLoans(int loanSlipId, List<int> loanDetailIds, String? reason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppPalette.gradient1),
                ),
                SizedBox(height: 16),
                Text('Đang xử lý...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      int successCount = 0;
      int failCount = 0;
      String? lastMessage;
      
      // Process each selected book
      for (final loanDetailId in loanDetailIds) {
        try {
          final response = await _repo.cancelLoanRequest(
            loanSlipId: loanSlipId,
            reason: reason,
            loanDetailId: loanDetailId,
          );
          
          final success = response['success'] as bool? ?? false;
          if (success) {
            successCount++;
            lastMessage = response['message'] as String?;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show result message
      String message;
      Color bgColor;
      IconData icon;
      
      if (failCount == 0) {
        message = successCount > 1 
            ? 'Đã xử lý $successCount tài liệu thành công'
            : (lastMessage ?? 'Đã xử lý yêu cầu thành công');
        bgColor = Colors.green;
        icon = Icons.check_circle;
      } else if (successCount == 0) {
        message = 'Không thể xử lý yêu cầu';
        bgColor = Colors.red;
        icon = Icons.error;
      } else {
        message = 'Đã xử lý $successCount/${ loanDetailIds.length} tài liệu';
        bgColor = Colors.orange;
        icon = Icons.warning;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Reload data
      if (successCount > 0) {
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lỗi: $e',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
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
          if (_isFilterByMonth || _isFilterByDate || _isFilterByDateRange || _searchQuery.isNotEmpty)
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
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color.fromARGB(221, 79, 79, 79),
              ),
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
                horizontal: 14,
                vertical: 10,
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
                      : 'Theo tháng',
                  isActive: _isFilterByMonth,
                  
                  onTap: _selectMonth,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.calendar_today,
                  label: _isFilterByDate
                      ? _formatDateOnly(_selectedDate)
                      : 'Theo ngày',
                  isActive: _isFilterByDate,
                  
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  icon: Icons.date_range,
                  label: _isFilterByDateRange
                      ? 'Khoảng TG'
                      : 'Khoảng TG',
                  isActive: _isFilterByDateRange,
                  
                  onTap: _selectDateRange,
                ),
              ),
            ],
          ),
          if (_isFilterByDateRange && _startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPalette.gradient1.withOpacity(0.1),
                      AppPalette.gradient2.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppPalette.gradient1.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.date_range,
                        size: 18,
                        color: AppPalette.gradient1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khoảng thời gian đã chọn',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateRange(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _isFilterByDateRange = false;
                          _filteredItems = _allItems;
                        });
                        _applyFilters();
                      },
                      tooltip: 'Xóa lọc',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
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
                  padding: const EdgeInsets.all(6),
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
                  'Ngày mượn:',
                  _formatDate(loan.loanDate),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.assignment_return_outlined,
                  'Hẹn trả:',
                  _formatDate(loan.dueDate),
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.library_books_outlined,
                  'Số đầu sách:',
                  '$detailsCount',
                  AppPalette.gradient1,
                ),
                if (loan.details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  Text(
                    'Danh sách tài liệu:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loan.details.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final detail = loan.details[index];
                      final book = detail.bookInfo;
                      
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            // Cover Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: book?.coverPhoto != null
                                  ? Image.network(
                                      book!.coverPhoto!,
                                      width: 50,
                                      height: 75,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 50,
                                        height: 75,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.book, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 75,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Book Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book?.title ?? 'Sách không xác định',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  
                                  // const SizedBox(height: 4),
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(
                                  //     horizontal: 8, 
                                  //     vertical: 2
                                  //   ),
                                  //   decoration: BoxDecoration(
                                  //     color: _statusColor(detail.status).withOpacity(0.1),
                                  //     borderRadius: BorderRadius.circular(4),
                                  //   ),
                                  //   child: Text(
                                  //     _statusLabel(detail.status),
                                  //     style: TextStyle(
                                  //       fontSize: 11,
                                  //       fontWeight: FontWeight.w500,
                                  //       color: _statusColor(detail.status),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          // Cancel button for PENDING or WAITING_FOR_PICKUP status
          if (loan.status.toUpperCase() == 'PENDING' || 
              loan.status.toUpperCase() == 'WAITING_FOR_PICKUP')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(loan),
                  label: Text(
                    loan.status.toUpperCase() == 'PENDING' 
                        ? 'Hủy đặt mượn' 
                        : 'Yêu cầu hủy',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
