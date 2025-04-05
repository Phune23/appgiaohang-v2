import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
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

  const CustomAppBar({
    required this.title,
    this.actions,
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Updated color scheme
    final gradientColors = brightness == Brightness.dark
        ? [
            const Color(0xFF8B4513),
            const Color(0xFF6B371F),
          ]
        : [
            const Color(0xFFE8A87C),
            const Color(0xFFD4845F),
          ];

    final textColor = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF2D1810);

    final iconColor = textColor;

    final borderColor = brightness == Brightness.dark
        ? Colors.orange.withOpacity(0.3)
        : const Color(0xFFB76E41).withOpacity(0.5);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: borderRadius ??
              const BorderRadius.only(
                bottomLeft: Radius.circular(25.0),
                bottomRight: Radius.circular(25.0),
              ),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          title: Text(
            title,
            style: TextStyle(color: textColor),
          ),
          actions: actions?.map((action) {
            // Tự động áp dụng màu icon
            if (action is IconButton) {
              return IconButton(
                icon: Icon(
                  (action.icon as Icon).icon,
                  color: iconColor,
                ),
                onPressed: action.onPressed,
              );
            }
            return action;
          }).toList(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0);
}
