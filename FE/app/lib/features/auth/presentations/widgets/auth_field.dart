import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  final String hintText;
  final bool obsecureText;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onToggleVisibility;
  final bool showToggleIcon;

  const AuthField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obsecureText = false,
    this.errorText,
    this.onChanged,
    this.validator,
    this.onToggleVisibility,
    this.showToggleIcon = false,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: Color.fromARGB(255, 66, 66, 66)),
      validator: widget.validator,
      obscureText: widget.obsecureText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 160, 160, 160),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        suffixIcon: widget.showToggleIcon
            ? IconButton(
                icon: Icon(
                  widget.obsecureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color.fromARGB(255, 120, 120, 120),
                  size: 20,
                ),
                onPressed: widget.onToggleVisibility,
              )
            : null,
        // Hiển thị error bên dưới field
        errorStyle: const TextStyle(
          color: Color.fromARGB(255, 229, 57, 53),
          fontSize: 12,
          height: 0.8,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 101, 101, 101),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 249, 213, 144),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 244, 143, 143),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 229, 57, 53),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
