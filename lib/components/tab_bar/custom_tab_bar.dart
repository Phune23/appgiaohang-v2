import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final Widget? leading;
  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final Color? lightTextColor;
  final Color? darkTextColor;
  final Color? lightIconColor;
  final Color? darkIconColor;
  final BorderRadius? borderRadius;
  final Color? lightBorderColor;
  final Color? darkBorderColor;
  final double topBorderThickness;
  final double leftBorderThickness;
  final double rightBorderThickness;
  final double bottomBorderThickness;
  final double height; // Chiều cao của TabBar
  final double topPadding; // Padding phía trên của TabBar

  const CustomTabBar({
    required this.tabs,
    this.leading,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightTextColor,
    this.darkTextColor,
    this.lightIconColor,
    this.darkIconColor,
    this.borderRadius,
    this.lightBorderColor,
    this.darkBorderColor,
    this.topBorderThickness = 2.0, // Độ dày viền trên
    this.leftBorderThickness = 2.0, // Độ dày viền trái
    this.rightBorderThickness = 2.0, // Độ dày viền phải
    this.bottomBorderThickness = 4.0, // Độ dày viền dưới
    this.height = kToolbarHeight, // Chiều cao mặc định là kToolbarHeight
    this.topPadding = 0.0, // Mặc định là 0
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Màu nền
    final backgroundColor = brightness == Brightness.dark
        ? darkBackgroundColor ?? const Color.fromARGB(255, 117, 63, 25)
        : lightBackgroundColor ?? const Color.fromARGB(255, 210, 134, 79);

    // Màu chữ
    final textColor = brightness == Brightness.dark
        ? darkTextColor ?? Colors.white
        : lightTextColor ?? Colors.black;

    // Màu icon
    final iconColor = brightness == Brightness.dark
        ? darkIconColor ?? Colors.white
        : lightIconColor ?? Colors.black;

    // Màu viền
    final borderColor = brightness == Brightness.dark
        ? darkBorderColor ?? const Color.fromARGB(255, 211, 155, 103).withOpacity(0.7)
        : lightBorderColor ?? Colors.black.withOpacity(0.7);

    return PreferredSize(
      preferredSize: Size.fromHeight(height + topPadding), // Thêm padding vào chiều cao
      child: Container(
        padding: EdgeInsets.only(top: topPadding), // Áp dụng padding phía trên
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ??
              const BorderRadius.only(
                topLeft: Radius.circular(38.0), // Bo tròn góc trên trái
                topRight: Radius.circular(38.0), // Bo tròn góc trên phải
                bottomLeft: Radius.circular(20.0), // Bo tròn góc dưới trái
                bottomRight: Radius.circular(20.0), // Bo tròn góc dưới phải
              ),
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: topBorderThickness,
            ),
            left: BorderSide(
              color: borderColor,
              width: leftBorderThickness,
            ),
            right: BorderSide(
              color: borderColor,
              width: rightBorderThickness,
            ),
            bottom: BorderSide(
              color: borderColor,
              width: bottomBorderThickness,
            ),
          ),
        ),
        child: TabBar(
          tabs: tabs,
          labelColor: textColor,  // Màu chữ khi tab được chọn
          unselectedLabelColor: textColor.withOpacity(0.7),  // Màu chữ khi tab không được chọn
          indicatorColor: textColor,  // Màu chỉ báo dưới tab
          indicatorWeight: 1.0,  // Độ dày của chỉ báo
        ),
      ),
    );
  }
}
