import 'package:flutter/material.dart';

class CustomSwitchListTile extends StatelessWidget {
  final String title; // Tiêu đề
  final String? subtitle; // Mô tả (tùy chọn)
  final bool value; // Giá trị trạng thái (true/false)
  final ValueChanged<bool> onChanged; // Hàm gọi khi thay đổi trạng thái
  final Color? switchActiveColor; // Màu khi switch bật
  final Color? switchInactiveColor; // Màu khi switch tắt
  final Color? switchTrackColor; // Màu track của switch
  final Widget? secondary; // Icon hoặc widget tùy chỉnh phía bên phải

  const CustomSwitchListTile({
    required this.title,
    this.subtitle, // Tùy chọn
    required this.value,
    required this.onChanged,
    this.switchActiveColor,
    this.switchInactiveColor,
    this.switchTrackColor,
    this.secondary, // Thêm tham số này
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness; // Kiểm tra chế độ sáng/tối

    // Chọn màu văn bản cho phù hợp với chế độ sáng/tối
    final titleColor = brightness == Brightness.dark
        ? Colors.white // Chế độ tối, chữ trắng
        : Colors.black; // Chế độ sáng, chữ đen

    final subtitleColor = brightness == Brightness.dark
        ? Colors.grey.shade300 // Chế độ tối, chữ xám sáng
        : Colors.grey; // Chế độ sáng, chữ xám đậm

    return ListTile(
      leading: secondary, // Đặt icon ở đây
      title: Text(
        title,
        style: TextStyle(color: titleColor), // Màu title theo chế độ sáng/tối
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: subtitleColor), // Màu subtitle theo chế độ sáng/tối
            )
          : null, // Nếu không có subtitle thì không hiển thị
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: switchActiveColor ?? const Color.fromARGB(255, 224, 127, 10), // Màu khi bật switch
        inactiveThumbColor: switchInactiveColor ?? const Color.fromARGB(251, 215, 130, 61), // Màu thumb khi tắt
        inactiveTrackColor: switchTrackColor ?? const Color.fromARGB(107, 241, 120, 21), // Màu track khi tắt
      ),
    );
  }
}
