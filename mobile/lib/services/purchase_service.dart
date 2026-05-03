/// RevenueCat 統合サービス（雛形）。
///
/// Phase 2（Sprint 4）で `purchases_flutter` を初期化し、
/// プラン取得・購入・復元・サブスク状態同期を扱う。
class PurchaseService {
  const PurchaseService._();

  /// SDK 初期化。`main.dart` から呼び出す想定。
  static Future<void> initialize({required String apiKey}) async {
    // TODO(phase2): await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  /// 購入処理（雛形）
  static Future<void> purchase(String productIdentifier) async {
    // TODO(phase2): await Purchases.purchaseProduct(productIdentifier);
  }

  /// 過去の購入を復元
  static Future<void> restore() async {
    // TODO(phase2): await Purchases.restorePurchases();
  }
}
