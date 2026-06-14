import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme.dart';

/// d**AI**ary ロゴ + タグライン。
/// 出典: docs/dAIary_brand_design.jsx, docs/dAIary_screen_layouts.jsx
class DaiaryLogo extends StatelessWidget {
  const DaiaryLogo({this.fontSize = 38, this.showTagline = true, super.key});

  final double fontSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      color: DaiaryColors.deepBrown,
      height: 1.1,
    );
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'd', style: base.copyWith(fontWeight: FontWeight.w400)),
              TextSpan(
                text: 'AI',
                style: base.copyWith(
                  color: DaiaryColors.brandGold,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(
                  text: 'ary',
                  style: base.copyWith(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            '写真に、言葉を添えて。',
            style: GoogleFonts.notoSansJp(
              fontSize: 10,
              color: const Color(0xFF9A9590),
              fontWeight: FontWeight.w300,
              letterSpacing: 3.2,
            ),
          ),
        ],
      ],
    );
  }
}
