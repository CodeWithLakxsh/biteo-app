// =============================================================
// lib/features/auth/presentation/screens/otp_verification_screen.dart
// 6-digit OTP entry. A single hidden TextField captures input;
// 6 styled visual boxes display each digit. 
// Principal Architect: Laksh/Yogesh (Biteo CTO Office)
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/biteo_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Resend countdown timer.
  static const int _resendSeconds = 60;
  int _remainingSeconds = _resendSeconds;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _startTimer();

    // 🔥 INFINIX BULLETPROOF FOCUS LOCK
    // Fixing the "keyboard comes but no typing" issue.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          // Forcefully request focus and trigger keyboard system-wide
          FocusScope.of(context).requestFocus(_focusNode);
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    });

    _otpController.addListener(_onOtpChanged);
  }

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _remainingSeconds = _resendSeconds;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  void _onOtpChanged() {
    setState(() {}); // Rebuild boxes when input changes.
    if (_otpController.text.length == 6) {
      // Auto-submit when all 6 digits are entered.
      _focusNode.unfocus();
      _handleVerify();
    }
  }

  void _handleVerify() {
    if (_otpController.text.length != 6) return;
    
    // UI Guard: prevent clicking while already loading
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthLoading || authState is AuthOtpVerifying) return;

    HapticFeedback.mediumImpact();
    ref.read(authNotifierProvider.notifier).verifyOtp(
          verificationId: widget.verificationId,
          otp: _otpController.text,
        );
  }

  void _handleResend() {
    if (!_canResend) return;
    
    HapticFeedback.lightImpact();
    _otpController.clear();
    
    // FIXED: Ensure we pass the clean number. 
    final cleanPhone = widget.phoneNumber.replaceAll('+91', '').trim();
    
    ref.read(authNotifierProvider.notifier).sendOtp(cleanPhone);
    
    _startPhoneResendFeedback(); 
    _startTimer(); 
  }

  void _startPhoneResendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending a new code...'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.deepCharcoal,
      ),
    );
  }

  // Formats +919876543210 → +91 98765 43210 for display.
  String get _formattedPhone {
    final raw = widget.phoneNumber;
    if (raw.startsWith('+91') && raw.length == 13) {
      final digits = raw.substring(3);
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return raw;
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthNewUser) {
        context.pushReplacementNamed(
          RouteNames.profileSetup,
          extra: {'uid': next.uid, 'phone': next.phoneNumber},
        );
      } else if (next is AuthAuthenticated) {
        context.goNamed(RouteNames.home);
      } else if (next is AuthError) {
        _otpController.clear();
        
        String errorMsg = next.message;
        if (errorMsg.contains('too-many-requests')) {
           errorMsg = "Too many attempts. Please wait a few minutes.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
        ref.read(authNotifierProvider.notifier).resetError();
        _focusNode.requestFocus();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading || authState is AuthOtpVerifying;
    final otp = _otpController.text;

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.dividerGrey),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // 🔥 MANUAL RE-FOCUS: If user clicks anywhere, keyboard must re-attach
          HapticFeedback.lightImpact();
          _focusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Verify your number', style: AppTextStyles.displayMedium),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium,
                    text: 'We sent a 6-digit code to\n',
                    children: [
                      TextSpan(
                        text: _formattedPhone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepCharcoal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                Stack(
                  children: [
                    Positioned(
                      left: -300,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
                          autofocus: true,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          showCursor: false,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        final char = i < otp.length ? otp[i] : '';
                        final isActive = i == otp.length && !isLoading;
                        return _OtpBox(
                          char: char,
                          isActive: isActive,
                          isFilled: char.isNotEmpty,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                BiteoButton(
                  label: 'Verify & Continue',
                  onPressed: (isLoading || otp.length < 6)
                      ? null
                      : _handleVerify,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: _canResend
                      ? GestureDetector(
                          onTap: _handleResend,
                          child: RichText(
                            text: TextSpan(
                              text: 'Didn\'t receive it? ',
                              style: AppTextStyles.bodyMedium,
                              children: const [
                                TextSpan(
                                  text: 'Resend OTP',
                                  style: TextStyle(
                                    color: AppColors.electricCoral,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.electricCoral,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            text: 'Resend code in ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: '$_remainingSeconds s',
                                style: const TextStyle(
                                  color: AppColors.electricCoral,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String char;
  final bool isActive;
  final bool isFilled;

  const _OtpBox({
    required this.char,
    required this.isActive,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.coralSurface
            : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.electricCoral
              : isFilled
                  ? AppColors.coralLight
                  : AppColors.dividerGrey,
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.electricCoral.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: char.isNotEmpty
            ? Text(
                char,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepCharcoal,
                  fontFamily: 'Poppins',
                ),
              )
            : isActive
                ? _BlinkingCursor()
                : const SizedBox.shrink(),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 24,
        color: AppColors.electricCoral,
      ),
    );
  }
}