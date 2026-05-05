import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/entities/ai_generate_result.dart';

part 'ai_generate_repository.g.dart';

class AiGenerateRepository {
  AiGenerateRepository();

  /// Edge Function は 2MB 制限。base64 で 33% 増 + JSON overhead を考慮し
  /// 1.5MB を超える画像は事前に弾く。
  static const int _maxImageBytes = 1500000;

  /// 画像から hashtag を生成する。
  Future<AiGenerateResult> generateHashtags(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (bytes.length > _maxImageBytes) {
      throw AiGenerateFailure('image_too_large', '画像が大きすぎます');
    }

    final encoded = base64Encode(bytes);
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'ai-generate',
        body: {
          'image': encoded,
          'mimeType': mimeType,
          'taskType': 'hashtag',
          'options': {
            'language': 'ja',
            'count': 10,
          },
        },
      );
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } on SocketException catch (e) {
      throw AiGenerateFailure(
        'network',
        'ネットワークに接続できませんでした: ${e.message}',
      );
    } catch (e) {
      throw AiGenerateFailure('unknown', '予期せぬエラーが発生しました: $e');
    }

    if (response.status != 200) {
      throw AiGenerateFailure(
        'service_failed',
        'AI 生成に失敗しました (status=${response.status})',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw AiGenerateFailure('service_failed', '想定外のレスポンス形式です');
    }
    final result = (data['result'] as Map?)?.cast<String, dynamic>();
    final rawHashtags = result?['hashtags'] as List?;
    if (rawHashtags == null) {
      throw AiGenerateFailure('service_failed', 'ハッシュタグが取得できませんでした');
    }
    final hashtags = rawHashtags.cast<String>();

    return AiGenerateResult(
      hashtags: hashtags,
      model: (data['model'] as String?) ?? 'unknown',
      remaining: (data['remaining'] as num?)?.toInt() ?? 0,
      limit: (data['limit'] as num?)?.toInt() ?? 0,
    );
  }

  /// 生成済み hashtag を photos.ai_tags に保存する。
  Future<void> updatePhotoTags(String photoId, List<String> hashtags) async {
    FunctionResponse response;
    try {
      response = await SupabaseService.invokeFunction(
        'photos/$photoId',
        method: HttpMethod.patch,
        body: {'ai_tags': hashtags},
      );
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } on SocketException catch (e) {
      throw AiGenerateFailure(
        'network',
        'ネットワークに接続できませんでした: ${e.message}',
      );
    } catch (e) {
      throw AiGenerateFailure(
        'service_failed',
        'タグの保存中に予期せぬエラーが発生しました: $e',
      );
    }

    if (response.status != 200) {
      throw AiGenerateFailure(
        'service_failed',
        'タグの保存に失敗しました (status=${response.status})',
      );
    }
  }

  AiGenerateFailure _mapFunctionException(FunctionException e) {
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

    switch (e.status) {
      case 401:
        return AiGenerateFailure('unauthenticated', 'ログインが必要です');
      case 413:
        return AiGenerateFailure('image_too_large', '画像が大きすぎます');
      case 429:
        return AiGenerateFailure(
          'rate_limited',
          (body?['message'] as String?) ?? '本日の利用上限に達しました',
          remaining: (body?['remaining'] as num?)?.toInt(),
          limit: (body?['limit'] as num?)?.toInt(),
        );
      default:
        return AiGenerateFailure(
          'service_failed',
          (body?['message'] as String?) ?? 'AI 生成に失敗しました',
        );
    }
  }
}

@Riverpod(keepAlive: false)
AiGenerateRepository aiGenerateRepository(Ref ref) => AiGenerateRepository();
