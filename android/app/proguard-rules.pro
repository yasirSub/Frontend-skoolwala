# Keep TensorFlow Lite and GPU delegate classes
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep ML Kit face detection classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Flutter plugin entry points
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep camera plugin classes
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Keep timer and attendance related classes
-keep class * extends android.view.View { *; }
-keepclassmembers class * {
    android.os.CountDownTimer *;
}

# Keep widgets used in timer displays
-keep class android.widget.* { *; }
