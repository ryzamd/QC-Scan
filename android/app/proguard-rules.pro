# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dio
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**

# JSON Models
-keep class ** implements com.google.gson.TypeAdapterFactory
-keep class ** implements com.google.gson.JsonSerializer
-keep class ** implements com.google.gson.JsonDeserializer
-keep class architecture_scan_app.models.** { *; }

# Mobile Scanner
-keep class com.google.mlkit.** { *; }

# Equatable
-keepclassmembers class ** extends equatable.Equatable {
    public boolean equals(java.lang.Object);
    public int hashCode();
}

# Keep data models
-keep class **.data.models.** { *; }

# Ignore missing Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**