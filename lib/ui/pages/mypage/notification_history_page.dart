import 'package:flutter/material.dart';
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
                          SnackbarUtil.showToastMessage(
                            "알림 전송 내역이 모두 삭제되었습니다.",
                          );
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
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
                      separatorBuilder: (_, __) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        final dt = DateTime.tryParse(item['receivedAt'] ?? '');
                        final formattedDate = dt != null
                            ? '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '';

                        return Card(
                          color: AppColor.mainYellowLight3.of(
                            context,
                          ), // 옅은 회색 배경
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center, // 카드 전체 센터 정렬
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'lib/assets/icons/icon10.png', // 실제 앱 아이콘 경로로 교체
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.notifications,
                                        size: 28,
                                        color: AppColor.gray20.of(context),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // 오른쪽 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center, // 카드 전체 센터
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '구독 결제 알림',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColor.deepBlack.of(
                                                context,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColor.gray20.of(
                                                  context,
                                                ),
                                                fontWeight: FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['body'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColor.deepBlack.of(
                                              context,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
