import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:starkmarkdown/windows/filedata.dart';

class Firebasedynamiclink {
  static Future<String> myDynamiclink(FileData fileData) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link:
          Uri.parse("https://www.starkmarkdown.com/users/?fid-${fileData.fid}"),
      uriPrefix: "https://starkmarkdown.page.link",
      androidParameters: const AndroidParameters(
        packageName: "com.example.starkmarkdown",
        minimumVersion: 30,
      ),
    );
    print(fileData.fid);
    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );
    final Uri url = shortLink.shortUrl;
    String _shortLink = url.toString();
    return _shortLink;
  }
}
