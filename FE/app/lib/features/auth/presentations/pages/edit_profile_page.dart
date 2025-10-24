import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/reader_entity.dart';
import 'package:book_tech/core/theme/app_palette.dart';

class EditProfilePage extends StatefulWidget {
  final ReaderEntity profile;

  const EditProfilePage({Key? key, required this.profile}) : super(key: key);
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  late TextEditingController _cccdController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(
      text: widget.profile.fullName ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.profile.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile.address ?? '',
    );
    _cccdController = TextEditingController(text: widget.profile.cccd ?? '');
    _noteController = TextEditingController(text: widget.profile.note ?? '');
    _selectedDate = widget.profile.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(state.profile);
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa thông tin'),
          backgroundColor: AppPalette.gradient1,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppPalette.gradient1,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin độc giả',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'ID: ${widget.profile.readerId}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form Fields
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  icon: Icons.person,
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

                _buildTextField(
                  controller: _phoneNumberController,
                  label: 'Số điện thoại',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                        return 'Số điện thoại không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  icon: Icons.location_on,
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.length > 500) {
                      return 'Địa chỉ không được quá 500 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Date of Birth
                _buildDateField(),
                const SizedBox(height: 20),

                // CCCD Field
                _buildTextField(
                  controller: _cccdController,
                  label: 'CCCD/CMND',
                  icon: Icons.credit_card,
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

                // Note Field
                _buildTextField(
                  controller: _noteController,
                  label: 'Ghi chú',
                  icon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // totol Borrow (Read-only)
                _buildInfoField(
                  'Số sách đã mượn',
                  '${widget.profile.totolBorrow}',
                ),
                const SizedBox(height: 20),
              ],
            ),
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
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppPalette.gradient1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppPalette.gradient1),
        ),
      ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppPalette.gradient1),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Chọn ngày sinh',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate != null
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
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
      // Tạo ReaderEntity mới với dữ liệu đã cập nhật
      final updatedProfile = widget.profile.copyWith(
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty
            ? null
            : _phoneNumberController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        dateOfBirth: _selectedDate,
        cccd: _cccdController.text.trim().isEmpty
            ? null
            : _cccdController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Lấy access token từ AuthBloc
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated &&
          authState.account.accessToken != null) {
        // Sử dụng ProfileBloc để cập nhật
        context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            authState.account.accessToken!,
            updatedProfile.toJson(),
          ),
        );
      } else {
        throw Exception('Không có token xác thực');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
