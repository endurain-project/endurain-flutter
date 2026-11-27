import java.util.Properties

// Kotlin is built into AGP 9, so unlike the Flutter phone build (whose Gradle
// plugin still needs the legacy variant API) this build needs no kotlin-android
// plugin. Versions come from android/gradle/libs.versions.toml.
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

// The watch app ships with the same version as the phone app, read from
// pubspec.yaml. Google Play needs a distinct version code for each APK of a
// release, so the watch's is offset well above any phone build number.
// Release builds can pass the phone's values instead, like `flutter build`'s
// --build-name and --build-number:
// -Pendurain.buildName=0.12.0 -Pendurain.buildNumber=22
val pubspecVersion =
    rootProject.file("../../pubspec.yaml").readLines()
        .first { it.startsWith("version:") }
        .removePrefix("version:")
        .trim()
val wearVersionName =
    providers.gradleProperty("endurain.buildName").orNull?.takeIf { it.isNotBlank() }
        ?: pubspecVersion.substringBefore('+')
val wearBuildNumber =
    providers.gradleProperty("endurain.buildNumber").orNull?.takeIf { it.isNotBlank() }
        ?: pubspecVersion.substringAfter('+')
val wearVersionCode = 1_000_000 + wearBuildNumber.toInt()

// Same upload key as the phone app: the Wearable Data Layer only connects
// apps with the same package name and signing certificate.
val keystoreProperties =
    Properties().apply {
        val file = rootProject.file("../key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }

fun signingValue(propertyName: String, environmentName: String): String? =
    (keystoreProperties[propertyName] as String?) ?: System.getenv(environmentName)

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }

android {
    namespace = "com.endurain.endurain.wear"
    // Compose 1.13 (BOM 2026.11) needs compileSdk 37.1.
    compileSdk = 37
    compileSdkMinor = 1

    defaultConfig {
        // Must equal the phone app's id for the Data Layer to connect them.
        applicationId = "com.endurain.endurain"
        // Wear OS 3, the first with Health Services.
        minSdk = 30
        targetSdk = 36
        versionCode = wearVersionCode
        versionName = wearVersionName
    }

    signingConfigs {
        create("release") {
            if (releaseStoreFile != null) {
                // Relative paths resolve against android/app, as in the phone build.
                storeFile = rootProject.file("../app").resolve(releaseStoreFile)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        // The recorder logs through android.util.Log, which the unit-test
        // android.jar stubs out.
        unitTests.isReturnDefaultValues = true
    }

    sourceSets {
        getByName("main") {
            // Protocol and handoff store shared with the phone app, plus the
            // watch-only recording and handoff code.
            kotlin.directories.add("../watch_shared/common/kotlin")
            kotlin.directories.add("../watch_shared/watch/kotlin")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.wear.compose.material3)
    implementation(libs.androidx.wear.compose.foundation)
    implementation(libs.androidx.wear)
    implementation(libs.androidx.wear.ongoing)
    implementation(libs.androidx.wear.protolayout)
    implementation(libs.androidx.wear.protolayout.material3)
    implementation(libs.androidx.wear.tiles)
    implementation(libs.androidx.health.services.client)
    implementation(libs.play.services.wearable)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.coroutines.guava)
    implementation(libs.kotlinx.coroutines.play.services)

    testImplementation(libs.junit)
    testImplementation(libs.org.json)
    testImplementation(libs.kotlinx.coroutines.test)
}
