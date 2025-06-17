import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot noticeDoc;
  const NoticeDetailPage({required this.noticeDoc, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = noticeDoc['title'] ?? '';
    final content = noticeDoc['content'] ?? '';
    final date = noticeDoc['date'] ?? ''; // YYYY.MM.DD 형식의 date 필드 사용

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 28),
            Text(
              content,
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
