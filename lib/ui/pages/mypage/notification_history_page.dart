import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/repository/local_notification_repository.dart';
import 'package:sheepdog/theme/colors.dart';
import 'package:sheepdog/ui/utils/snackbar_utils.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({Key? key}) : super(key: key);

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLatestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await LocalNotificationRepository()
        .getAllNotifications();
    setState(() {
      _notifications = notifications;
      if (!_isLatestFirst) {
        _notifications = _notifications.reversed.toList();
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isLatestFirst = !_isLatestFirst;
      _notifications = _notifications.reversed.toList();
    });
  }

  String _formatDate(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    return DateFormat('yyyy.MM.dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 전송 내역'),
        centerTitle: true,
        leading: BackButton(),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear_all') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('전체 삭제'),
                    content: Text('모든 알림 전송 내역을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: AppColor.mainYellow.of(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          SnackbarUtil.showToastMessage("알림 전송 내역이 모두 삭제되었습니다.");
                        },
                        child: Text(
                          '확인',
                          style: TextStyle(
                            color: AppColor.defaultBlack.of(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await LocalNotificationRepository().clearAll();
                  setState(() {
                    _notifications = [];
                  });
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear_all', child: Text('전체 내역 삭제')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 정렬 토글 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _toggleSortOrder,
              child: Text(
                _isLatestFirst ? '↓최신순' : '↓오래된순',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: AppColor.deepBlack.of(context),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? const Center(child: Text('알림 전송 내역이 없습니다.'))
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColor.lightGray10.of(context),
                    ),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return ListTile(
                        title: Text(
                          item['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item['body'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.deepBlack.of(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          _formatDate(item['receivedAt'] ?? ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          // 필요시 알림 상세 페이지 이동 등 추가 가능
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
