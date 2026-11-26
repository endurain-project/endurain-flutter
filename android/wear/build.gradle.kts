import java.util.Properties

// Keep the plugin versions in sync with android/settings.gradle.kts. Kotlin is
// built into AGP 9, so unlike the Flutter phone build (whose Gradle plugin still
// needs the legacy variant API) this build needs no kotlin-android plugin.
plugins {
    id("com.android.application") version "9.5.2"
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.21"
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
    compileSdk = 37
    compileSdkMinor = 0

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
            // Protocol and stores shared with the phone app.
            kotlin.directories.add("../watch_shared/kotlin")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Newer BOMs need compileSdk 37.1, which the CI image does not install.
    implementation(platform("androidx.compose:compose-bom:2026.09.00"))
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.core:core-ktx:1.19.1")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.1")
    implementation("androidx.wear.compose:compose-material3:1.7.2")
    implementation("androidx.wear.compose:compose-foundation:1.7.2")
    implementation("androidx.wear:wear:1.4.0")
    implementation("androidx.wear:wear-ongoing:1.1.0")
    implementation("androidx.health:health-services-client:1.1.0")
    implementation("com.google.android.gms:play-services-wearable:20.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.11.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20260814")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}
