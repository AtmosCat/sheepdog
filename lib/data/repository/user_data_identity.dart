/// 사용자 기록 저장 위치. 값을 바꾸면 업데이트 후 기존 데이터가 안 보인다.
class UserDataIdentity {
  UserDataIdentity._();

  static const androidApplicationId = 'com.middlenamestudio.sheepdog';
  static const iosBundleId = 'com.middlenamestudio.sheepdog';
  static const sqliteFileName = 'sheepdog.db';
  static const sqliteSchemaVersion = 4;
  static const notificationDbFileName = 'notification_history.db';
}
