/// キャプション生成のスタイル選択肢。
/// 要件定義 F-AI-002 の文章スタイル一覧と対応する。
enum CaptionStyle {
  poetic,
  business,
  casual,
  news,
  humor;

  /// ai-generate Edge Function の `options.style` に渡す値。
  /// docs/prompt-design.md と整合する語彙を使う。
  String get apiValue => switch (this) {
        CaptionStyle.poetic => 'poetic',
        CaptionStyle.business => 'formal',
        CaptionStyle.casual => 'casual',
        CaptionStyle.news => 'news',
        CaptionStyle.humor => 'humor',
      };

  String get label => switch (this) {
        CaptionStyle.poetic => 'ポエム',
        CaptionStyle.business => 'ビジネス',
        CaptionStyle.casual => 'カジュアル',
        CaptionStyle.news => 'ニュース',
        CaptionStyle.humor => 'ユーモア',
      };
}

/// キャプション生成の文章長選択肢。
enum CaptionLength {
  short,
  medium,
  long;

  String get label => switch (this) {
        CaptionLength.short => '短め',
        CaptionLength.medium => '標準',
        CaptionLength.long => '長め',
      };

  /// プロンプトに含めるヒント文字列。
  /// Edge Function 側プロンプトへの組込は後続 PR でのスコープ。
  String get promptHint => switch (this) {
        CaptionLength.short => '40〜70字',
        CaptionLength.medium => '80〜140字',
        CaptionLength.long => '150〜250字',
      };
}
