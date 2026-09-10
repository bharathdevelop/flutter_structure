import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/colors.dart';


class Commoninputfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIconPath;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final int? maxlength;
  final int? maxline;

   const Commoninputfield({super.key, 
    required this.controller,
    required this.hintText,
    this.prefixIconPath,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.errorText,
    this.maxlength,
    this.maxline,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: readOnly,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: primary,
      maxLength: maxlength,
      maxLines: maxline,
      decoration: InputDecoration(
        filled: true,
        fillColor: lightgrey.withValues(alpha: 0.1),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 16),
        prefixIcon: 
        prefixIconPath != null
            ?
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 20),
            prefixIconPath ?? const SizedBox(),
            const SizedBox(width: 15),
            // / Vertical Divider
            // VerticalDivider(
            //   color: black,
            //   width: 10,
            //   thickness: 1,
            // ),
            Container(height: 25, width: 1, color: black),
            const SizedBox(width: 10),
          ],
        )
        : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 55),
        suffixIcon: suffixIcon,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: lightgrey.withValues(alpha: 0.2), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: lightgrey.withValues(alpha: 0.2), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
