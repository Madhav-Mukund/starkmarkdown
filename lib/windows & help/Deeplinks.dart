import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'userdata.dart';

import 'filedata.dart';

class Firebasedynamiclink {
  static Future<String> myDynamiclink(
      FileData fileData, UserData userData) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse(
          "https://www.starkmarkdown.com/users/?uid=${userData.uid}&fid=${fileData.fid}"),
      uriPrefix: "https://starkmarkdown.page.link",
      androidParameters: const AndroidParameters(
        packageName: "com.example.starkmarkdown",
        minimumVersion: 30,
      ),
    );
    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      dynamicLinkParams,
      shortLinkType: ShortDynamicLinkType.unguessable,
    );
    final Uri url = shortLink.shortUrl;
    String shortlink = url.toString();
    return shortlink;
  }
}
