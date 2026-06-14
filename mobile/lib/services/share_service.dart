import 'package:share_plus/share_plus.dart';

/// OS 標準共有シート連携。
///
/// share_plus 12+ では SharePlus.instance.share(ShareParams(...)) が正規の API。
class ShareService {
  const ShareService._();

  static Future<ShareResult> shareText(String text, {String? subject}) {
    return SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  static Future<ShareResult> shareFiles(List<String> paths, {String? text}) {
    return SharePlus.instance.share(
      ShareParams(
        files: paths.map(XFile.new).toList(growable: false),
        text: text,
      ),
    );
  }
}
