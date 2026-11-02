# shared_preferences_android 2.5+ calls its Kotlin code through JNI, and the
# generated bindings (plus package:jni) look these Kotlin classes up by name.
# R8 renames them in release builds, so the method descriptors the Dart side
# uses no longer exist and every SharedPreferencesAsync call throws
# NoSuchMethodError (flutter/flutter#194649). Neither the plugin nor package:jni
# ships consumer rules for them yet (dart-lang/native#3732).
# Remove this block once package:jni keeps these classes itself.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
