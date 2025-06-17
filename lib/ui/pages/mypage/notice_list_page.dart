import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheepdog/ui/pages/mypage/notice_detail_page.dart';

class NoticeListPage extends StatelessWidget {
  const NoticeListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainYellow = Color(0xFFFFD600); // 앱의 메인 노란색(예시)

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('공지사항'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('number', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: mainYellow),
                  const SizedBox(height: 20),
                  const Text(
                    '공지사항을 불러오는 중입니다...',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final title = doc['title'] ?? '';
              final date = doc['date'] ?? '';
              return ListTile(
                title: Text(title, style: const TextStyle(fontSize: 16)),
                trailing: Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoticeDetailPage(noticeDoc: doc),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
