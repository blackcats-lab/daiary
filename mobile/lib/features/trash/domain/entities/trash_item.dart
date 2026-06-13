import 'package:freezed_annotation/freezed_annotation.dart';

part 'trash_item.freezed.dart';

/// ゴミ箱内（論理削除済み）の写真。残日数表示のため deletedAt を保持する。
@freezed
abstract class TrashItem with _$TrashItem {
  const factory TrashItem({
    required String id,
    required String storagePath,
    String? thumbnailPath,
    required DateTime deletedAt,
  }) = _TrashItem;

  const TrashItem._();

  /// 物理削除（30 日後）までの残日数。負にはならない。
  int remainingDays({DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(deletedAt).inDays;
    final remaining = 30 - elapsed;
    return remaining < 0 ? 0 : remaining;
  }
}

TrashItem trashItemFromJson(Map<String, dynamic> json) => TrashItem(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
    );
