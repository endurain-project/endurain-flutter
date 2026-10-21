# shared_preferences_android 2.5+ calls its Kotlin API reflectively over JNI
# (including suspend functions with a Continuation parameter). R8 renames or
# strips those members in release builds, so every SharedPreferencesAsync call
# fails with NoSuchMethodError at runtime. Keep the plugin intact.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
