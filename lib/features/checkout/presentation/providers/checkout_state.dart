// ============================================================
// lib/features/checkout/presentation/providers/checkout_state.dart
// Sealed state for the full payment flow.
// ============================================================

sealed class CheckoutState {
  const CheckoutState();
}

/// No checkout in progress.
final class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

/// Cloud Function is creating the Razorpay order (step 1).
final class CheckoutCreatingOrder extends CheckoutState {
  const CheckoutCreatingOrder();
}

/// Razorpay checkout sheet is open. Waiting for user to pay.
final class CheckoutAwaitingPayment extends CheckoutState {
  final String razorpayOrderId;
  final int amountPaise;

  const CheckoutAwaitingPayment({
    required this.razorpayOrderId,
    required this.amountPaise,
  });
}

/// Payment succeeded. Cloud Function is verifying + creating order.
final class CheckoutVerifying extends CheckoutState {
  const CheckoutVerifying();
}

/// Order created successfully. Navigate to success screen.
final class CheckoutSuccess extends CheckoutState {
  final String orderId;
  final String otpCode;
  final String vendorName;
  final int totalPaise;
  final int estimatedReadyMinutes;
  final String pickupMode;

  const CheckoutSuccess({
    required this.orderId,
    required this.otpCode,
    required this.vendorName,
    required this.totalPaise,
    required this.estimatedReadyMinutes,
    required this.pickupMode,
  });

  String get totalDisplay =>
      '₹${(totalPaise / 100).toStringAsFixed(0)}';
}

/// Something went wrong. [isPaymentFailed] = true means Razorpay
/// rejected it. false = backend verification/order creation failed.
final class CheckoutFailure extends CheckoutState {
  final String message;
  final bool isPaymentFailed;

  const CheckoutFailure({
    required this.message,
    this.isPaymentFailed = false,
  });
}