/**
 * Import function triggers from their respective submodules:
 */
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler"); // 1번만 선언
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

// 예약 알림 저장 함수 (Flutter 앱에서 POST 요청)
exports.schedulePaymentNotifications = onRequest(async (req, res) => {
  // CORS 허용 (필요시)
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST, GET, DELETE');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    if (req.method === 'POST') {
      const schedules = req.body.schedules;
      if (!Array.isArray(schedules)) {
        logger.error("Invalid schedules payload");
        return res.status(400).send('Invalid schedules');
      }

      const batch = admin.firestore().batch();
      schedules.forEach((item) => {
        const ref = admin.firestore().collection('scheduled_notifications').doc();
        batch.set(ref, {
          ...item,
          sent: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();

      logger.info(`Saved ${schedules.length} scheduled notifications`);
      res.status(200).send('ok');
    } else if (req.method === 'DELETE') {
      // 예약 알림 취소(삭제)
      const { subscriptionId } = req.body;
      if (!subscriptionId) {
        logger.error("No subscriptionId for deletion");
        return res.status(400).send('No subscriptionId');
      }
      const snap = await admin.firestore()
        .collection('scheduled_notifications')
        .where('subscriptionId', '==', subscriptionId)
        .get();
      const batch = admin.firestore().batch();
      snap.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      logger.info(`Deleted notifications for subscriptionId: ${subscriptionId}`);
      res.status(200).send('deleted');
    } else if (req.method === 'GET') {
      // 예약 알림 전체 조회 (테스트/관리용)
      const snap = await admin.firestore()
        .collection('scheduled_notifications')
        .orderBy('notifyDate')
        .get();
      const data = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      res.status(200).json(data);
    } else {
      res.status(405).send('Method Not Allowed');
    }
  } catch (e) {
    logger.error("Error in schedulePaymentNotifications", e);
    res.status(500).send('Server error');
  }
});

// 예약 알림 자동 발송 스케줄러 (5분마다 실행)
exports.sendScheduledNotifications = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: 'asia-northeast3'
  },
  async (event) => {
    const now = new Date();
    const nowISO = now.toISOString();

    const snapshot = await admin.firestore()
      .collection('scheduled_notifications')
      .where('sent', '==', false)
      .where('notifyDate', '<=', nowISO)
      .get();

    if (snapshot.empty) return;

    const messages = [];
    const batch = admin.firestore().batch();

    snapshot.forEach(doc => {
      const data = doc.data();
      if (!data.fcmToken) return;
      messages.push({
        token: data.fcmToken,
        notification: {
          title: "구독 결제 알림",
          body: data.message,
        },
        data: {
          type: data.type,
          subscriptionNames: Array.isArray(data.subscriptionNames) ? data.subscriptionNames.join(',') : '',
        }
      });
      batch.update(doc.ref, {sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp()});
    });

    if (messages.length > 0) {
      const messaging = admin.messaging();
      for (const msg of messages) {
        try {
          await messaging.send(msg);
        } catch (e) {
          logger.error("FCM send error:", e);
        }
      }
    }

    await batch.commit();
  }
);
