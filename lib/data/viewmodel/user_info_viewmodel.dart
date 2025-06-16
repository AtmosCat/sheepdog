import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheepdog/data/model/app_user.dart';

class UserInfoViewModel extends ChangeNotifier {
  AppUser? _userInfo;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  UserInfoViewModel() {
    listenUserInfo();
  }

  AppUser? get userInfo => _userInfo;

  void listenUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userDocSubscription?.cancel(); 

    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            _userInfo = AppUser.fromMap(doc.data()!);
            notifyListeners();
          }
        });
  }

  void setUserInfo(AppUser userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }
}
