// ============================================================
// lib/features/checkout/data/services/razorpay_service.dart
// Wraps the razorpay_flutter SDK.
//
// WHY a wrapper class:
// 1. Allows mocking in tests.
// 2. Centralizes callback setup — no scattered listeners.
// 3. Ensures proper dispose() is called to free SDK resources.
// ============================================================
import 'package:logger/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  // Callbacks set by CheckoutNotifier.
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onExternalWallet;

  bool _initialized = false;

  // ── Lifecycle ─────────────────────────────────────────────
  void initialize() {
    if (_initialized) return;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initialized = true;
    _log.i('[Razorpay] Initialized.');
  }

  void dispose() {
    if (!_initialized) return;
    _razorpay.clear();
    onSuccess = null;
    onFailure = null;
    onExternalWallet = null;
    _initialized = false;
    _log.i('[Razorpay] Disposed.');
  }

  // ── Open checkout ─────────────────────────────────────────
  // `options` must include: key, order_id, amount, currency, name.
  void open(Map<String, dynamic> options) {
    if (!_initialized) {
      _log.e('[Razorpay] Cannot open — not initialized.');
      return;
    }
    _log.i('[Razorpay] Opening checkout for order: ${options['order_id']}');
    _razorpay.open(options);
  }

  // ── Private event handlers ────────────────────────────────
  void _handleSuccess(PaymentSuccessResponse response) {
    _log.i('[Razorpay] Payment SUCCESS. PaymentID: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handleError(PaymentFailureResponse response) {
    _log.w(
      '[Razorpay] Payment FAILED. '
      'Code: ${response.code}, Msg: ${response.message}',
    );
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _log.i('[Razorpay] External wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }
}