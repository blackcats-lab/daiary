import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/photo_list_repository.dart';

part 'photo_tags_provider.g.dart';

/// 検索 UI のタグ候補（頻度順）。autoDispose で検索を抜けたら破棄する。
@riverpod
Future<List<String>> photoTags(Ref ref) {
  return ref.read(photoListRepositoryProvider).fetchTags();
}
