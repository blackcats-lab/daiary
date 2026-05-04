/// AdMob 統合サービス。
///
/// Phase 2（Sprint 4）で `google_mobile_ads` を初期化し、
/// バナー / インタースティシャル / リワード広告を扱う。
class AdMobService {
  const AdMobService._();

  /// SDK 初期化。`main.dart` から呼び出す想定。
  static Future<void> initialize() async {
    // TODO(phase2): MobileAds.instance.initialize();
  }

  /// プレミアムユーザーには広告を表示しないため、表示前に判定する。
  static bool shouldShowAd({required bool isPremium}) => !isPremium;
}
