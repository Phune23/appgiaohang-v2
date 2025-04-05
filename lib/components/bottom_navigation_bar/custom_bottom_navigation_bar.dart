import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final Widget child; // Phần nội dung của BottomNavigationBar sẽ được truyền vào
  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final BorderRadius? borderRadius;
  final Color? lightBorderColor;
  final Color? darkBorderColor;
  final double topBorderThickness;
  final double leftBorderThickness;
  final double rightBorderThickness;
  final double bottomBorderThickness;
  final double topPadding; // Thêm padding cho phần trên
  final double bottomPadding; // Thêm padding cho phần dưới

  const CustomBottomNavBar({
    required this.child,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.borderRadius,
    this.lightBorderColor,
    this.darkBorderColor,
    this.topBorderThickness = 1.0,
    this.leftBorderThickness = 4.0,
    this.rightBorderThickness = 4.0,
    this.bottomBorderThickness = 4.0,
    this.topPadding = 0,
    this.bottomPadding = 0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Màu nền
    final backgroundColor = brightness == Brightness.dark
        ? darkBackgroundColor ?? const Color.fromARGB(255, 34, 34, 34)
        : lightBackgroundColor ?? const Color.fromARGB(255, 255, 255, 255);

    // Màu viền
    final borderColor = brightness == Brightness.dark
        ? darkBorderColor ?? const Color.fromARGB(255, 211, 166, 113).withOpacity(0.7)
        : lightBorderColor ?? Colors.black.withOpacity(0.7);

    // Màu icon thay đổi theo nền sáng/tối
    final selectedItemColor = brightness == Brightness.dark
        ? const Color.fromARGB(255, 255, 140, 0) // Vàng cho dark mode
        : const Color.fromARGB(255, 181, 106, 22); // Cam cho light mode;

    final unselectedItemColor = brightness == Brightness.dark
        ? Colors.grey.shade600 // Xám đậm hơn cho dark mode
        : Colors.grey; // Xám mặc định cho light mode

    const selectedIconTheme = IconThemeData(size: 25.0);
    const unselectedIconTheme = IconThemeData(size: 20.0);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ??
          const BorderRadius.only(
            topLeft: Radius.circular(10.0), // Bo tròn góc trên trái
            topRight: Radius.circular(10.0), // Bo tròn góc trên phải
            bottomLeft: Radius.circular(38.0), // Bo tròn góc duoi phải
            bottomRight: Radius.circular(38.0), // Bo tròn góc duoi phải
          ),
        border: Border.all(
          color: borderColor,
          width: topBorderThickness,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ??
              const BorderRadius.only(
                topLeft: Radius.circular(10.0), // Bo tròn góc trên trái
                topRight: Radius.circular(10.0), // Bo tròn góc trên phải
                bottomLeft: Radius.circular(38.0), // Bo tròn góc duoi phải
                bottomRight: Radius.circular(38.0), // Bo tròn góc duoi phải
              ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
          child: Theme(
            data: Theme.of(context).copyWith(
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
                selectedIconTheme: selectedIconTheme,
                unselectedIconTheme: unselectedIconTheme,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
