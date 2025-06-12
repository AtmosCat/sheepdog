const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const moment = require('moment-timezone');
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

        const {fcmToken, notifications} = req.body;

        // 유효성 검증
        if (
          !fcmToken ||
          !Array.isArray(notifications) ||
          notifications.length === 0 ||
          notifications.length > 2 // before, on만 허용
        ) {
          logger.error("Invalid notifications payload", req.body);
          return res.status(400).send('Invalid notifications payload');
        }

        // 알림 타입 체크
        const validTypes = ['before', 'on'];
        const dataToSave = {};
        for (const item of notifications) {
          if (!item.type || !validTypes.includes(item.type)) {
            logger.error("Invalid notification type", item);
            return res.status(400).send('Invalid notification type');
          }
          // before, on 각각의 설정을 문서의 필드로 저장
          dataToSave[item.type] = {
            notifyOn: item.notifyOn,
            notifyTime: item.notifyTime,
            nextNotifyDate: item.nextNotifyDate,
            cycle: item.cycle, // 필요시 추가
          };
        }
        dataToSave['fcmToken'] = fcmToken;
        dataToSave['updatedAt'] = admin.firestore.FieldValue.serverTimestamp();

        // 토큰을 문서 ID로 사용
        const ref = admin.firestore().collection('user_notifications').doc(fcmToken);
        await ref.set(dataToSave, {merge: true});

        logger.info(`Saved notification settings for fcmToken: ${fcmToken}`);
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
    schedule: '*/10 * * * *',
    region: 'asia-northeast3'
  },
  async (event) => {
    const now = moment().tz("Asia/Seoul");
    logger.info(`[알림 스케줄러] 실행 시작: ${now.toISOString()}`);

    const snapshot = await admin.firestore()
      .collection('user_notifications')
      .get();

    logger.info(`[알림 스케줄러] 전체 문서 수: ${snapshot.size}`);

    if (snapshot.empty) {
      logger.info("[알림 스케줄러] 발송 대상 없음, 종료");
      return;
    }

    const batch = admin.firestore().batch();
    const messaging = admin.messaging();

    // type별 메시지 템플릿
    const messageTemplates = {
      before: "내일 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
      on: "오늘 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
    };

    // [수정] type별(결제 전/당일)로 중복 발송 방지 (서로 다른 type은 같은 시각에 각각 발송 허용)
    const sentSet = { before: new Set(), on: new Set() };

    for (const doc of snapshot.docs) {
      const data = doc.data();
      logger.info(`[알림 스케줄러] 문서 처리 시작: ${doc.id}`);

      const fcmToken = data.fcmToken;
      if (!fcmToken) {
        logger.error(`[알림 스케줄러] fcmToken 없음, 문서ID: ${doc.id}`);
        continue;
      }

      for (const type of ['before', 'on']) {
        const notifyData = data[type];
        if (
          notifyData &&
          notifyData.notifyOn === true &&
          notifyData.nextNotifyDate &&
          moment.tz(notifyData.nextNotifyDate, "Asia/Seoul").isSameOrBefore(now)
        ) {
          // [수정] type별로만 중복 발송 방지 (같은 type+토큰+시각 조합만 차단)
          const sendKey = `${fcmToken}_${type}_${notifyData.nextNotifyDate}`;
          if (sentSet[type].has(sendKey)) {
            logger.info(`[알림 스케줄러] 중복 방지로 FCM 발송 SKIP: ${sendKey}`);
            continue;
          }
          sentSet[type].add(sendKey);

          try {
            const messageBody = messageTemplates[type] || "구독 결제 알림";

            logger.info(`[알림 스케줄러] FCM 발송 시도: 토큰=${fcmToken}, type=${type}, message=${messageBody}`);
            await messaging.send({
              token: fcmToken,
              notification: {
                title: "구독 결제 알림",
                body: messageBody,
              },
              data: {
                type: type,
              }
            });
            logger.info(`[알림 스케줄러] FCM 발송 성공: 토큰=${fcmToken}, type=${type}`);

            // nextNotifyDate 갱신
            let nextNotifyDate = moment.tz(notifyData.nextNotifyDate, "Asia/Seoul");
            let candidate = nextNotifyDate.clone();
            while (!candidate.isAfter(now)) {
              if (notifyData.cycle === 'monthly') {
                candidate.add(1, 'month');
              } else if (notifyData.cycle === 'weekly') {
                candidate.add(1, 'week');
              } else if (notifyData.cycle === 'yearly') {
                candidate.add(1, 'year');
              } else {
                candidate.add(1, 'month');
              }
            }
            batch.update(doc.ref, {
              [`${type}.nextNotifyDate`]: candidate.toISOString(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.info(`[알림 스케줄러] nextNotifyDate 갱신: ${candidate.toISOString()} (${type})`);
          } catch (e) {
            if (
              e.code === 'messaging/registration-token-not-registered' ||
              e.code === 'messaging/invalid-registration-token' ||
              e.errorInfo?.code === 'messaging/registration-token-not-registered' ||
              e.errorInfo?.code === 'messaging/invalid-registration-token'
            ) {
              await doc.ref.delete();
              logger.info(`[알림 스케줄러] 유효하지 않은 FCM 토큰 삭제: ${fcmToken}, 문서ID: ${doc.id}`);
            } else {
              logger.error(`[알림 스케줄러] FCM 발송 오류: ${e}, 문서ID: ${doc.id}`);
            }
          }
        }
      }
    }

    await batch.commit();
    logger.info("[알림 스케줄러] 전체 커밋 완료");
  }
);

