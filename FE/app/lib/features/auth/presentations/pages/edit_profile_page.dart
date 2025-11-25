import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/reader_entity.dart';
import 'package:book_tech/core/ui/notification_service.dart';

class EditProfilePage extends StatefulWidget {
  final ReaderEntity profile;

  const EditProfilePage({Key? key, required this.profile}) : super(key: key);
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _addressController;
  late TextEditingController _cccdController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;
  String _selectedGender = '';
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFFFF6B35);

  final List<String> _genderOptions = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(
      text: widget.profile.fullName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile.address ?? '',
    );
    _cccdController = TextEditingController(text: widget.profile.cccd ?? '');
    _noteController = TextEditingController(text: widget.profile.note ?? '');
    _selectedDate = widget.profile.dateOfBirth;
    
    // Normalize gender value to match dropdown options
    String rawGender = (widget.profile.gender ?? '').trim();
    if (rawGender.toLowerCase() == 'nam') {
      _selectedGender = 'Nam';
    } else if (rawGender.toLowerCase() == 'nữ' || rawGender.toLowerCase() == 'nu') {
      _selectedGender = 'Nữ';
    } else if (rawGender.toLowerCase() == 'khác' || rawGender.toLowerCase() == 'khac') {
      _selectedGender = 'Khác';
    } else {
      _selectedGender = rawGender;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          // Chỉ gọi pop, KHÔNG gọi thêm setState/context ở đây
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop(state.profile);
            }
          });
        } else if (state is ProfileError) {
          // Hiển thị lỗi sau 1 frame, tránh setState/context trên widget đã unmount
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              NotificationService.showError(
                context,
                message: 'Lỗi: ${state.message}',
              );
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Chỉnh sửa thông tin',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Lưu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 360;
              final margin = isSmallScreen ? 12.0 : 16.0;
              final padding = isSmallScreen ? 16.0 : 20.0;
              
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      margin: EdgeInsets.all(margin),
                      padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        spreadRadius: 1,
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.profile.fullName ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.profile.email ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.profile.readerId}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Fields
                Container(
                  margin: EdgeInsets.symmetric(horizontal: margin),
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Thông tin cá nhân'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Họ và tên',
                          icon: Icons.person_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            if (value.trim().length < 2) {
                              return 'Họ và tên phải có ít nhất 2 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildGenderField(),
                        const SizedBox(height: 20),

                        _buildDateField(),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _addressController,
                          label: 'Địa chỉ',
                          icon: Icons.location_on_rounded,
                          maxLines: 3,
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Địa chỉ không được quá 500 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _cccdController,
                          label: 'CCCD/CMND',
                          icon: Icons.credit_card_rounded,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[0-9]{9,12}$').hasMatch(value)) {
                                return 'CCCD/CMND không hợp lệ';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _noteController,
                          label: 'Ghi chú',
                          icon: Icons.note_rounded,
                          maxLines: 3,
                        ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87, fontSize: 14),
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender.isEmpty ? null : _selectedGender,
          items: _genderOptions
              .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value ?? '';
            });
          },
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(221, 255, 255, 255),
          ),
          hint: const Text(
            'Chọn giới tính',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.wc_rounded, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Chọn ngày sinh',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(colors: [_primaryColor]),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert gender back to lowercase for backend
      String genderForBackend = '';
      if (_selectedGender == 'Nam') {
        genderForBackend = 'nam';
      } else if (_selectedGender == 'Nữ') {
        genderForBackend = 'nữ';
      } else if (_selectedGender == 'Khác') {
        genderForBackend = 'khác';
      } else {
        genderForBackend = _selectedGender.toLowerCase();
      }
      
      // Tạo data theo format API yêu cầu với đầy đủ thông tin từ widget.profile
      final profileData = {
        'readerId': widget.profile.readerId,
        'accountId': widget.profile.accountId,
        'fullName': _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        'gender': genderForBackend.isEmpty ? '' : genderForBackend,
        'dateOfBirth': _selectedDate?.toIso8601String().split('T').first ?? '',
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'cccd': _cccdController.text.trim().isEmpty
            ? ''
            : _cccdController.text.trim(),
        'note': _noteController.text.trim().isEmpty
            ? ''
            : _noteController.text.trim(),
        'phoneNumber': widget.profile.phoneNumber,
        'totolBorrow': widget.profile.totolBorrow,
        'created_at': widget.profile.createdAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Lấy access token từ AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated &&
          authState.account.accessToken != null) {
        context.read<ProfileBloc>().add(
          ProfileUpdateRequested(authState.account.accessToken!, profileData),
        );
      } else {
        throw Exception('Không có token xác thực');
      }
    } catch (e) {
      NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }
}
