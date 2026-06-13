import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/photo_detail.dart';
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

  /// photos Edge Function の GET /photos/:id を叩いて 1 件分取得する。
  Future<PhotoDetail> fetchDetail(String photoId) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.get,
      );
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw PhotoFailure('not_found', '写真が見つかりません');
      }
      throw PhotoFailure('detail_failed', '詳細の取得に失敗しました (${e.status})');
    } on SocketException catch (e) {
      throw PhotoFailure('network', 'ネットワークに接続できませんでした: ${e.message}');
    } catch (e) {
      throw PhotoFailure('unknown', '詳細の取得中に予期せぬエラーが発生しました: $e');
    }

    if (response.status != 200) {
      throw PhotoFailure(
        'detail_failed',
        '詳細の取得に失敗しました (status=${response.status})',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw PhotoFailure('detail_failed', '想定外のレスポンス形式です');
    }
    final photo = (data['photo'] as Map?)?.cast<String, dynamic>();
    if (photo == null) {
      throw PhotoFailure('not_found', '写真が見つかりません');
    }
    return photoDetailFromJson(photo);
  }

  /// お気に入りトグル。サーバから返る最新値を返す。
  Future<bool> toggleFavorite(String photoId, bool next) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.patch,
        body: {'is_favorite': next},
      );
    } on FunctionException catch (e) {
      throw PhotoFailure('update_failed', 'お気に入りの更新に失敗しました (${e.status})');
    } on SocketException catch (e) {
      throw PhotoFailure('network', 'ネットワークに接続できませんでした: ${e.message}');
    }

    if (response.status != 200) {
      throw PhotoFailure(
        'update_failed',
        'お気に入りの更新に失敗しました (status=${response.status})',
      );
    }

    final data = response.data;
    if (data is Map) {
      final photo = (data['photo'] as Map?)?.cast<String, dynamic>();
      final fav = photo?['is_favorite'] as bool?;
      if (fav != null) return fav;
    }
    return next;
  }

  /// 論理削除。
  Future<void> softDelete(String photoId) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.delete,
      );
    } on FunctionException catch (e) {
      if (e.status == 404) {
        throw PhotoFailure('not_found', '写真が見つかりません');
      }
      throw PhotoFailure('delete_failed', '削除に失敗しました (${e.status})');
    } on SocketException catch (e) {
      throw PhotoFailure('network', 'ネットワークに接続できませんでした: ${e.message}');
    }

    if (response.status != 200) {
      throw PhotoFailure(
        'delete_failed',
        '削除に失敗しました (status=${response.status})',
      );
    }
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

  /// 原寸画像の Signed URL（1 時間有効）。
  Future<String?> createOriginalSignedUrl(String path) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 3600);
    } on StorageException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 原寸画像を一時ディレクトリにダウンロードして File を返す。
  /// share_plus への File 渡しと、PR-F の AI 再生成入口で使う。
  Future<File> downloadOriginalToTmp(String storagePath) async {
    final bytes = await _client.storage.from(_bucket).download(storagePath);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/dl_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

@Riverpod(keepAlive: false)
PhotoListRepository photoListRepository(Ref ref) {
  return PhotoListRepository();
}
