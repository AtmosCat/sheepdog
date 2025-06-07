import 'package:flutter/material.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카테고리 관리')),
      body: const Center(child: Text('카테고리 관리 페이지 내용')),
    );
  }
}
