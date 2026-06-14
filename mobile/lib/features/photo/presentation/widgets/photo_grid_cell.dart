import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/photo_list_view.dart';

/// 写真グリッドの 1 セル。サムネイル + AI タグオーバーレイ。
/// ホーム一覧・検索結果で共用する。
class PhotoGridCell extends StatelessWidget {
  const PhotoGridCell({super.key, required this.view});

  final PhotoListItemView view;

  @override
  Widget build(BuildContext context) {
    final url = view.signedThumbnailUrl;
    final tags = view.item.aiTags;
    return GestureDetector(
      onTap: () => context.push('/photo/${view.item.id}'),
      child: ColoredBox(
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              const Center(child: Icon(Icons.broken_image, color: Colors.grey))
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            if (tags.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TagOverlay(tags: tags),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagOverlay extends StatelessWidget {
  const _TagOverlay({required this.tags});

  final List<String> tags;

  /// グリッド 3 列で 1 セル ~118px の制約から先頭 2 件 + +N バッジに留める。
  static const _kVisibleTagCount = 2;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(_kVisibleTagCount).toList();
    final extra = tags.length - visible.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x8C000000)],
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 0,
        children: [
          for (final t in visible)
            Text(
              t.startsWith('#') ? t : '#$t',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          if (extra > 0)
            Text(
              '+$extra',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
        ],
      ),
    );
  }
}
