import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text; // Văn bản trên nút
  final VoidCallback onPressed; // Hành động khi nút được nhấn
  final Color? backgroundColor; // Màu nền của nút
  final Color? textColor; // Màu chữ
  final double borderRadius; // Độ bo góc
  final double? width; // Chiều rộng của nút
  final double? height; // Chiều cao của nút
  final TextStyle? textStyle; // Kiểu chữ tùy chỉnh
  final EdgeInsetsGeometry? padding; // Khoảng cách bên trong nút
  final Icon? icon; // Icon đi kèm (nếu có)
  final Color? borderColor; // Màu viền của nút
  final double borderWidth; // Độ dày viền
  final ButtonStyle? style; // Thêm style để tùy chỉnh các thuộc tính như padding, shape...

  const CustomElevatedButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 100.0,
    this.width,
    this.height,
    this.textStyle,
    this.padding,
    this.icon,
    this.borderColor,
    this.borderWidth = 2.0,
    this.style, // Add the style parameter
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            const Color(0xFFD35400),
            const Color(0xFFE67E22),
          ]
        : [
            const Color(0xFFE67E22),
            const Color(0xFFF39C12),
          ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8), // Khoảng cách giữa icon và text
            ],
            Text(
              text,
              style: textStyle ??
                  TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
