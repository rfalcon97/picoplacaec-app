import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

/// Wraps google_sign_in's v7 singleton API.
///
/// [serverClientId] must be the WEB OAuth client id from Google Cloud
/// Console (not the Android one) — that's what makes the resulting ID
/// token's audience match what our backend expects, see
/// backend/src/auth/auth.service.ts#loginWithGoogle and GOOGLE_CLIENT_ID
/// in backend/.env.
class GoogleAuthService {
  static const String serverClientId =
      '1063429698843-4ovbhofg3g1m3oafebkilk6h2v5snv9v.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  /// Returns the Google ID token to send to our backend.
  Future<String> signInAndGetIdToken() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Este dispositivo no soporta el inicio de sesión con Google');
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google no devolvió un token válido');
    }
    return idToken;
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in via Google, or not configured yet — fine to ignore.
    }
  }
}
