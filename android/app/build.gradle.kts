import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun signingValue(propertyName: String, environmentName: String): String? {
    return (keystoreProperties[propertyName] as String?)
        ?: System.getenv(environmentName)
}

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingValue(
    "storePassword",
    "ANDROID_KEYSTORE_PASSWORD",
)
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val missingReleaseSigningValues = listOf(
    "ANDROID_KEYSTORE_PATH (or storeFile)" to releaseStoreFile,
    "ANDROID_KEYSTORE_PASSWORD (or storePassword)" to releaseStorePassword,
    "ANDROID_KEY_ALIAS (or keyAlias)" to releaseKeyAlias,
    "ANDROID_KEY_PASSWORD (or keyPassword)" to releaseKeyPassword,
).filter { (_, value) -> value.isNullOrBlank() }.map { (name, _) -> name }
val configuredReleaseStoreFile = releaseStoreFile
    ?.takeIf { it.isNotBlank() }
    ?.let(::file)

if (isReleaseBuild && missingReleaseSigningValues.isNotEmpty()) {
    throw GradleException(
        "Release builds require Android upload-key credentials. Missing: " +
            missingReleaseSigningValues.joinToString(),
    )
}
if (isReleaseBuild && configuredReleaseStoreFile?.isFile != true) {
    throw GradleException(
        "Release builds require a readable upload keystore at " +
            "ANDROID_KEYSTORE_PATH (or storeFile).",
    )
}

android {
    namespace = "com.endurain.endurain"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.endurain.endurain"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = configuredReleaseStoreFile
            storePassword = releaseStorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            // Never publish a debug-signed artifact. The release task checks
            // required upload-key inputs before this variant is configured.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Used by the native activity recorder service for notification/permission
    // helpers. Kept as an explicit dependency since plugin transitive deps are
    // not exposed to the app compile classpath.
    implementation("androidx.core:core-ktx:1.13.1")

    // JVM unit tests for the native activity-recorder models. `org.json` is
    // pulled in as a real implementation because the android.jar on the
    // unit-test classpath only ships non-functional stubs; the Android Gradle
    // Plugin orders it ahead of that stub jar for `testDebugUnitTest`.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
