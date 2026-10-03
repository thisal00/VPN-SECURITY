# ProGuard & R8 Hardening for WARP Shield (Anti-Reverse Engineering)

# Preserve AmneziaWG Native Tunnel and JNI hooks
-keep class org.amnezia.awg.** { *; }
-keepclassmembers class org.amnezia.awg.** { *; }

# Preserve WireguardFlutterPlugin Method Channels & Bindings
-keep class billion.group.wireguard_flutter.** { *; }
-keepclassmembers class billion.group.wireguard_flutter.** { *; }

# Protect Flutter engine and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Obfuscate internal implementation classes & remove source debug info
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
-repackageclasses 'billion.shield.internal'
-allowaccessmodification
-dontwarn org.amnezia.awg.**
