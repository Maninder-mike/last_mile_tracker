# Proguard Rules for Last Mile Tracker Android Application

# Enable aggressive optimization passes
-optimizationpasses 5
-allowaccessmodification

# Repackage all obfuscated classes into a single package to maximize shrinking score
-repackageclasses 'o'

# Strict Flutter embedding keep rules (minimum required)
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugin.editing.TextInputPlugin { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift SQLite bindings keep rules
-keep class sqlite3.** { *; }
-keep class com.sqlite.** { *; }
-dontwarn sqlite3.**

# Firebase/GMS keep rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
