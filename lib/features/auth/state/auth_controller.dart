import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../data/google_auth_service.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

/// Holds the current session: `null` while checking/logged out, an [AppUser]
/// once authenticated. Screens watch this to decide what to render/navigate to.
final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(email, password));
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).register(email, password));
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final idToken = await ref.read(googleAuthServiceProvider).signInAndGetIdToken();
      return ref.read(authRepositoryProvider).loginWithGoogleIdToken(idToken);
    });
  }

  Future<void> logout() async {
    await ref.read(googleAuthServiceProvider).signOut();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
