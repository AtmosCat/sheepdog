import 'package:flutter/material.dart';

class PaidAppInfoPage extends StatelessWidget {
  const PaidAppInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('유료 앱 안내')),
      body: const Center(child: Text('유료 앱 안내 페이지 내용')),
    );
  }
}
