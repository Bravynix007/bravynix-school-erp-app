import 'package:bravynix_school_erp/features/files/domain/file_opening.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// The phone's browser, through `url_launcher`: the link of FIL-03 makes it download the file.
class UrlFileOpening implements FileOpening {
  const new();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
