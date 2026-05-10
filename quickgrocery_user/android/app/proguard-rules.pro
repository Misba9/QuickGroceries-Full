# Flutter / embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Gson / JSON models used by plugins (Razorpay, analytics, etc.)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Razorpay SDK (release minification)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.** { *; }

# Firebase / Play Services — libraries ship their own rules; keep broad warnings off noise
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
