const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

// 알림 설정/예약 정보 저장 (Flutter에서 POST)
exports.saveUserNotificationSettings = onRequest(
  { region: 'asia-northeast3' },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST, GET');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    try {
      if (req.method === 'POST') {
        logger.info("Request body:", req.body);

        const {userId, notifications} = req.body;

        // 유효성 검증
        if (
          !userId ||
          !Array.isArray(notifications) ||
          notifications.length === 0 ||
          notifications.length > 3
        ) {
          logger.error("Invalid notifications payload", req.body);
          return res.status(400).send('Invalid notifications payload');
        }

        // 알림 타입 체크
        const validTypes = ['before', 'on', 'after'];
        for (const item of notifications) {
          if (!item.type || !validTypes.includes(item.type)) {
            logger.error("Invalid notification type", item);
            return res.status(400).send('Invalid notification type');
          }
        }

        const batch = admin.firestore().batch();
        notifications.forEach((item) => {
          const docId = `${userId}_${item.type}`;
          const ref = admin.firestore().collection('user_notifications').doc(docId);
          batch.set(ref, {
            ...item,
            userId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            // message 필드는 클라이언트에서 안 보내도 됨
          }, {merge: true});
        });
        await batch.commit();

        logger.info(`Saved notification settings for fcmToken: ${userId}`);
        res.status(200).send('ok');
      } else if (req.method === 'GET') {
        const snap = await admin.firestore().collection('user_notifications').get();
        const data = snap.docs.map(doc => ({id: doc.id, ...doc.data()}));
        res.status(200).json(data);
      } else {
        res.status(405).send('Method Not Allowed');
      }
    } catch (e) {
      logger.error("Error in saveUserNotificationSettings", e);
      res.status(500).send('Server error');
    }
  }
);

exports.sendUserNotifications = onSchedule(
  {
    schedule: '*/5 * * * *',
    region: 'asia-northeast3'
  },
  async (event) => {
    const nowISO = new Date().toISOString();

    logger.info(`[알림 스케줄러] 실행 시작: ${nowISO}`);

    const snapshot = await admin.firestore()
      .collection('user_notifications')
      .where('notifyOn', '==', true)
      .where('nextNotifyDate', '<=', nowISO)
      .get();

    logger.info(`[알림 스케줄러] 발송 대상 문서 수: ${snapshot.size}`);

    if (snapshot.empty) {
      logger.info("[알림 스케줄러] 발송 대상 없음, 종료");
      return;
    }

    const batch = admin.firestore().batch();
    const messaging = admin.messaging();

    // type별 메시지 템플릿
    const messageTemplates = {
      before: "내일 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
      on: "오늘 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
      after: "어제 결제 예정이었던 구독 서비스가 있습니다.\n지금 바로 확인해보세요!"
    };

    for (const doc of snapshot.docs) {
      const data = doc.data();
      logger.info(`[알림 스케줄러] 문서 처리 시작: ${doc.id}`);

      if (!data.fcmToken) {
        logger.error(`[알림 스케줄러] fcmToken 없음, 문서ID: ${doc.id}`);
        continue;
      }
      try {
        // type에 따라 메시지 내용 결정
        const messageBody = messageTemplates[data.type] || "구독 결제 알림";

        logger.info(`[알림 스케줄러] FCM 발송 시도: 토큰=${data.fcmToken}, type=${data.type}, message=${messageBody}`);
        await messaging.send({
          token: data.fcmToken,
          notification: {
            title: "구독 결제 알림",
            body: messageBody,
          },
          data: {
            type: data.type || '',
          }
        });
        logger.info(`[알림 스케줄러] FCM 발송 성공: 토큰=${data.fcmToken}, type=${data.type}`);

        // 발송 후 nextNotifyDate 갱신 (예: 1달 뒤로 갱신)
        let nextDate = new Date(data.nextNotifyDate);
        if (data.type === 'before' || data.type === 'on' || data.type === 'after') {
          nextDate.setMonth(nextDate.getMonth() + 1);
        }
        batch.update(doc.ref, {
          nextNotifyDate: nextDate.toISOString(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`[알림 스케줄러] nextNotifyDate 갱신: ${nextDate.toISOString()}`);
      } catch (e) {
        // 유효하지 않은 FCM 토큰이면 해당 문서 삭제
        if (
          e.code === 'messaging/registration-token-not-registered' ||
          e.code === 'messaging/invalid-registration-token' ||
          e.errorInfo?.code === 'messaging/registration-token-not-registered' ||
          e.errorInfo?.code === 'messaging/invalid-registration-token'
        ) {
          await doc.ref.delete();
          logger.info(`[알림 스케줄러] 유효하지 않은 FCM 토큰 삭제: ${data.fcmToken}, 문서ID: ${doc.id}`);
        } else {
          logger.error(`[알림 스케줄러] FCM 발송 오류: ${e}, 문서ID: ${doc.id}`);
        }
      }
    }

    await batch.commit();
    logger.info("[알림 스케줄러] 전체 커밋 완료");
  }
);
