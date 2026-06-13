import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/trash_item.dart';

part 'trash_repository.g.dart';

/// ゴミ箱（論理削除済み写真）の取得・復元・完全削除。
/// photo_list_repository とは分離し、ゴミ箱固有のエンドポイントのみ扱う。
class TrashRepository {
  TrashRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const _bucket = 'photos';

  /// ゴミ箱一覧（GET /photos?deleted=true）。deleted_at 降順。
  Future<List<TrashItem>> fetchTrash() async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos',
        method: HttpMethod.get,
        queryParameters: {'deleted': 'true', 'limit': '100'},
      );
    } on FunctionException catch (e) {
      throw PhotoFailure('list_failed', 'ゴミ箱の取得に失敗しました (${e.status})');
    } catch (e) {
      throw PhotoFailure('unknown', 'ゴミ箱の取得中にエラーが発生しました: $e');
    }

    if (response.status != 200) {
      throw PhotoFailure('list_failed', 'ゴミ箱の取得に失敗しました');
    }
    final data = response.data;
    if (data is! Map) throw PhotoFailure('list_failed', '想定外のレスポンス形式です');
    return (data['photos'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(trashItemFromJson)
        .toList();
  }

  /// 復元（POST /photos/:id/restore）。
  Future<void> restore(String photoId) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId/restore',
        method: HttpMethod.post,
      );
    } on FunctionException catch (e) {
      if (e.status == 404) throw PhotoFailure('not_found', '写真が見つかりません');
      throw PhotoFailure('update_failed', '復元に失敗しました (${e.status})');
    } catch (e) {
      throw PhotoFailure('unknown', '復元中にエラーが発生しました: $e');
    }
    if (response.status != 200) {
      throw PhotoFailure('update_failed', '復元に失敗しました');
    }
  }

  /// 完全削除（DELETE /photos/:id?permanent=true）。Storage 実ファイルも消える。
  Future<void> permanentDelete(String photoId) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.delete,
        queryParameters: {'permanent': 'true'},
      );
    } on FunctionException catch (e) {
      if (e.status == 404) throw PhotoFailure('not_found', '写真が見つかりません');
      throw PhotoFailure('delete_failed', '完全削除に失敗しました (${e.status})');
    } catch (e) {
      throw PhotoFailure('unknown', '完全削除中にエラーが発生しました: $e');
    }
    if (response.status != 200) {
      throw PhotoFailure('delete_failed', '完全削除に失敗しました');
    }
  }

  /// サムネイルの Signed URL（1 時間有効）。失敗時は null。
  Future<String?> createThumbnailSignedUrl(String path) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }
}

@riverpod
TrashRepository trashRepository(Ref ref) => TrashRepository();
