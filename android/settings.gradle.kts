pluginManagement {
    // The plugins {} block below cannot use version catalog accessors, so the
    // plugin versions are read from the shared catalog (gradle/libs.versions.toml).
    val catalogVersions =
        file("gradle/libs.versions.toml").readLines()
            .mapNotNull { Regex("""^(\w+)\s*=\s*"([^"]+)"\s*$""").find(it.trim()) }
            .associate { it.groupValues[1] to it.groupValues[2] }
    fun catalogVersion(name: String): String =
        requireNotNull(catalogVersions[name]) { "$name not set in gradle/libs.versions.toml" }

    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    plugins {
        id("com.android.application") version catalogVersion("agp")
        id("org.jetbrains.kotlin.android") version catalogVersion("kotlin")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

include(":app")
