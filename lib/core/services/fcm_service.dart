import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> setupFCM() async {

  final messaging = FirebaseMessaging.instance;

  // 🔥 Request permission
  await messaging.requestPermission();

  // 🔥 Get token
  final token = await messaging.getToken();

  print("🔥 FCM TOKEN: $token");

  final user =
      FirebaseAuth.instance.currentUser;

  // 🔥 Save token to Firestore
  if (user != null && token != null) {

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({

      "fcmToken": token,

    }, SetOptions(merge: true));
  }

  // 🔥 Refresh token
  FirebaseMessaging.instance
      .onTokenRefresh
      .listen((newToken) async {

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser != null) {

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .set({

        "fcmToken": newToken,

      }, SetOptions(merge: true));
    }
  });
}