import 'package:share_plus/share_plus.dart';

/// OS 標準共有シート連携。
class ShareService {
  const ShareService._();

  static Future<void> shareText(String text, {String? subject}) {
    return Share.share(text, subject: subject);
  }

  static Future<void> shareFiles(List<String> paths, {String? text}) {
    return Share.shareXFiles(
      paths.map(XFile.new).toList(growable: false),
      text: text,
    );
  }
}
