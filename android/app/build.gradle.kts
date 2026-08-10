plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pocketbudget.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.pocketbudget.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Create a versioned copy alongside Flutter's default release APK.
tasks.configureEach {
    if (name == "assembleRelease") {
        doLast {
            val versionName = project.findProperty("version-name")?.toString()
                ?: android.defaultConfig.versionName
                ?: "0.0.1"

            val flutterApkDir = file("../../build/app/outputs/flutter-apk")
            val releaseApkDir = file("${layout.buildDirectory.get()}/outputs/apk/release")
            val targetName = "PocketBudget_v${versionName}_release.apk"

            val defaultReleaseApk = file("$releaseApkDir/app-release.apk")
            if (defaultReleaseApk.exists()) {
                defaultReleaseApk.copyTo(file("$releaseApkDir/$targetName"), overwrite = true)
                flutterApkDir.mkdirs()
                defaultReleaseApk.copyTo(file("$flutterApkDir/$targetName"), overwrite = true)
            }
        }
    }
    if (name == "bundleRelease") {
        doLast {
            val versionName = project.findProperty("version-name")?.toString()
                ?: android.defaultConfig.versionName
                ?: "0.0.1"
            val bundleDir = file("${layout.buildDirectory.get()}/outputs/bundle/release")
            val defaultBundle = file("$bundleDir/app-release.aab")
            if (defaultBundle.exists()) {
                defaultBundle.copyTo(
                    file("$bundleDir/PocketBudget_v${versionName}_release.aab"),
                    overwrite = true,
                )
            }
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
