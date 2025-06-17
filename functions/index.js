const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const moment = require('moment-timezone');
const EXPIRATION_TIME = 1000 * 60 * 60 * 24 * 180; // 180일(ms)
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

        // uid, fcmToken, notifications, futureOnNotifyDates, futureBeforeNotifyDates를 받아야 함
        const {uid, fcmToken, notifications, futureOnNotifyDates, futureBeforeNotifyDates} = req.body;

        // 유효성 검증
        if (
          !uid ||
          !fcmToken ||
          !Array.isArray(futureOnNotifyDates) ||
          !Array.isArray(futureBeforeNotifyDates) ||
          !Array.isArray(notifications)
        ) {
          logger.error("Invalid payload", req.body);
          return res.status(400).send('Invalid payload');
        }

        // 알림 타입 체크 및 저장 데이터 구성
        const validTypes = ['before', 'on'];
        const dataToSave = {
          fcmToken,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          futureOnNotifyDates,        // ISO8601 문자열 배열로 저장
          futureBeforeNotifyDates,    // ISO8601 문자열 배열로 저장
        };

        // notifications가 비어있지 않으면 before/on 저장, 아니면 삭제 처리
        if (notifications.length > 0) {
          notifications.forEach(item => {
            if (!item.type || !validTypes.includes(item.type)) {
              logger.error("Invalid notification type", item);
              return res.status(400).send('Invalid notification type');
            }
            // futureOnNotifyDates가 비어있으면 on 알림 삭제, futureBeforeNotifyDates가 비어있으면 before 알림 삭제
            if (item.type === 'before' && futureBeforeNotifyDates.length === 0) {
              dataToSave['before'] = admin.firestore.FieldValue.delete();
            } else if (item.type === 'on' && futureOnNotifyDates.length === 0) {
              dataToSave['on'] = admin.firestore.FieldValue.delete();
            } else {
              dataToSave[item.type] = {
                notifyOn: item.notifyOn,
                notifyTime: item.notifyTime,
                nextNotifyDate: item.nextNotifyDate,
              };
            }
          });
        } else {
          // 알림 정보 삭제 처리
          dataToSave['before'] = admin.firestore.FieldValue.delete();
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

    const messageTemplates = {
      before: "내일 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
      on: "오늘 결제 예정인 구독 서비스가 있습니다.\n지금 바로 확인해보세요!",
    };

    const sentSet = { before: new Set(), on: new Set() };

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const uid = doc.id;
      logger.info(`[알림 스케줄러] 유저 문서 처리 시작: ${uid}`);

      const fcmToken = data.fcmToken;
      if (!fcmToken) {
        logger.error(`[알림 스케줄러] fcmToken 없음, uid: ${uid}`);
        continue;
      }

      // futureOnNotifyDates와 futureBeforeNotifyDates 배열을 가져옴 (ISO8601 문자열 배열)
      let futureOnNotifyDates = Array.isArray(data.futureOnNotifyDates)
        ? data.futureOnNotifyDates.map(str => moment(str))
        : [];
      let futureBeforeNotifyDates = Array.isArray(data.futureBeforeNotifyDates)
        ? data.futureBeforeNotifyDates.map(str => moment(str))
        : [];

      for (const type of ['before', 'on']) {
        const notifyData = data[type];
        if (
          notifyData &&
          notifyData.notifyOn === true &&
          notifyData.nextNotifyDate &&
          moment.tz(notifyData.nextNotifyDate, "Asia/Seoul").isSameOrBefore(now)
        ) {
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

            // 알림 발송일을 해당 futureNotifyDates에서 삭제
            let updatedFields = {};
            let nextNotifyDate = null;
            let targetList, notifyTime;

            if (type === 'before') {
              targetList = futureBeforeNotifyDates;
              notifyTime = notifyData.notifyTime || '09:00';
            } else {
              targetList = futureOnNotifyDates;
              notifyTime = notifyData.notifyTime || '09:00';
            }

            // 삭제: now(또는 nextNotifyDate와 같은 날짜)와 같은 날짜를 리스트에서 제거
            targetList = targetList.filter(dt =>
              !dt.isSame(moment.tz(notifyData.nextNotifyDate, "Asia/Seoul"), 'day')
            );

            // 오름차순 정렬
            targetList.sort((a, b) => a.valueOf() - b.valueOf());

            // 다음 알림 예약일 갱신
            if (targetList.length > 0) {
              const nextDate = targetList[0];
              nextNotifyDate = nextDate
                .hour(Number(notifyTime.split(':')[0]))
                .minute(Number(notifyTime.split(':')[1]))
                .second(0)
                .millisecond(0)
                .toISOString();
              updatedFields[`${type}.nextNotifyDate`] = nextNotifyDate;
            } else {
              // futureNotifyDates가 비어 있으면 알림 정보 삭제
              updatedFields[`${type}`] = admin.firestore.FieldValue.delete();
            }

            // futureNotifyDates를 DB에 반영
            if (type === 'before') {
              updatedFields['futureBeforeNotifyDates'] = targetList.map(dt => dt.toISOString());
            } else {
              updatedFields['futureOnNotifyDates'] = targetList.map(dt => dt.toISOString());
            }
            updatedFields['updatedAt'] = admin.firestore.FieldValue.serverTimestamp();

            batch.update(doc.ref, updatedFields);
            logger.info(`[알림 스케줄러] nextNotifyDate 갱신: (${type}) → ${nextNotifyDate}`);
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

    // Firestore의 updatedAt 필드가 180일 이상 갱신되지 않은 문서 찾기
    const staleTokensSnapshot = await admin.firestore()
      .collection('users')
      .where('updatedAt', '<', new Date(expirationTimestamp))
      .get();

    if (staleTokensSnapshot.empty) {
      console.log('[pruneStaleFcmTokens] 만료 토큰 없음');
      return;
    }

    // 만료된 토큰(문서) 삭제
    const batch = admin.firestore().batch();
    staleTokensSnapshot.forEach(doc => {
      batch.delete(doc.ref);
      console.log(`[pruneStaleFcmTokens] 만료 토큰 문서 삭제: ${doc.id}`);
    });

    await batch.commit();
    console.log(`[pruneStaleFcmTokens] 총 ${staleTokensSnapshot.size}개 만료 토큰 삭제 완료`);
  }
);