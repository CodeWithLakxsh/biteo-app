// ============================================================
// lib/features/checkout/presentation/providers/checkout_providers.dart
// ============================================================
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../../../features/cart/presentation/providers/cart_state.dart';
import '../../../../features/cart/presentation/providers/cart_providers.dart';
import '../../data/repositories/checkout_repository_impl.dart';
import '../../data/services/razorpay_service.dart';
import 'checkout_state.dart';

// ── Repository ────────────────────────────────────────────────
final checkoutRepositoryProvider = Provider<CheckoutRepositoryImpl>(
  (_) => CheckoutRepositoryImpl(),
);

// ── Razorpay Service ──────────────────────────────────────────
final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService();
  service.initialize();

  ref.onDispose(service.dispose);

  return service;
});

// ── Checkout Notifier ─────────────────────────────────────────
class CheckoutNotifier extends Notifier<CheckoutState> {
  String? _vendorId;

  // 🔥 FIX: SAFE STORAGE (DO NOT REMOVE)
  String? _paymentVendorId;

  String? _restaurantNote;
bool _noCutlery = false;

bool _useBiteoPoints = true;

int _usableDiscountPaise = 0;
int _finalPayablePaise = 0;

  String _currentMode = 'pickup';

  final Logger _log = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  RazorpayService get _razorpay =>
      ref.read(razorpayServiceProvider);

  CheckoutRepositoryImpl get _repo =>
      ref.read(checkoutRepositoryProvider);

  @override
  CheckoutState build() {
    _razorpay.onSuccess =
        _handlePaymentSuccess;

    _razorpay.onFailure =
        _handlePaymentFailure;

    _razorpay.onExternalWallet =
        _handleExternalWallet;

    ref.onDispose(() {
      _razorpay.onSuccess = null;
      _razorpay.onFailure = null;
      _razorpay.onExternalWallet = null;
    });

    return const CheckoutIdle();
  }

  // ── placeOrder: the main entry point ──────────────────────
Future<void> placeOrder({
  required String mode,
  String? restaurantNote,
  required bool noCutlery,
  required bool useBiteoPoints,
}) async {
    _currentMode = mode;
    _restaurantNote = restaurantNote;
_noCutlery = noCutlery;

    final cartState =
        ref.read(cartNotifierProvider);

    if (cartState is! CartLoaded) {
      state = const CheckoutFailure(
        message:
            'Your cart is empty or has expired.',
      );

      return;
    }

    final cart = cartState.cart;
    final cleanedNote =
    restaurantNote?.trim() ?? '';

// 🔥 BITEO POINTS LOGIC
final biteoPoints =
    ref.read(biteoPointsProvider);

final maxDiscountPaise =
    biteoPoints * 100;

final usableDiscountPaise =
    useBiteoPoints
        ? (
            maxDiscountPaise > cart.totalPaise
                ? cart.totalPaise
                : maxDiscountPaise
          )
        : 0;

final finalPayablePaise =
    cart.totalPaise -
        usableDiscountPaise;
        _useBiteoPoints = useBiteoPoints;

_usableDiscountPaise =
    usableDiscountPaise;

_finalPayablePaise =
    finalPayablePaise;

    _vendorId = cart.vendorId;

    // 🔥 FIX: STORE SAFE COPY BEFORE PAYMENT
    _paymentVendorId =
        cart.vendorId;

    if (cart.isExpired) {
      state = const CheckoutFailure(
        message:
            'Your cart has expired. Please add items again.',
      );

      return;
    }

    if (cart.isLocked) {
      state = const CheckoutFailure(
        message:
            'Payment is already being processed.',
      );

      return;
    }

    state = const CheckoutCreatingOrder();

    final String razorpayOrderId;

    try {
final result =
    await _repo.createRazorpayOrder(
  mode: _currentMode,
  restaurantNote: cleanedNote,
  noCutlery: noCutlery,
);

      razorpayOrderId =
          result['id'] as String;
    } catch (e) {
      _log.e(
        '[Checkout] createRazorpayOrder failed',
        error: e,
      );

      state = CheckoutFailure(
        message: e
            .toString()
            .replaceAll(
              'Exception: ',
              '',
            ),
      );

      return;
    }

    final authState =
        ref.read(authNotifierProvider);

    final String userPhone;
    final String userName;
    final String userEmail;

    if (authState is AuthAuthenticated) {
      userPhone = authState.user.phone
              .startsWith('+91')
          ? authState.user.phone.substring(3)
          : authState.user.phone;

      userName =
          authState.user.fullName ?? '';

      userEmail =
          authState.user.email ?? '';
    } else {
      userPhone = '';
      userName = '';
      userEmail = '';
    }

    state = CheckoutAwaitingPayment(
      razorpayOrderId:
          razorpayOrderId,

      // 🔥 FINAL PAYABLE
      amountPaise:
          finalPayablePaise,
    );

    final options =
        <String, dynamic>{
      'key':
          dotenv.env[
                  'RAZORPAY_KEY_ID'] ??
              '',

      'order_id':
          razorpayOrderId,

      // 🔥 FINAL PAYABLE
      'amount':
          finalPayablePaise,

      'currency': 'INR',

      'name': 'Biteo',

      'description':
          'Pickup order from ${cart.vendorName}',

      'image':
          'https://biteo.in/logo.png',

      'prefill': {
        'contact': userPhone,

        if (userName.isNotEmpty)
          'name': userName,

        if (userEmail.isNotEmpty)
          'email': userEmail,
      },

      'readonly': {
        'contact': true,
      },

      'send_sms_hash': true,

      'remember_customer': false,

      'theme': {
        'color': '#FF6B6B',
      },

      'modal': {
        'backdropclose': false,
        'escape': false,
        'confirm_close': true,
        'animation': true,
      },
    };

    _razorpay.open(options);

    _log.i(
      '[Checkout] Razorpay checkout opened for order $razorpayOrderId',
    );
  }

  // ── Razorpay Callbacks ────────────────────────────────────

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    _log.i(
      '[Checkout] Payment success. '
      'PaymentID: ${response.paymentId}, '
      'OrderID: ${response.orderId}',
    );

    if (response.paymentId == null ||
        response.orderId == null ||
        response.signature == null) {
      state = const CheckoutFailure(
        message:
            'Payment completed but details are missing. Contact support.',
      );

      return;
    }

    state = const CheckoutVerifying();

    try {
      // 🔥 FINAL RELIABLE VENDOR ID
      String? vendorId =
          _paymentVendorId ??
              _vendorId;

      // fallback from cart if needed
      if (vendorId == null ||
          vendorId.isEmpty) {
        final cartState =
            ref.read(
          cartNotifierProvider,
        );

        if (cartState
            is CartLoaded) {
          vendorId =
              cartState
                  .cart
                  .vendorId;
        }
      }

      // 🚨 FINAL SAFETY CHECK
      if (vendorId == null ||
          vendorId.isEmpty) {
        state =
            const CheckoutFailure(
          message:
              'Vendor ID missing. Please restart order.',
        );

        return;
      }

      // 🔍 DEBUG
      print(
        "🔥 FINAL VENDOR ID USED: $vendorId",
      );

      // ✅ FINAL API CALL
final result =
    await _repo
        .verifyPaymentAndCreateOrder(
  razorpayOrderId:
      response.orderId!,

  razorpayPaymentId:
      response.paymentId!,

  razorpaySignature:
      response.signature!,

  mode: _currentMode,

  vendorId:
      vendorId,

  restaurantNote:
      _restaurantNote ?? '',

biteoPointsUsed:
    _useBiteoPoints
        ? _usableDiscountPaise ~/ 100
        : 0,

finalPaidPaise:
    _finalPayablePaise,

noCutlery:
    _noCutlery,
);

      _log.i(
        '[Checkout] Order created: ${result['orderId']}',
      );

      state = CheckoutSuccess(
        orderId:
            result['orderId']
                as String,

        otpCode:
            result['otpCode']
                    as String? ??
                '',

        vendorName:
            result['vendorName']
                    as String? ??
                '',

        totalPaise:
            (result['totalPaise']
                        as num?)
                    ?.toInt() ??
                0,

        estimatedReadyMinutes:
            (result[
                        'estimatedReadyMinutes']
                    as num?)
                ?.toInt() ??
            15,

        pickupMode:
            result['pickupMode']
                    as String? ??
                'pickup',
      );
    } catch (e) {
      _log.e(
        '[Checkout] verifyPaymentAndCreateOrder failed',
        error: e,
      );

      state = CheckoutFailure(
        message:
            'Payment received (ID: ${response.paymentId}) but order creation failed. Please contact support.',
      );
    }
  }

  void _handlePaymentFailure(
    PaymentFailureResponse response,
  ) {
    _log.w(
      '[Checkout] Payment failed. '
      'Code: ${response.code}, Msg: ${response.message}',
    );

    state = CheckoutFailure(
      message:
          response.message ??
              'Payment failed',

      isPaymentFailed: true,
    );
  }

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {
    _log.i(
      '[Checkout] External wallet: ${response.walletName}',
    );

    state = CheckoutFailure(
      message:
          'Please complete payment in ${response.walletName ?? 'wallet'} and return.',

      isPaymentFailed: true,
    );
  }

  void reset() {
    state = const CheckoutIdle();
  }
}

// ── Provider ─────────────────────────────────────────
final checkoutNotifierProvider =
    NotifierProvider<
        CheckoutNotifier,
        CheckoutState>(
  CheckoutNotifier.new,
);