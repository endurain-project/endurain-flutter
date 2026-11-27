// Standalone build for the Wear OS app, kept out of the Flutter Gradle build
// so `flutter build apk` never compiles it. Run it with the phone build's
// wrapper: `cd android && ./gradlew -p wear assembleDebug`.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
    versionCatalogs {
        // Shared with the phone build (android/settings.gradle.kts).
        create("libs") {
            from(files("../gradle/libs.versions.toml"))
        }
    }
}

rootProject.name = "endurain-wear"
