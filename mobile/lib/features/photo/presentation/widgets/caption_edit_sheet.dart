import 'package:flutter/material.dart';

/// caption 編集用のモーダルボトムシート。
/// 保存時は新しい caption（空文字なら消去扱い）を返す。キャンセル時は null。
class CaptionEditSheet extends StatefulWidget {
  const CaptionEditSheet({super.key, this.initial});

  final String? initial;

  static const int maxLength = 500;

  /// 表示して結果を返す。保存されたら caption（消去は空文字）、キャンセルは null。
  static Future<String?> show(BuildContext context, {String? initial}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CaptionEditSheet(initial: initial),
    );
  }

  @override
  State<CaptionEditSheet> createState() => _CaptionEditSheetState();
}

class _CaptionEditSheetState extends State<CaptionEditSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          Text(
            'キャプションを編集',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            maxLength: CaptionEditSheet.maxLength,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '写真に添える言葉…',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, _controller.text.trim()),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
