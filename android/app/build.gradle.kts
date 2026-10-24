import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release key comes from android/key.properties on a release machine, or from CI secrets
// (ANDROID_KEYSTORE_PATH and friends). Neither is ever committed.
val keyProperties =
    Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }

fun signingValue(property: String, environment: String): String? =
    keyProperties.getProperty(property) ?: System.getenv(environment)

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val hasReleaseKey = releaseStoreFile != null

android {
    namespace = "com.bravynix.schoolerp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.bravynix.schoolerp"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // AGP 9 turns resValue off by default; the flavors use it for the app name.
    buildFeatures {
        resValues = true
    }

    // One flavor per environment, so dev, staging and prod installs sit side by side.
    // Run with: flutter run --flavor dev --dart-define-from-file=config/dev.json
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "BravyNix Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
            resValue("string", "app_name", "BravyNix Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "BravyNix")
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Without the release key, dev and staging release builds fall back to the debug key
            // so `flutter run --release` works on a developer's phone. A prod release refuses
            // (below): a store build signed with the debug key could never be updated.
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

tasks.configureEach {
    if (!hasReleaseKey && Regex("(assemble|bundle|package)ProdRelease").matches(name)) {
        doFirst {
            throw GradleException(
                "A prod release needs the release key: android/key.properties or ANDROID_KEYSTORE_* in CI.",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
