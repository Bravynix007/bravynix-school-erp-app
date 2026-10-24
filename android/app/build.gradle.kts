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

// A blank value counts as missing: CI expands an unset secret to an empty string.
fun signingValue(property: String, environment: String): String? =
    (keyProperties.getProperty(property) ?: System.getenv(environment))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val hasReleaseKey =
    listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword).all { it != null }

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
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
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

// Checked once the task graph is known and before any task runs, so no debug-signed prod APK or
// AAB is ever written: a check in the tasks themselves ran after the bundle was packaged and signed.
gradle.taskGraph.whenReady {
    val buildsProdRelease = allTasks.any { it.project == project && it.name.contains("ProdRelease") }
    if (buildsProdRelease && !hasReleaseKey) {
        throw GradleException(
            "A prod release needs the release key: storeFile, storePassword, keyAlias and keyPassword " +
                "in android/key.properties, or ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, " +
                "ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD in CI.",
        )
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
