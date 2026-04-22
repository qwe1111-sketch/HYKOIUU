import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _appId = '20251230002530232'; // Baidu App ID
  static const String _appSecret = 'nhIRyfe2DVkz5Hdb0hk1'; // Baidu App Secret
  static const String _baseUrl = 'https://fanyi-api.baidu.com/api/trans/vip/translate';

  final Map<String, String> _translationCache = {};
  Completer<void> _requestChain = Completer()..complete();

  static final Map<String, String> _languageCodeMap = {
    'en': 'en',
    'zh': 'zh',
    'fr': 'fra',
    'de': 'de',
    'ru': 'ru',
    'es': 'spa',
    'ja': 'jp',
    'ko': 'kor',
  };

  Future<String> translate(String query, String toLanguage) async {
    if (query.trim().isEmpty) return query;

    // Check cache first
    final cacheKey = '$toLanguage:$query';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // --- Request Throttling ---
    final currentRequestCompleter = Completer<void>();
    final previousRequestFuture = _requestChain.future;
    _requestChain = currentRequestCompleter;

    await previousRequestFuture;

    try {
      if (_translationCache.containsKey(cacheKey)) {
        return _translationCache[cacheKey]!;
      }

      final lang = toLanguage.split('_').first.split('-').first.toLowerCase();
      final baiduLanguageCode = _languageCodeMap[lang] ?? lang;

      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final sign = _generateSign(query, salt);
      final url = '$_baseUrl?q=${Uri.encodeComponent(query)}&from=auto&to=$baiduLanguageCode&appid=$_appId&salt=$salt&sign=$sign';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['trans_result'] != null && decoded['trans_result'].isNotEmpty) {
          final translatedText = decoded['trans_result'][0]['dst'];
          _translationCache[cacheKey] = translatedText;
          return translatedText;
        }
      }
      return query;
    } catch (e) {
      return query;
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      currentRequestCompleter.complete();
    }
  }

  String _generateSign(String query, String salt) {
    final str = '$_appId$query$salt$_appSecret';
    return md5.convert(utf8.encode(str)).toString();
  }
}
