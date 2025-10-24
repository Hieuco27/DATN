import 'package:flutter/material.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: Colors.white,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(context), _buildMenuItems(context)],
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 20,
      bottom: 20,
    ),
    color: Colors.blue,
    child: Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 40, color: Colors.blue),
        ),
        SizedBox(height: 10),
        Text(
          'Tên người dùng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'user@example.com',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildMenuItems(BuildContext context) => Column(
    children: [
      ListTile(
        leading: Icon(Icons.home, color: Colors.black87),
        title: Text('Home', style: TextStyle(color: Colors.black87)),
        onTap: () {
          // Đóng drawer sau khi chọn
          Navigator.pop(context);
        },
      ),

      ExpansionTile(
        leading: Icon(Icons.search, color: Colors.black87),
        title: Text(
          'Tra cứu tài liệu',
          style: TextStyle(color: Colors.black87),
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: ListTile(
              leading: Icon(Icons.book, size: 20, color: Colors.black87),
              title: Text('Sách', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                // Thêm hành động khi chọn Sách
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: ListTile(
              leading: Icon(Icons.article, size: 20, color: Colors.black87),
              title: Text('Báo chí', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                // Thêm hành động khi chọn Báo chí
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: ListTile(
              leading: Icon(Icons.description, size: 20, color: Colors.black87),
              title: Text('Tài liệu', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                // Thêm hành động khi chọn Tài liệu
              },
            ),
          ),
        ],
      ),
    ],
  );
}
