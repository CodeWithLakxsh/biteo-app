// ============================================================
// lib/features/checkout/data/repositories/checkout_repository_impl.dart
// FINAL WORKING VERSION
// (WITH BITEO POINTS + VENDOR ID + RESTAURANT NOTES)
// ============================================================

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CheckoutRepositoryImpl {
  final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  // ✅ Firebase URLs
  static const String createOrderUrl =
      "https://createorder-73wvldn2ia-uc.a.run.app/";

  static const String verifyPaymentUrl =
      "https://verifypayment-73wvldn2ia-uc.a.run.app/";

  // ── Create Razorpay Order ─────────────────────────────────
  Future<Map<String, dynamic>> createRazorpayOrder({
    required String mode,

    // 🔥 NEW
    String restaurantNote = '',
    required bool noCutlery,
  }) async {
    try {
      _log.i(
        '[Checkout] Calling createOrder (HTTP)...',
      );

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'User not logged in',
        );
      }

      final url =
          Uri.parse(createOrderUrl);

      final body = {
        'userId': user.uid,

        'mode': mode,

        // 🔥 NEW
        'restaurant_note':
            restaurantNote,

        'no_cutlery':
            noCutlery,
      };

      // 🔍 DEBUG
      _log.d(
        'CREATE ORDER BODY: ${jsonEncode(body)}',
      );

      final response = await http.post(
        url,

        headers: {
          "Content-Type":
              "application/json",
        },

        body: jsonEncode(body),
      );

      _log.d(
        "STATUS: ${response.statusCode}",
      );

      _log.d(
        "BODY: ${response.body}",
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ??
              'Failed to create order',
        );
      }

      if (data['order'] == null) {
        throw Exception(
          'Invalid order response from server',
        );
      }

      _log.i(
        '[Checkout] Razorpay order created: ${data['order']['id']}',
      );

      return data['order'];
    } catch (e) {
      _log.e(
        '[Checkout] Error in createRazorpayOrder',
        error: e,
      );

      throw Exception(
        'Payment service unavailable. Please try again.',
      );
    }
  }

  // ── Verify Payment + Create Firestore Order ───────────────
  Future<Map<String, dynamic>>
      verifyPaymentAndCreateOrder({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String mode,
    required String vendorId,

    // 🔥 BITEO POINTS
    int biteoPointsUsed = 0,
    int finalPaidPaise = 0,

    // 🔥 NEW
    String restaurantNote = '',
    required bool noCutlery,
  }) async {
    try {
      _log.i(
        '[Checkout] Verifying payment (HTTP)...',
      );

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'User not logged in',
        );
      }

      final url =
          Uri.parse(verifyPaymentUrl);

      final body = {
        "razorpay_order_id":
            razorpayOrderId,

        "razorpay_payment_id":
            razorpayPaymentId,

        "razorpay_signature":
            razorpaySignature,

        "userId": user.uid,

        "mode": mode,

        // 🔥 CRITICAL
        "vendor_id": vendorId,

        // 🔥 BITEO POINTS
        "biteo_points_used":
            biteoPointsUsed,

        "final_paid_paise":
            finalPaidPaise,

        // 🔥 NEW
        "restaurant_note":
            restaurantNote,

        "no_cutlery":
            noCutlery,
      };

      // 🔍 DEBUG
      _log.d(
        'VERIFY BODY: ${jsonEncode(body)}',
      );

      final response = await http.post(
        url,

        headers: {
          "Content-Type":
              "application/json",
        },

        body: jsonEncode(body),
      );

      _log.d(
        "STATUS: ${response.statusCode}",
      );

      _log.d(
        "BODY: ${response.body}",
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ??
              'Payment verification failed',
        );
      }

      if (data['orderId'] == null) {
        throw Exception(
          'Order creation failed (no orderId)',
        );
      }

      _log.i(
        '[Checkout] Order created: ${data['orderId']}',
      );

      return data;
    } catch (e) {
      _log.e(
        '[Checkout] Error in verifyPayment',
        error: e,
      );

      throw Exception(
        'Order creation failed. Please contact support.',
      );
    }
  }
}