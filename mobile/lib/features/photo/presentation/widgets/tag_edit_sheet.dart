import 'package:flutter/material.dart';

import '../../../../core/utils/tag_normalizer.dart';

/// ハッシュタグ編集用のモーダルボトムシート。
/// 既存タグを InputChip で削除、テキスト欄から追加。保存時は正規化済みリストを返す。
class TagEditSheet extends StatefulWidget {
  const TagEditSheet({super.key, required this.initial});

  final List<String> initial;

  /// 表示して結果を返す。保存されたら正規化済みタグリスト、キャンセルは null。
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initial,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TagEditSheet(initial: initial),
    );
  }

  @override
  State<TagEditSheet> createState() => _TagEditSheetState();
}

class _TagEditSheetState extends State<TagEditSheet> {
  late List<String> _tags = TagNormalizer.normalizeList(widget.initial);
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text;
    final error = TagNormalizer.validateForAdd(raw, _tags);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _tags = [..._tags, TagNormalizer.normalizeOne(raw)!];
      _controller.clear();
      _error = null;
    });
  }

  void _remove(String tag) {
    setState(() => _tags = _tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'タグを編集',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${_tags.length} / ${TagNormalizer.maxCount}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tags.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('タグがありません', style: TextStyle(color: Colors.grey)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in _tags)
                  InputChip(
                    label: Text(t),
                    onDeleted: () => _remove(t),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'タグを追加',
                    errorText: _error,
                    prefixText: '#',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton.filledTonal(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, _tags),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
