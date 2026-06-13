import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/add_photos_result.dart';
import '../../domain/entities/album_summary.dart';
import '../../domain/entities/album_with_photos.dart';

part 'album_repository.g.dart';

class AlbumRepository {
  AlbumRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const _bucket = 'photos';

  /// GET /albums。一覧取得。
  Future<List<AlbumSummary>> fetchList() async {
    final res = await _invoke('albums', method: HttpMethod.get);
    if (res.status != 200) {
      throw AlbumFailure(
        'service_failed',
        'アルバム一覧の取得に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('service_failed', '想定外のレスポンス形式です');
    }
    final raw =
        (data['albums'] as List? ?? const []).cast<Map<String, dynamic>>();
    return raw.map(albumSummaryFromJson).toList(growable: false);
  }

  /// POST /albums。作成成功時はサマリーを返す。
  Future<AlbumSummary> create({
    required String name,
    String? coverPhotoId,
    bool isPublic = false,
  }) async {
    final res = await _invoke(
      'albums',
      method: HttpMethod.post,
      body: {
        'name': name,
        if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
        'is_public': isPublic,
      },
    );
    if (res.status != 201) {
      throw AlbumFailure(
        'create_failed',
        'アルバムの作成に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('create_failed', '想定外のレスポンス形式です');
    }
    final album = (data['album'] as Map?)?.cast<String, dynamic>();
    if (album == null) {
      throw AlbumFailure('create_failed', '想定外のレスポンス形式です');
    }
    return albumSummaryFromJson(album);
  }

  /// GET /albums/:id。アルバム詳細 + 含まれる写真一覧。
  Future<AlbumWithPhotos> fetchDetail(String albumId) async {
    final res = await _invoke('albums/$albumId', method: HttpMethod.get);
    if (res.status == 404) {
      throw AlbumFailure('not_found', 'アルバムが見つかりません');
    }
    if (res.status != 200) {
      throw AlbumFailure(
        'service_failed',
        'アルバム詳細の取得に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('service_failed', '想定外のレスポンス形式です');
    }
    return albumWithPhotosFromJson(data.cast<String, dynamic>());
  }

  /// PATCH /albums/:id。name / cover_photo_id / is_public / share_token を更新。
  Future<AlbumSummary> update(
    String albumId, {
    String? name,
    String? coverPhotoId,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
      if (isPublic != null) 'is_public': isPublic,
    };
    if (body.isEmpty) {
      throw AlbumFailure('update_failed', '更新項目が指定されていません');
    }
    final res = await _invoke(
      'albums/$albumId',
      method: HttpMethod.patch,
      body: body,
    );
    if (res.status == 404) {
      throw AlbumFailure('not_found', 'アルバムが見つかりません');
    }
    if (res.status != 200) {
      throw AlbumFailure(
        'update_failed',
        'アルバムの更新に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('update_failed', '想定外のレスポンス形式です');
    }
    final album = (data['album'] as Map?)?.cast<String, dynamic>();
    if (album == null) {
      throw AlbumFailure('update_failed', '想定外のレスポンス形式です');
    }
    // PATCH レスポンスには cover_thumbnail_path / photo_count が無いので 0 / null で補完
    return albumSummaryFromJson({
      ...album,
      if (album['cover_thumbnail_path'] == null) 'cover_thumbnail_path': null,
      if (album['photo_count'] == null) 'photo_count': 0,
    });
  }

  /// DELETE /albums/:id。物理削除（album_photos は CASCADE）。
  Future<void> delete(String albumId) async {
    final res = await _invoke('albums/$albumId', method: HttpMethod.delete);
    if (res.status == 404) {
      throw AlbumFailure('not_found', 'アルバムが見つかりません');
    }
    if (res.status != 200) {
      throw AlbumFailure(
        'delete_failed',
        'アルバムの削除に失敗しました (status=${res.status})',
      );
    }
  }

  /// POST /albums/:id/photos。写真の一括追加。
  /// 弾かれた photo_id は AddPhotosResult.skipped に reason 付きで返される。
  Future<AddPhotosResult> addPhotos(
    String albumId,
    List<String> photoIds,
  ) async {
    final res = await _invoke(
      'albums/$albumId/photos',
      method: HttpMethod.post,
      body: {'photo_ids': photoIds},
    );
    if (res.status == 404) {
      throw AlbumFailure('not_found', 'アルバムが見つかりません');
    }
    if (res.status != 200) {
      throw AlbumFailure(
        'add_photos_failed',
        '写真の追加に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('add_photos_failed', '想定外のレスポンス形式です');
    }
    return addPhotosResultFromJson(data.cast<String, dynamic>());
  }

  /// DELETE /albums/:id/photos。写真の一括削除（写真自体は残る）。
  Future<List<String>> removePhotos(
    String albumId,
    List<String> photoIds,
  ) async {
    final res = await _invoke(
      'albums/$albumId/photos',
      method: HttpMethod.delete,
      body: {'photo_ids': photoIds},
    );
    if (res.status == 404) {
      throw AlbumFailure('not_found', 'アルバムが見つかりません');
    }
    if (res.status != 200) {
      throw AlbumFailure(
        'remove_photos_failed',
        '写真の削除に失敗しました (status=${res.status})',
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw AlbumFailure('remove_photos_failed', '想定外のレスポンス形式です');
    }
    return ((data['removed'] as List?) ?? const []).cast<String>();
  }

  /// カバー画像の Signed URL（1 時間有効）。
  /// 失敗しても一覧描画は続けたいので例外を投げず null を返す。
  Future<String?> createSignedUrl(String? path) async {
    if (path == null) return null;
    try {
      return await _client.storage.from(_bucket).createSignedUrl(path, 3600);
    } on StorageException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<FunctionResponse> _invoke(
    String name, {
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await SupabaseService.invokeFunction(
        name,
        method: method,
        body: body,
        queryParameters: queryParameters,
      );
    } on FunctionException catch (e) {
      throw _mapException(e);
    } on SocketException catch (e) {
      throw AlbumFailure(
        'network',
        'ネットワークに接続できませんでした: ${e.message}',
      );
    } catch (e) {
      throw AlbumFailure(
        'unknown',
        'API 呼び出し中に予期せぬエラーが発生しました: $e',
      );
    }
  }

  AlbumFailure _mapException(FunctionException e) {
    Map<String, dynamic>? body;
    final details = e.details;
    if (details is Map) {
      body = details.cast<String, dynamic>();
    } else if (details is String && details.isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) body = decoded.cast<String, dynamic>();
      } catch (_) {
        // JSON 以外の文字列は無視
      }
    }

    final msg = (body?['message'] as String?) ?? 'API 呼び出しに失敗しました';
    switch (e.status) {
      case 401:
        return AlbumFailure('unauthenticated', 'ログインが必要です');
      case 404:
        return AlbumFailure('not_found', msg);
      default:
        return AlbumFailure('service_failed', '$msg (${e.status})');
    }
  }
}

@Riverpod(keepAlive: false)
AlbumRepository albumRepository(Ref ref) => AlbumRepository();
