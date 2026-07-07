import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';

class VaporwaveTextField extends StatefulWidget {
  const VaporwaveTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  State<VaporwaveTextField> createState() => _VaporwaveTextFieldState();
}

class _VaporwaveTextFieldState extends State<VaporwaveTextField> {
  bool _obscure = false;
  bool _focused = false;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focus = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focus.hasFocus);
      });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: _focused ? AppColors.neonCyan : AppColors.textSecondary,
            shadows: _focused
                ? [Shadow(color: AppColors.neonCyan.withValues(alpha: 0.6), blurRadius: 8)]
                : [],
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 18,
                color: _focused ? AppColors.neonCyan : AppColors.textMuted)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
                : null,
          ),
        ),
      ],
    );
  }
}