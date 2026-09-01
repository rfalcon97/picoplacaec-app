/// AdMob configuration.
///
/// [bannerAdUnitId] and [interstitialAdUnitId] currently point to Google's
/// OFFICIAL PUBLIC TEST ad units — they always serve a sample ad, are safe to
/// ship in debug builds, and never earn real money. Before publishing:
///
/// 1. Create a free AdMob account at https://admob.google.com and register
///    this app to get a real App ID and ad unit IDs.
/// 2. Replace the App ID in android/app/src/main/AndroidManifest.xml.
/// 3. Set [useTestAds] to false and fill in the `_prod*` ids below.
class AdConfig {
  static const bool useTestAds = true;

  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static const String _prodBannerAdUnitId = 'REPLACE_WITH_REAL_BANNER_AD_UNIT_ID';
  static const String _prodInterstitialAdUnitId = 'REPLACE_WITH_REAL_INTERSTITIAL_AD_UNIT_ID';

  static String get bannerAdUnitId => useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;

  static String get interstitialAdUnitId => useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
}
