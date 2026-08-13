// =============================================================
// lib/features/auth/presentation/screens/profile_setup_screen.dart
// Shown once for new users. Collects name + email + food preference.
// After saving, shows the Hype Welcome Modal before navigating home.
// =============================================================

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
import '../widgets/hype_welcome_modal.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String uid;
  final String phoneNumber; // FIXED: Renamed from phone to phoneNumber

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.phoneNumber, // FIXED: Renamed from phone to phoneNumber
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocus  = FocusNode();
  final _emailFocus = FocusNode();
  
  // Default preference set to 'Veg'
  String _selectedPreference = 'Veg'; 

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _handleSaveProfile() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    
    // Updated to include foodPreference and phoneNumber
    ref.read(authNotifierProvider.notifier).saveProfile(
          uid:            widget.uid,
          phone:          widget.phoneNumber, // FIXED: Use widget.phoneNumber
          fullName:       _nameController.text.trim(),
          foodPreference: _selectedPreference,
          email:          _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        );
  }

  Future<void> _showWelcomeModal(String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const HypeWelcomeModal(),
    );
    await ref.read(authNotifierProvider.notifier).markWelcomeModalSeen(uid);
    if (mounted) context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthStateAuthenticated) {
        _showWelcomeModal(next.user.uid);
      } else if (next is AuthStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    final isLoading = ref.watch(authNotifierProvider) is AuthStateLoading;

    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            28,
            40,
            28,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProgressDot(active: true),
                    const SizedBox(width: 6),
                    _ProgressDot(active: true),
                    const SizedBox(width: 6),
                    _ProgressDot(active: false),
                  ],
                ),
                const SizedBox(height: 28),
                Text('One last\nstep 👋', style: AppTextStyles.displayMedium),
                const SizedBox(height: 10),
                Text(
                  'Tell us your name and preference to get started.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 40),

                // ── Name field ─────────────────────────────
                const _FieldLabel(label: 'Your Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.deepCharcoal,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Your Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.mutedGrey),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Your name is required';
                    if (v.trim().length < 2) return 'Please enter your full name';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Email field ────────────────────────────
                Row(
                  children: [
                    const _FieldLabel(label: 'Email Address'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Optional',
                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.deepCharcoal,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'yourmail@mail.com',
                    helperText: 'For order receipts and updates',
                    helperStyle: TextStyle(fontSize: 11, color: AppColors.mutedGrey),
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.mutedGrey),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Food Preference ──────────────────
                const _FieldLabel(label: 'Food Preference'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PreferenceCard(
                      label: 'Veg',
                      icon: Icons.eco_rounded,
                      color: Colors.green,
                      isSelected: _selectedPreference == 'Veg',
                      onTap: () => setState(() => _selectedPreference = 'Veg'),
                    ),
                    const SizedBox(width: 12),
                    _PreferenceCard(
                      label: 'Non-Veg',
                      icon: Icons.restaurant_rounded,
                      color: Colors.redAccent,
                      isSelected: _selectedPreference == 'Non-Veg',
                      onTap: () => setState(() => _selectedPreference = 'Non-Veg'),
                    ),
                    const SizedBox(width: 12),
                    _PreferenceCard(
                      label: 'Both',
                      icon: Icons.fastfood_rounded,
                      color: AppColors.electricCoral,
                      isSelected: _selectedPreference == 'Both',
                      onTap: () => setState(() => _selectedPreference = 'Both'),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // ── CTA ────────────────────────────────────
                BiteoButton(
                  label: 'Complete My Profile',
                  onPressed: isLoading ? null : _handleSaveProfile,
                  isLoading: isLoading,
                  prefixIcon: Icons.check_circle_outline_rounded,
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '🔒  Your data is private and secure',
                    style: AppTextStyles.bodySmall,
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

// ── Supporting Widgets ──────────────────────────────────────

class _PreferenceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PreferenceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.dividerGrey,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.mutedGrey, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.deepCharcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.deepCharcoal,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final bool active;
  const _ProgressDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.electricCoral : AppColors.dividerGrey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}