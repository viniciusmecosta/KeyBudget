import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool forceVisible;

  const PasswordFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.readOnly = false,
    this.forceVisible = false,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = widget.forceVisible;
  }

  @override
  void didUpdateWidget(covariant PasswordFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceVisible != oldWidget.forceVisible) {
      setState(() {
        _isPasswordVisible = widget.forceVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_isPasswordVisible,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: widget.validator,
    );
  }
}
