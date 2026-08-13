import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // 🔥 FIX: Move profile data init here (NOT in build)
    Future.microtask(() {
      final profile = ref.read(userProfileProvider).value;

      if (profile != null && !_initialized) {
        nameController.text = profile.name ?? '';
        emailController.text = profile.email ?? '';
        dobController.text = profile.dob ?? '';
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),

      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => const Center(
          child: Text("Failed to load profile"),
        ),
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── NAME ──
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                  ),
                ),

                const SizedBox(height: 16),

                // ── EMAIL ──
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                  ),
                ),

                const SizedBox(height: 16),

                // ── DOB ──
                TextField(
                  controller: dobController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      dobController.text =
                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    }
                  },
                ),

                const SizedBox(height: 30),

                // ── SAVE BUTTON ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();

                            setState(() => _isSaving = true);

                            try {
                              await ref
                                  .read(updateProfileProvider.notifier)
                                  .updateProfile(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    dob: dobController.text.trim(),
                                  );

                              // 🔥 CRITICAL FIX
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Failed to update profile"),
                                ),
                              );
                            }

                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}