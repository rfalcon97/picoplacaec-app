/// Backend base URL for local development.
///
/// - Android emulator: `10.0.2.2` is the emulator's alias for your PC's
///   `localhost`, so this default works out of the box against
///   `pnpm run start:dev` on port 3000.
/// - Physical Android device (USB or same Wi-Fi): replace with your PC's LAN
///   IP, e.g. `http://192.168.1.50:3000`.
/// - iOS simulator: `localhost` works directly, unlike Android.
///
/// Once the backend is deployed, swap this for the Render URL.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
