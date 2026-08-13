// ============================================================
// lib/core/router/app_router.dart
// FINAL VERSION (5B + 5C + 6 MERGED SAFELY)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/address/presentation/screens/map_location_screen.dart';
import '../../features/address/presentation/screens/location_search_screen.dart';
import '../../features/address/presentation/screens/saved_addresses_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/domain/entities/vendor_entity.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/vendor/presentation/screens/vendor_detail_screen.dart';

// 5C
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/offers_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';

// 🔥 6 NEW
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/checkout/presentation/providers/checkout_state.dart';
import '../../features/checkout/presentation/screens/coupon_selection_screen.dart';

// ============================================================
// ROUTE CONSTANTS
// ============================================================

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const vendorDetail = '/vendor/:vendorId';
  static const mapLocation = '/map-location';
  static const search = '/search';
  static const editProfile = '/edit-profile';
  static const savedAddresses = '/saved-addresses';
  static const locationSearch = '/location-search';

  // 5C
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const offers = '/offers';
  static const support = '/support';

  // 🔥 6 NEW
  static const checkout = '/checkout';
  static const couponSelection =
    '/coupon-selection';
  static const orderSuccess = '/order-success';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const otp = 'otp';
  static const profileSetup = 'profile-setup';
  static const home = 'home';
  static const vendorDetail = 'vendor-detail';
  static const mapLocation = 'map-location';
  static const search = 'search';
  static const editProfile = 'edit-profile';
  static const locationSearch = 'location-search';

  // 5C
  static const profile = 'profile';
  static const notifications = 'notifications';
  static const offers = 'offers';
  static const support = 'support';

  // 🔥 6 NEW
  static const checkout = 'checkout';
  static const orderSuccess = 'order-success';
}

// ============================================================
// ROUTER NOTIFIER
// ============================================================

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription _sub;

  _RouterNotifier(this._ref) {
    _sub = _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authNotifierProvider);
    final loc = state.matchedLocation;

    if (auth is AuthInitial) return null;

    if (loc == AppRoutes.splash) {
      if (auth is AuthAuthenticated) return AppRoutes.home;
      if (auth is AuthNewUser) return AppRoutes.profileSetup;
      if (auth is AuthCodeSent) return AppRoutes.otp;
      return AppRoutes.login;
    }

    if (auth is AuthLoading || auth is AuthOtpVerifying) return null;

    if (auth is AuthCodeSent) {
      return loc == AppRoutes.otp ? null : AppRoutes.otp;
    }

    if (auth is AuthNewUser) {
      return loc == AppRoutes.profileSetup
          ? null
          : AppRoutes.profileSetup;
    }

    if (auth is AuthAuthenticated) {
      const restricted = [
        AppRoutes.login,
        AppRoutes.otp,
        AppRoutes.profileSetup,
        AppRoutes.splash,
      ];
      return restricted.contains(loc) ? AppRoutes.home : null;
    }

    const protected = [
      AppRoutes.home,
      AppRoutes.mapLocation,
      AppRoutes.search,
      AppRoutes.locationSearch,
      AppRoutes.profile,
      AppRoutes.notifications,
      AppRoutes.editProfile,
      AppRoutes.support,

      // 🔥 6 PROTECTED
      AppRoutes.checkout,
      AppRoutes.orderSuccess,
    ];

    if (protected.contains(loc) || loc.startsWith('/vendor')) {
      return AppRoutes.login;
    }

    return null;
  }
}

// ============================================================
// ROUTER PROVIDER
// ============================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    debugLogDiagnostics: true,
    routes: [
      // SPLASH
      GoRoute(
        path: AppRoutes.splash,
        name: RouteNames.splash,
        builder: (_, __) => const _SplashScreen(),
      ),

      // LOGIN
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        pageBuilder: (_, state) => _fadeTransition(
          state: state,
          child: const PhoneLoginScreen(),
        ),
      ),

      // OTP
      GoRoute(
        path: AppRoutes.otp,
        name: RouteNames.otp,
        pageBuilder: (_, state) => _slideTransition(
          state: state,
          child: Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authNotifierProvider);
              return OtpVerificationScreen(
                verificationId:
                    auth is AuthCodeSent ? auth.verificationId : '',
                phoneNumber:
                    auth is AuthCodeSent ? auth.phoneNumber : '',
              );
            },
          ),
        ),
      ),

      // PROFILE SETUP
      GoRoute(
        path: AppRoutes.profileSetup,
        name: RouteNames.profileSetup,
        pageBuilder: (_, state) => _slideTransition(
          state: state,
          child: Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authNotifierProvider);
              return ProfileSetupScreen(
                uid: auth is AuthNewUser ? auth.uid : '',
                phoneNumber:
                    auth is AuthNewUser ? auth.phoneNumber : '',
              );
            },
          ),
        ),
      ),

      // HOME
      GoRoute(
        path: AppRoutes.home,
        name: RouteNames.home,
        builder: (_, __) => const HomeScreen(),
      ),

      // SEARCH
      GoRoute(
        path: AppRoutes.search,
        name: RouteNames.search,
        builder: (_, __) => const SearchScreen(),
      ),

      // LOCATION SEARCH
      GoRoute(
        path: AppRoutes.locationSearch,
        name: RouteNames.locationSearch,
        pageBuilder: (_, state) => _slideTransition(
          state: state,
          child: const LocationSearchScreen(),
        ),
      ),

      // VENDOR
      GoRoute(
        path: AppRoutes.vendorDetail,
        name: RouteNames.vendorDetail,
        pageBuilder: (_, state) {
          final vendor = state.extra as VendorEntity;
          return _slideTransition(
            state: state,
            child: VendorDetailScreen(vendor: vendor),
          );
        },
      ),

      // MAP
      GoRoute(
        path: AppRoutes.mapLocation,
        name: RouteNames.mapLocation,
        pageBuilder: (_, state) => _slideTransition(
          state: state,
          child: const MapLocationScreen(),
        ),
      ),

      // PROFILE
      GoRoute(
        path: AppRoutes.profile,
        name: RouteNames.profile,
        builder: (_, __) => const ProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.notifications,
        name: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      GoRoute(
  path: AppRoutes.offers,
  name: RouteNames.offers,
  builder: (_, __) => const OffersScreen(),
),

GoRoute(
  path: AppRoutes.support,
  name: RouteNames.support,
  builder: (_, __) => const SupportScreen(),
),

      GoRoute(
        path: AppRoutes.editProfile,
        name: RouteNames.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.savedAddresses,
        builder: (_, __) => const SavedAddressesScreen(),
      ),

      // 🔥 CHECKOUT
GoRoute(
  path: AppRoutes.checkout,
  name: RouteNames.checkout,
  pageBuilder: (_, state) => _slideTransition(
    state: state,
    child: const CheckoutScreen(),
  ),
),

// 🔥 COUPON SELECTION
GoRoute(
  path: AppRoutes.couponSelection,
  builder: (context, state) {

    final data =
        state.extra as Map<String, dynamic>;

    return CouponSelectionScreen(
      cartTotalPaise:
          data['cartTotalPaise'],
    );
  },
),

// 🔥 ORDER SUCCESS
GoRoute(
  path: AppRoutes.orderSuccess,
  name: RouteNames.orderSuccess,
  pageBuilder: (_, state) {

    final successData =
        state.extra as CheckoutSuccess;

    return _fadeTransition(
      state: state,
      child: OrderSuccessScreen(
        successData: successData,
      ),
    );
  },
),
    ],
  );
});

// ============================================================
// SPLASH
// ============================================================

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFF6B6B),
      body: Center(
        child: Text(
          'biteo',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TRANSITIONS
// ============================================================

CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slideTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero);
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}