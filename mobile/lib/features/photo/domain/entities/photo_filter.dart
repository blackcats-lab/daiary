import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_filter.freezed.dart';

/// 写真一覧の検索・絞り込み条件。
///
/// [tag] は AI タグの完全一致（保存値そのまま）、[favoriteOnly] はお気に入りのみ。
/// 両方未指定（[isEmpty]）のときは検索モード OFF とみなしフィードを表示する。
@freezed
abstract class PhotoFilter with _$PhotoFilter {
  const factory PhotoFilter({
    String? tag,
    @Default(false) bool favoriteOnly,
  }) = _PhotoFilter;

  const PhotoFilter._();

  bool get isEmpty => (tag == null || tag!.isEmpty) && !favoriteOnly;
  bool get isActive => !isEmpty;
}
