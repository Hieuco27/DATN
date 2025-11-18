import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  final String hintText;
  final bool obsecureText;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const AuthField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obsecureText = false,
    this.errorText,
    this.onChanged,
    this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  String? _inlineError;

  String? _validate(String? value) {
    // Ưu tiên validator truyền từ ngoài, fallback sang validator mặc định
    String? externalError;
    if (widget.validator != null) {
      externalError = widget.validator!(value);
    } else {
      if (value == null || value.isEmpty) {
        externalError = '${widget.hintText} is required';
      }
    }

    if (externalError != _inlineError) {
      setState(() {
        _inlineError = externalError;
      });
    }

    // Trả về null để Flutter KHÔNG vẽ dòng error bên dưới,
    // chúng ta sẽ hiển thị lỗi ngay trong ô nhập.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _inlineError != null;

    return TextFormField(
      controller: widget.controller,
      onChanged: (value) {
        // Gửi onChanged ra ngoài nếu có
        widget.onChanged?.call(value);
        // Tự validate khi người dùng thay đổi
        _validate(value);
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: Color.fromARGB(255, 66, 66, 66)),
      validator: _validate,
      obscureText: widget.obsecureText,
      decoration: InputDecoration(
        // Khi có lỗi: hiển thị nội dung lỗi ngay trong ô nhập (màu đỏ)
        hintText: hasError ? _inlineError : widget.hintText,
        hintStyle: TextStyle(
          color: hasError
              ? const Color.fromARGB(255, 220, 82, 82)
              : const Color.fromARGB(255, 160, 160, 160),
        ),
        // Ẩn error mặc định bên dưới
        errorText: null,
        errorStyle: const TextStyle(height: 0, color: Colors.transparent),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError
                ? const Color.fromARGB(255, 244, 143, 143)
                : const Color.fromARGB(255, 101, 101, 101),
            width: 1.0,
          ), // khi chưa focus
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError
                ? const Color.fromARGB(255, 229, 57, 53)
                : const Color.fromARGB(255, 249, 213, 144),
            width: 2.0,
          ), // khi focus
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
