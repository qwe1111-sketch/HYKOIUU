// lib/config/app_config.dart
// 通过 --dart-define 切换环境
//
// 本地开发（连接本地后端）：
//   flutter run --dart-define=API_BASE_URL=http://localhost:3000
//
// 真机调试（连接电脑局域网后端）：
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
//
// 发布（连接服务器）：
//   flutter build apk --dart-define=API_BASE_URL=https://hykoiuu.hykoiuu.com
//   或不写 --dart-define，默认就是服务器地址

class AppConfig {
  // 基础域名（不含路径），例如 https://hykoiuu.hykoiuu.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hykoiuu.hykoiuu.com',
  );

  // API 根路径，例如 https://hykoiuu.hykoiuu.com/api
  static String get apiBaseUrl => '$baseUrl/api';

  // 认证接口根路径，例如 https://hykoiuu.hykoiuu.com/api/auth
  static String get authBaseUrl => '$baseUrl/api/auth';
}
