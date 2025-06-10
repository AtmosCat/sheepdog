const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

// 알림 설정/예약 정보 저장 (Flutter에서 POST)
// userId 대신 fcmToken을 식별자로 사용
exports.saveUserNotificationSettings = onRequest(
  { region: 'asia-northeast3' },   // ← region 옵션 추가!
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
        // body: { userId, notifications: [...] }
        // userId = fcmToken
        logger.info("Request body:", req.body); // 실제 body 로그로 확인

        const {userId, notifications} = req.body;

        // 유효성 검증: 필드 존재, notifications는 배열, 1~3개
        if (
          !userId ||
          !Array.isArray(notifications) ||
          notifications.length === 0 ||
          notifications.length > 3
        ) {
          logger.error("Invalid notifications payload", req.body);
          return res.status(400).send('Invalid notifications payload');
        }

        // 각 알림 타입이 before/on/after인지 체크
        const validTypes = ['before', 'on', 'after'];
        for (const item of notifications) {
          if (!item.type || !validTypes.includes(item.type)) {
            logger.error("Invalid notification type", item);
            return res.status(400).send('Invalid notification type');
          }
        }

        const batch = admin.firestore().batch();
        notifications.forEach((item) => {
          // 문서ID: <fcmToken>_<type> (예: fcmToken_before)
          const docId = `${userId}_${item.type}`;
          const ref = admin.firestore().collection('user_notifications').doc(docId);
          batch.set(ref, {
            ...item,
            userId, // == fcmToken
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        });
        await batch.commit();

        logger.info(`Saved notification settings for fcmToken: ${userId}`);
        res.status(200).send('ok');
      } else if (req.method === 'GET') {
        // 전체 유저 알림 설정 조회 (관리용)
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

// 알림 자동 발송 스케줄러 (5분마다 실행)
exports.sendUserNotifications = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'asia-northeast3'
  },
  async (event) => {
    const nowISO = new Date().toISOString();

    // nextNotifyDate가 도래(과거/현재)하고 notifyOn=true인 문서만 조회
    const snapshot = await admin.firestore()
      .collection('user_notifications')
      .where('notifyOn', '==', true)
      .where('nextNotifyDate', '<=', nowISO)
      .get();

    if (snapshot.empty) return;

    const batch = admin.firestore().batch();
    const messaging = admin.messaging();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (!data.fcmToken) {
        logger.error('No fcmToken for notification:', doc.id);
        continue;
      }
      // FCM 발송
      try {
        await messaging.send({
          token: data.fcmToken,
          notification: {
            title: "구독 결제 알림",
            body: data.message,
          },
          data: {
            type: data.type || '',
          }
        });
        // 발송 후 nextNotifyDate, message 등 갱신 (예: 1달 뒤로 갱신)
        let nextDate = new Date(data.nextNotifyDate);
        if (data.type === 'before' || data.type === 'on' || data.type === 'after') {
          nextDate.setMonth(nextDate.getMonth() + 1);
        }
        batch.update(doc.ref, {
          nextNotifyDate: nextDate.toISOString(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (e) {
        logger.error("FCM send error:", e);
      }
    }

    await batch.commit();
  }
);
