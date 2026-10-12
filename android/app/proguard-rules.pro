# UdyogaSethu ProGuard / R8 Rules for Release Optimization & Obfuscation

# Flutter / Dart Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve Line Numbers & Attributes for Crash Telemetry Symbolication
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google ML Kit Face Detection
-keep class com.google.mlkit.vision.face.** { *; }
-dontwarn com.google.mlkit.**

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Razorpay Flutter Gateway
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }

# Firebase Core & Messaging
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**

