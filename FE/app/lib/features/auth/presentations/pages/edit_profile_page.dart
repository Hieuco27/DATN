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
      // Set to empty string if value doesn't match any valid option
      _selectedGender = '';
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop(state.profile);
            }
          });
        } else if (state is ProfileError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              NotificationService.showError(
                context,
                message: state.message.replaceFirst('Exception: ', ''),
              );
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Chỉnh sửa thông tin',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Họ và tên',
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
                        maxLines: 3,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Save Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primaryColor.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Nhập $label',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 13, height: 1.4),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _primaryColor : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: Colors.white,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _primaryColor,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gender,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Chọn ngày sinh',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey[400],
                      height: 1.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
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
        'totalBorrow': widget.profile.totalBorrow,
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
      NotificationService.showError(
        context, 
        message: e.toString().replaceFirst('Exception: ', ''),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
