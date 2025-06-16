import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sheepdog/data/viewmodel/user_info_viewmodel.dart';
import 'package:sheepdog/theme/colors.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInfoViewModel>(context).userInfo;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        centerTitle: true,
        title: const Text('내 정보'),
        backgroundColor: AppColor.containerWhite.of(context),
        elevation: 0,
      ),
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('가입일시', _formatDate(userInfo.createdAt)),
                  const SizedBox(height: 16),
                  _infoRow('디바이스 정보(ID)', userInfo.deviceId ?? '-'),
                  const SizedBox(height: 16),
                  _infoRow(
                    '유료 앱 결제 여부',
                    userInfo.isPremium ? 'O' : 'X',
                    valueColor: userInfo.isPremium
                        ? AppColor.mainYellow.of(context)
                        : AppColor.gray20.of(context),
                  ),
                ],
              ),
            ),
    );
  }

  // 가입일시 포맷 함수
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  // 정보 표시용 위젯
  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
