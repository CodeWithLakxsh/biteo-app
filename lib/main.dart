// =============================================================
// lib/main.dart
// FINAL CLEAN STABLE VERSION + PUSH NOTIFICATIONS FIXED
// =============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

// 🔥 LOCATION INIT
import 'core/providers/location_provider.dart';

// =============================================================
// 🔥 FCM BACKGROUND HANDLER
// =============================================================

Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );

  debugPrint(
    "🔥 Background Message: ${message.messageId}",
  );
}

// =============================================================
// 🔥 NEW FCM INIT
// =============================================================

Future<void> initFCM() async {

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  // 🔥 ASK PERMISSION
  NotificationSettings settings =
      await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    "🔥 Notification Permission: ${settings.authorizationStatus}",
  );

  // 🔥 FOREGROUND OPTIONS
  await messaging
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 🔥 GET TOKEN
  final token =
      await messaging.getToken();

      await messaging.subscribeToTopic('all_users');

debugPrint(
  "🔥 SUBSCRIBED TO TOPIC",
);

  debugPrint(
    "🔥 NEW FCM TOKEN: $token",
  );

  final user =
      FirebaseAuth.instance.currentUser;

  if (user != null &&
      token != null) {

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({

      'fcmToken': token,

    }, SetOptions(merge: true));

    debugPrint(
      "🔥 TOKEN SAVED TO FIRESTORE",
    );
  }

  // 🔥 TOKEN REFRESH
  FirebaseMessaging.instance
      .onTokenRefresh
      .listen((newToken) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({

        'fcmToken': newToken,

      }, SetOptions(merge: true));

      debugPrint(
        "🔥 TOKEN REFRESHED",
      );
    }
  });

  // 🔥 FOREGROUND MESSAGE
  FirebaseMessaging.onMessage
      .listen((message) {

    debugPrint(
      "🔥 FOREGROUND NOTIFICATION RECEIVED",
    );

    debugPrint(
      "🔥 TITLE: ${message.notification?.title}",
    );

    debugPrint(
      "🔥 BODY: ${message.notification?.body}",
    );
  });

  // 🔥 NOTIFICATION CLICKED
  FirebaseMessaging.onMessageOpenedApp
      .listen((message) {

    debugPrint(
      "🔥 Notification Clicked",
    );
  });
}

// =============================================================
// MAIN
// =============================================================

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    "🚀 STEP 1: Flutter Engine Initialized",
  );

  try {

    // ── ENV ───────────────────────────
    // .env is optional at build/run time. Real credentials must never be
    // committed; developers create a local (git-ignored) .env from
    // .env.example. The app boots normally when .env is absent.
    await dotenv.load(
      fileName: '.env',
      isOptional: true,
    );

    debugPrint(
      "🚀 STEP 2: Environment Variables Loaded",
    );

    // ── FIREBASE ──────────────────────
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions
              .currentPlatform,
    );

    debugPrint(
      "🚀 STEP 3: Firebase Initialized",
    );

    // ── AUTH WARMUP ───────────────────
    await Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
    );

    FirebaseAuth.instance.currentUser;

    debugPrint(
      "🚀 STEP 3.2: Firebase Auth Warmed Up",
    );

    // ── SYSTEM UI ─────────────────────
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent,

        statusBarIconBrightness:
            Brightness.dark,

        systemNavigationBarColor:
            Colors.white,

        systemNavigationBarIconBrightness:
            Brightness.dark,
      ),
    );

    // ── ORIENTATION ───────────────────
    await SystemChrome
        .setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint(
      "🚀 STEP 4: Orientation Locked",
    );

    // ── APP START ─────────────────────
    runApp(
      const ProviderScope(
        child: BiteoApp(),
      ),
    );

    debugPrint(
      "🚀 STEP 5: ProviderScope Launched!",
    );

  } catch (e, stack) {

    debugPrint(
      "❌ CRITICAL BOOT ERROR: $e",
    );

    debugPrint(
      stack.toString(),
    );
  }
}

// =============================================================
// APP
// =============================================================

class BiteoApp
    extends ConsumerStatefulWidget {

  const BiteoApp({
    super.key,
  });

  @override
  ConsumerState<BiteoApp>
      createState() =>
          _BiteoAppState();
}

class _BiteoAppState
    extends ConsumerState<BiteoApp> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {

      // 🔥 LOCATION INIT
      ref
          .read(
            locationNotifierProvider
                .notifier,
          )
          .initialise(ref);

      // 🔥 WAIT FOR LOGIN
      await Future.delayed(
        const Duration(seconds: 2),
      );

      // 🔥 INIT FCM
      await initFCM();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    final router =
        ref.watch(
      appRouterProvider,
    );

    return MaterialApp.router(

      title: 'Biteo',

      debugShowCheckedModeBanner:
          false,

      theme:
          AppTheme.lightTheme,

      routerConfig: router,

      builder:
          (context, child) {

        return MediaQuery(

          data:
              MediaQuery.of(
                context,
              ).copyWith(
                textScaler:
                    const TextScaler.linear(
                  1.0,
                ),
              ),

          child: child!,
        );
      },
    );
  }
}