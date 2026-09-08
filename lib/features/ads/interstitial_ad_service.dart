import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ad_config.dart';

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  final service = InterstitialAdService();
  service.preload();
  ref.onDispose(service.dispose);
  return service;
});

/// Preloads one interstitial at a time and shows it on demand (e.g. after
/// adding a vehicle) — never automatically, and never blocking the core
/// "can I circulate today" flow.
class InterstitialAdService {
  InterstitialAd? _ad;

  void preload() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  /// Shows the preloaded ad if one is ready, and completes once it's been
  /// dismissed (or immediately if no ad was available) — so callers that
  /// need to gate an action behind the ad, not just fire-and-forget it, can
  /// `await` this instead of the previous void return.
  Future<void> showIfReady() {
    final ad = _ad;
    if (ad == null) return Future.value();

    _ad = null;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
  }
}
