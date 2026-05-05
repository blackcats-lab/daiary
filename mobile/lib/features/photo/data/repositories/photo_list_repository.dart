import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/photo_list_item.dart';
import '../../domain/entities/photo_list_page.dart';

part 'photo_list_repository.g.dart';

class PhotoListRepository {
  PhotoListRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const _bucket = 'photos';

  /// photos Edge Function の GET /photos を叩いて 1 ページ分取得する。
  Future<PhotoListPage> fetchPage({DateTime? before, int limit = 30}) async {
    final query = <String, dynamic>{
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };

    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos',
        method: HttpMethod.get,
        queryParameters: query,
      );
    } on FunctionException catch (e) {
      throw PhotoFailure('list_failed', '一覧の取得に失敗しました (${e.status})');
    } on SocketException catch (e) {
      throw PhotoFailure('network', 'ネットワークに接続できませんでした: ${e.message}');
    } catch (e) {
      throw PhotoFailure('unknown', '一覧の取得中に予期せぬエラーが発生しました: $e');
    }

    if (response.status != 200) {
      throw PhotoFailure(
        'list_failed',
        '一覧の取得に失敗しました (status=${response.status})',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw PhotoFailure('list_failed', '想定外のレスポンス形式です');
    }
    final rawItems =
        (data['photos'] as List? ?? const []).cast<Map<String, dynamic>>();
    final items = rawItems.map(photoListItemFromJson).toList();
    final nextBeforeRaw = data['next_before'] as String?;
    final nextBefore =
        nextBeforeRaw == null ? null : DateTime.parse(nextBeforeRaw);
    return PhotoListPage(items: items, nextBefore: nextBefore);
  }

  /// Storage オブジェクトの Signed URL を発行する（1 時間有効）。
  /// 失敗しても一覧描画は続けたいので例外を投げず null を返す。
  Future<String?> createThumbnailSignedUrl(String path) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 3600);
    } on StorageException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

@Riverpod(keepAlive: false)
PhotoListRepository photoListRepository(Ref ref) {
  return PhotoListRepository();
}
