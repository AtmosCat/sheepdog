const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const moment = require('moment-timezone');
const EXPIRATION_TIME = 1000 * 60 * 60 * 24 * 180; // 180일(ms)
admin.initializeApp();

const PAYMENT_DAY_TITLE = "결제일 알림";
const PAYMENT_DAY_BODY = "오늘 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!";

// 알림 설정/예약 정보 저장 (Flutter에서 POST) — 결제일 알림(on)만 지원
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

        const {uid, fcmToken, notifications, futureOnNotifyDates} = req.body;

        if (
          !uid ||
          !fcmToken ||
          !Array.isArray(futureOnNotifyDates) ||
          !Array.isArray(notifications)
        ) {
          logger.error("Invalid payload", req.body);
          return res.status(400).send('Invalid payload');
        }

        const dataToSave = {
          fcmToken,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          futureOnNotifyDates,
          futureBeforeNotifyDates: admin.firestore.FieldValue.delete(),
          before: admin.firestore.FieldValue.delete(),
        };

        if (notifications.length > 0) {
          notifications.forEach(item => {
            if (!item.type || item.type !== 'on') {
              logger.error("Invalid notification type", item);
              return;
            }
            if (futureOnNotifyDates.length === 0) {
              dataToSave['on'] = {
                notifyOn: item.notifyOn,
                notifyTime: item.notifyTime,
                nextNotifyDate: null,
              };
            } else {
              dataToSave['on'] = {
                notifyOn: item.notifyOn,
                notifyTime: item.notifyTime,
                nextNotifyDate: item.nextNotifyDate,
              };
            }
          });
        } else {
          dataToSave['on'] = admin.firestore.FieldValue.delete();
        }

        const ref = admin.firestore().collection('users').doc(uid);
        await ref.set(dataToSave, {merge: true});

        logger.info(`Saved notification settings for uid: ${uid}`);
        res.status(200).send('ok');
      } else if (req.method === 'GET') {
        const snap = await admin.firestore().collection('users').get();
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

// 테스트 알림: Firestore users/{uid}의 fcmToken으로 실제 FCM 발송
exports.sendTestNotification = onRequest(
  { region: 'asia-northeast3' },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.status(204).send('');
      return;
    }

    try {
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      const {uid} = req.body;
      if (!uid) {
        return res.status(400).send('uid required');
      }

      const doc = await admin.firestore().collection('users').doc(uid).get();
      if (!doc.exists) {
        return res.status(404).send('user not found in Firestore');
      }

      const fcmToken = doc.data().fcmToken;
      if (!fcmToken) {
        return res.status(400).send('fcmToken missing in Firestore');
      }

      // 스케줄러(sendUserNotifications)와 동일한 페이로드로 FCM 발송
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: PAYMENT_DAY_TITLE,
          body: PAYMENT_DAY_BODY,
        },
        data: {
          type: 'on',
          test: 'true',
        },
      });

      logger.info(`[테스트 알림] Firestore→FCM 발송 성공: uid=${uid}`);
      res.status(200).send('ok');
    } catch (e) {
      logger.error("[테스트 알림] 발송 실패", e);
      res.status(500).send(e.message || 'Server error');
    }
  }
);

exports.sendUserNotifications = onSchedule(
  {
    schedule: '*/10 * * * *',
    region: 'asia-northeast3'
  },
  async (event) => {
    const now = moment().tz("Asia/Seoul");
    logger.info(`[알림 스케줄러] 실행 시작: ${now.toISOString()}`);

    const snapshot = await admin.firestore()
      .collection('users')
      .get();

    logger.info(`[알림 스케줄러] 전체 유저 수: ${snapshot.size}`);

    if (snapshot.empty) {
      logger.info("[알림 스케줄러] 발송 대상 없음, 종료");
      return;
    }

    const batch = admin.firestore().batch();
    const messaging = admin.messaging();
    const sentSet = new Set();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const uid = doc.id;
      logger.info(`[알림 스케줄러] 유저 문서 처리 시작: ${uid}`);

      const fcmToken = data.fcmToken;
      if (!fcmToken) {
        logger.error(`[알림 스케줄러] fcmToken 없음, uid: ${uid}`);
        continue;
      }

      let futureOnNotifyDates = Array.isArray(data.futureOnNotifyDates)
        ? data.futureOnNotifyDates.map(str => moment(str))
        : [];

      // 결제일 알림(on)만 처리
      const notifyData = data.on;
      if (
        notifyData &&
        notifyData.notifyOn === true &&
        notifyData.nextNotifyDate &&
        moment.tz(notifyData.nextNotifyDate, "Asia/Seoul").isSameOrBefore(now)
      ) {
        const sendKey = `${fcmToken}_on_${notifyData.nextNotifyDate}`;
        if (sentSet.has(sendKey)) {
          logger.info(`[알림 스케줄러] 중복 방지로 FCM 발송 SKIP: ${sendKey}`);
          continue;
        }
        sentSet.add(sendKey);

        try {
          logger.info(`[알림 스케줄러] FCM 발송 시도: 토큰=${fcmToken}`);
          await messaging.send({
            token: fcmToken,
            notification: {
              title: PAYMENT_DAY_TITLE,
              body: PAYMENT_DAY_BODY,
            },
            data: {
              type: 'on',
            }
          });
          logger.info(`[알림 스케줄러] FCM 발송 성공: 토큰=${fcmToken}`);

          const notifyTime = notifyData.notifyTime || '09:00';
          let targetList = futureOnNotifyDates.filter(dt =>
            !dt.isSame(moment.tz(notifyData.nextNotifyDate, "Asia/Seoul"), 'day')
          );
          targetList.sort((a, b) => a.valueOf() - b.valueOf());

          const updatedFields = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            before: admin.firestore.FieldValue.delete(),
            futureBeforeNotifyDates: admin.firestore.FieldValue.delete(),
            futureOnNotifyDates: targetList.map(dt => dt.toISOString()),
          };

          if (targetList.length > 0) {
            const [hh, mm] = notifyTime.split(':').map(Number);
            const nextNotifyDate = moment.tz(targetList[0].format('YYYY-MM-DD'), 'Asia/Seoul')
              .hour(hh)
              .minute(mm)
              .second(0)
              .millisecond(0)
              .format();
            updatedFields['on.nextNotifyDate'] = nextNotifyDate;
          } else {
            updatedFields['on'] = {
              notifyOn: true,
              notifyTime: notifyTime,
              nextNotifyDate: null,
            };
          }

          batch.update(doc.ref, updatedFields);
          logger.info(`[알림 스케줄러] nextNotifyDate 갱신 → ${updatedFields['on.nextNotifyDate'] || null}`);
        } catch (e) {
          const errorCode = e.code || e.errorInfo?.code;
          if (
            errorCode === 'messaging/registration-token-not-registered' ||
            errorCode === 'messaging/invalid-registration-token'
          ) {
            await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
            logger.info(`[알림 스케줄러] 유효하지 않은 FCM 토큰 삭제: ${fcmToken}, uid: ${uid}`);
          } else {
            logger.error(`[알림 스케줄러] FCM 발송 오류: ${e}, uid: ${uid}`);
          }
        }
      }
    }

    await batch.commit();
    logger.info("[알림 스케줄러] 전체 커밋 완료");
  }
);


exports.pruneStaleFcmTokens = onSchedule(
  {
    schedule: 'every 24 hours',
    region: 'asia-northeast3'
  },
  async (event) => {
    const now = Date.now();
    const expirationTimestamp = now - EXPIRATION_TIME;

    const staleTokensSnapshot = await admin.firestore()
      .collection('users')
      .where('updatedAt', '<', new Date(expirationTimestamp))
      .get();

    if (staleTokensSnapshot.empty) {
      console.log('[pruneStaleFcmTokens] 만료 토큰 없음');
      return;
    }

    const batch = admin.firestore().batch();
    staleTokensSnapshot.forEach(doc => {
      batch.delete(doc.ref);
      console.log(`[pruneStaleFcmTokens] 만료 토큰 문서 삭제: ${doc.id}`);
    });

    await batch.commit();
    console.log(`[pruneStaleFcmTokens] 총 ${staleTokensSnapshot.size}개 만료 토큰 삭제 완료`);
  }
);
