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
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Firebase Phone Auth / reCAPTCHA / SafetyNet / Play Integrity
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth-api.** { *; }
-keep class com.google.android.gms.safetynet.** { *; }
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
