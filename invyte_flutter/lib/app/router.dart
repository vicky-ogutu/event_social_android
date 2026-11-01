import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/bookings/presentation/screens/booking_detail_screen.dart';
import '../features/bookings/presentation/screens/booking_request_screen.dart';
import '../features/bookings/presentation/screens/checkout_screen.dart';
import '../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../features/bookings/presentation/screens/vendor_bookings_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/event_form_screen.dart';
import '../features/events/presentation/screens/my_events_screen.dart';
import '../features/home/presentation/screens/consumer_home_screen.dart';
import '../features/home/presentation/screens/discover_screen.dart';
import '../features/home/presentation/screens/vendor_dashboard_screen.dart';
import '../features/livestream/presentation/screens/go_live_screen.dart';
import '../features/livestream/presentation/screens/live_stream_screen.dart';
import '../features/messaging/presentation/screens/chat_screen.dart';
import '../features/messaging/presentation/screens/inbox_screen.dart';
import '../features/profile/presentation/screens/change_password_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/social/presentation/screens/create_post_screen.dart';
import '../features/social/presentation/screens/event_chat_screen.dart';
import '../features/social/presentation/screens/feed_screen.dart';
import '../features/vendors/presentation/screens/business_profile_screen.dart';
import '../features/vendors/presentation/screens/manage_services_screen.dart';
import '../features/vendors/presentation/screens/portfolio_screen.dart';
import '../features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'main_shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmailPath = '/verify-email';
  static const forgotPasswordPath = '/forgot-password';
  static const resetPasswordPath = '/reset-password';

  static String verifyEmail(String email) => Uri(path: verifyEmailPath, queryParameters: {'email': email}).toString();
  static String forgotPassword({String? email}) =>
      Uri(path: forgotPasswordPath, queryParameters: {'email': ?email}).toString();
  static String resetPassword(String email) =>
      Uri(path: resetPasswordPath, queryParameters: {'email': email}).toString();

  // Customer tabs
  static const home = '/home';
  static const discover = '/discover';
  static const feed = '/feed';
  static const inbox = '/inbox';
  static const profile = '/profile';

  // Vendor tabs (everything under /vendor is vendor-only)
  static const vendorHome = '/vendor';
  static const vendorBookings = '/vendor/bookings';
  static const vendorFeed = '/vendor/feed';
  static const vendorInbox = '/vendor/inbox';
  static const vendorProfile = '/vendor/profile';
  static const vendorBusiness = '/vendor/business';
  static const vendorServices = '/vendor/services';
  static const vendorPortfolio = '/vendor/portfolio';

  static const newEvent = '/events/new';
  static const myEvents = '/my-events';
  static const myBookings = '/bookings';
  static const newPost = '/posts/new';
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/password';
  static const goLive = '/go-live';

  static String event(int id) => '/events/$id';
  static String editEvent(int id) => '/events/$id/edit';
  static String eventChat(int id) => '/events/$id/chat';
  static String live(int id) => '/events/$id/live';
  static String vendor(int id) => '/vendors/$id';
  static String book(int vendorId, int serviceId) => '/vendors/$vendorId/book/$serviceId';
  static String booking(int id) => '/bookings/$id';
  static String checkout(int bookingId) => '/bookings/$bookingId/checkout';
  static String chat(int userId, {required String name, String? avatar}) => Uri(
        path: '/chat/$userId',
        queryParameters: {'name': name, 'avatar': ?avatar},
      ).toString();
  static String discoverWith({String? category}) =>
      Uri(path: discover, queryParameters: {'category': ?category}).toString();

  static String homeFor({required bool vendor}) => vendor ? vendorHome : home;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod → GoRouter so redirects re-run when auth changes.
  final refresh = ValueNotifier(0);
  ref.listen(
    authControllerProvider.select((s) => (s.user?.id, s.user?.isVendor)),
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == Routes.splash) return null;

      final user = ref.read(authControllerProvider).user;
      const publicRoutes = {
        Routes.onboarding,
        Routes.login,
        Routes.register,
        Routes.verifyEmailPath,
        Routes.forgotPasswordPath,
        Routes.resetPasswordPath,
      };
      final isPublic = publicRoutes.contains(location);

      if (user == null) return isPublic ? null : Routes.login;

      final home = Routes.homeFor(vendor: user.isVendor);
      if (isPublic) return home;

      final isVendorArea = location == Routes.vendorHome || location.startsWith('${Routes.vendorHome}/');
      const customerTabs = {Routes.home, Routes.discover, Routes.feed, Routes.inbox, Routes.profile};
      if (user.isVendor && customerTabs.contains(location)) return home;
      if (!user.isVendor && isVendorArea) return home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyEmailPath,
        builder: (_, s) => VerifyEmailScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: Routes.forgotPasswordPath,
        builder: (_, s) => ForgotPasswordScreen(email: s.uri.queryParameters['email']),
      ),
      GoRoute(
        path: Routes.resetPasswordPath,
        builder: (_, s) => ResetPasswordScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),

      // ---- Customer app ----
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell, vendor: false),
        branches: [
          _branch(Routes.home, (_) => const ConsumerHomeScreen()),
          _branch(Routes.discover, (s) => DiscoverScreen(initialCategory: s.uri.queryParameters['category'])),
          _branch(Routes.feed, (_) => const FeedScreen()),
          _branch(Routes.inbox, (_) => const InboxScreen()),
          _branch(Routes.profile, (_) => const ProfileScreen()),
        ],
      ),

      // ---- Vendor app ----
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell, vendor: true),
        branches: [
          _branch(Routes.vendorHome, (_) => const VendorDashboardScreen()),
          _branch(Routes.vendorBookings, (_) => const VendorBookingsScreen()),
          _branch(Routes.vendorFeed, (_) => const FeedScreen()),
          _branch(Routes.vendorInbox, (_) => const InboxScreen()),
          _branch(Routes.vendorProfile, (_) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: Routes.vendorBusiness, builder: (_, _) => const BusinessProfileScreen()),
      GoRoute(path: Routes.vendorServices, builder: (_, _) => const ManageServicesScreen()),
      GoRoute(path: Routes.vendorPortfolio, builder: (_, _) => const PortfolioScreen()),

      // ---- Shared full-screen routes ----
      GoRoute(path: Routes.newEvent, builder: (_, _) => const EventFormScreen()),
      GoRoute(path: Routes.myEvents, builder: (_, _) => const MyEventsScreen()),
      GoRoute(
        path: '/events/:id',
        builder: (_, s) => EventDetailScreen(eventId: _id(s)),
        routes: [
          GoRoute(path: 'edit', builder: (_, s) => EventFormScreen(eventId: _id(s))),
          GoRoute(path: 'chat', builder: (_, s) => EventChatScreen(eventId: _id(s))),
          GoRoute(path: 'live', builder: (_, s) => LiveStreamScreen(eventId: _id(s))),
        ],
      ),
      GoRoute(
        path: '/vendors/:id',
        builder: (_, s) => VendorDetailScreen(vendorId: _id(s)),
        routes: [
          GoRoute(
            path: 'book/:serviceId',
            builder: (_, s) => BookingRequestScreen(
              vendorId: _id(s),
              serviceId: int.tryParse(s.pathParameters['serviceId'] ?? '') ?? 0,
            ),
          ),
        ],
      ),
      GoRoute(path: Routes.myBookings, builder: (_, _) => const MyBookingsScreen()),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, s) => BookingDetailScreen(bookingId: _id(s)),
        routes: [
          GoRoute(path: 'checkout', builder: (_, s) => CheckoutScreen(bookingId: _id(s))),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatScreen(
          userId: _id(s),
          name: s.uri.queryParameters['name'] ?? 'Chat',
          avatar: s.uri.queryParameters['avatar'],
        ),
      ),
      GoRoute(
        path: Routes.newPost,
        builder: (_, s) => CreatePostScreen(eventId: int.tryParse(s.uri.queryParameters['eventId'] ?? '')),
      ),
      GoRoute(path: Routes.editProfile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: Routes.goLive, builder: (_, _) => const GoLiveScreen()),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget Function(GoRouterState state) builder) => StatefulShellBranch(
      routes: [GoRoute(path: path, pageBuilder: (_, s) => NoTransitionPage(child: builder(s)))],
    );

int _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
