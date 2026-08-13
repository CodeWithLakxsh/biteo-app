// =============================================================
// lib/features/auth/presentation/screens/phone_login_screen.dart
// The first screen users see. Split-screen: coral brand header
// + white form bottom sheet. Premium "Gourmet" look.
// =============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/biteo_button.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {

  // 1️⃣ VARIABLES
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // 2️⃣ initState
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  } // ✅ FIXED: Ye bracket missing thi jo yahan add kar di gayi hai!

  // 3️⃣ dispose
  @override
  void dispose() {
    _phoneController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // 4️⃣ functions
  void _handleSendOtp() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authNotifierProvider.notifier)
        .sendOtp(_phoneController.text.trim());
  }

Future<void> _openTerms() async {
  final uri = Uri.parse(
    'https://policy.biteo.in',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}

Future<void> _openPrivacy() async {
  final uri = Uri.parse(
    'https://policy.biteo.in',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}

  // 5️⃣ build method
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthCodeSent) {
        context.pushNamed(RouteNames.otp);
      } else if (next is AuthAuthenticated) {
        context.goNamed(RouteNames.home);
      } else if (next is AuthNewUser) {
        context.pushNamed(RouteNames.profileSetup);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.electricCoral,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Coral background with subtle pattern ──────────
          Positioned.fill(
            child: CustomPaint(painter: _CoralPatternPainter()),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top brand section ────────────────────────
                SizedBox(
                  height: size.height * 0.34,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo mark
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lunch_dining_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Wordmark
                        Text(
                          'biteo',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Premium food. Half the price.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.82),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── White bottom sheet card ──────────────────
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            28,
                            36,
                            28,
                            MediaQuery.of(context).viewInsets.bottom + 32,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Drag handle ───────────────
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 28),
                                    decoration: BoxDecoration(
                                      color: AppColors.dividerGrey,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),

                                Text(
                                  'Sign in to Biteo',
                                  style: AppTextStyles.headlineLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Discover 50%+ off daily. Pickup from top cafés near you.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: 32),

                                // ── Phone input label ─────────
                                Text(
                                  'Mobile Number',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.deepCharcoal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ── Phone field ───────────────
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleSendOtp(),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                    color: AppColors.deepCharcoal,
                                    fontFamily: 'Poppins',
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '98765 43210',
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      letterSpacing: 2,
                                      color: AppColors.softGrey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    // +91 prefix block
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(right: 0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundGrey,
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          left: Radius.circular(12),
                                        ),
                                        border: const Border(
                                          right: BorderSide(
                                            color: AppColors.dividerGrey,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🇮🇳',
                                              style: TextStyle(fontSize: 18)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '+91',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.deepCharcoal,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your mobile number';
                                    }
                                    if (v.trim().length != 10) {
                                      return 'Enter a valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // ── CTA ───────────────────────
                                BiteoButton(
                                  label: 'Send OTP',
                                  onPressed: isLoading ? null : _handleSendOtp,
                                  isLoading: isLoading,
                                ),

                                const SizedBox(height: 24),

                                // ── T&C ───────────────────────
                               Center(
  child: Text.rich(
    TextSpan(
      text:
          'By continuing, you agree to our ',
      style: TextStyle(
        fontSize: 11,
        color: AppColors.mutedGrey,
        fontFamily: 'Poppins',
      ),
      children: [

        TextSpan(
          text: 'Terms of Service',
          style: const TextStyle(
            color:
                AppColors.electricCoral,
            fontWeight:
                FontWeight.w600,
            decoration:
                TextDecoration.underline,
            decorationColor:
                AppColors.electricCoral,
          ),

          recognizer:
              TapGestureRecognizer()
                ..onTap = _openTerms,
        ),

        const TextSpan(
          text: ' & ',
        ),

        TextSpan(
          text: 'Privacy Policy',
          style: const TextStyle(
            color:
                AppColors.electricCoral,
            fontWeight:
                FontWeight.w600,
            decoration:
                TextDecoration.underline,
            decorationColor:
                AppColors.electricCoral,
          ),

          recognizer:
              TapGestureRecognizer()
                ..onTap = _openPrivacy,
        ),
      ],
    ),

    textAlign: TextAlign.center,
  ),
),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} // ✅ THIS closes _PhoneLoginScreenState properly

/// Draws subtle overlapping circles
class _CoralPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.05), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.25), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.32), 50, paint);

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.08), 160, strokePaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.28), 100, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}