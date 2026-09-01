import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/cities/screens/city_schedule_screen.dart';
import '../features/notifications/screens/notification_history_screen.dart';
import '../features/vehicles/screens/add_vehicle_screen.dart';
import '../features/vehicles/screens/home_screen.dart';
import 'splash_screen.dart';

/// Recreated whenever auth state changes, so `redirect` always sees the
/// latest session — simple and fine at this app's scale.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/add-vehicle', builder: (context, state) => const AddVehicleScreen()),
      GoRoute(
        path: '/edit-vehicle',
        builder: (context, state) => AddVehicleScreen(editArgs: state.extra as VehicleEditArgs),
      ),
      GoRoute(
        path: '/city-schedule/:slug',
        builder: (context, state) => CityScheduleScreen(citySlug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/notification-history', builder: (context, state) => const NotificationHistoryScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(email: state.extra as String),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final atSplash = loc == '/';
      final atAuthScreen = loc == '/login' || loc == '/register' || loc == '/forgot-password' || loc == '/reset-password';

      if (authState.isLoading) {
        return atSplash ? null : '/';
      }

      final isLoggedIn = authState.valueOrNull != null;

      if (!isLoggedIn) {
        return atAuthScreen ? null : '/login';
      }

      if (atAuthScreen || atSplash) {
        return '/home';
      }
      return null;
    },
  );
});
