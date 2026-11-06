# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.**

# Google protobuf
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# 保留所有 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 model 类
-keep class **.model.** { *; }
-keep class **.models.** { *; }
