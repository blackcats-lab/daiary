import 'package:freezed_annotation/freezed_annotation.dart';

import 'photo_list_item.dart';

part 'photo_list_page.freezed.dart';

@freezed
abstract class PhotoListPage with _$PhotoListPage {
  const factory PhotoListPage({
    required List<PhotoListItem> items,
    DateTime? nextBefore,
  }) = _PhotoListPage;
}
