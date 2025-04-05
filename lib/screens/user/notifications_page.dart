import 'package:flutter/material.dart';

import '../../components/app_bar/custom_app_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:const CustomAppBar(
        title: 'Thông báo',
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 206, 128, 72),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text('Thông báo ${index + 1}'),
              subtitle: Text('Nội dung thông báo cho mục $index'),
              trailing: Text('${DateTime.now().hour}:${DateTime.now().minute}'),
              onTap: () {
                // Handle notification tap
              },
            ),
          );
        },
      ),
    );
  }
}