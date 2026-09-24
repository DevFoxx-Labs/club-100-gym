# Flutter engine and plugin embedding classes are invoked via reflection
# by the engine itself; keep them all so the app doesn't crash at runtime.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications serializes scheduled-notification data with
# Gson reflection; stripping these breaks reminders silently.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# mobile_scanner's ML Kit barcode scanning backend.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter's engine references Play Core's deferred-component (dynamic
# feature delivery) APIs even though this app doesn't use that library or
# feature; safe to ignore since they're never actually called.
-dontwarn com.google.android.play.core.**
