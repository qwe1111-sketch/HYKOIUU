import 'dart:developer';
import 'package:sport_flutter/config/app_config.dart';

class UrlFormatter {
  static String get _baseUrl => AppConfig.baseUrl;

  static String format(String? relativePath) {
    log('[UrlFormatter] Formatting path: "$relativePath"');
    if (relativePath == null || relativePath.isEmpty) {
      log('[UrlFormatter] Path is null or empty, returning empty string.');
      return '';
    }
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      log('[UrlFormatter] Path is already absolute: "$relativePath"');
      return relativePath;
    }
    final formattedUrl =
        _baseUrl +
        (relativePath.startsWith('/') ? relativePath : '/' + relativePath);
    log('[UrlFormatter] Formatted URL: "$formattedUrl"');
    return formattedUrl;
  }
}
