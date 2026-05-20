plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.app_medica"

    // Plugins like flutter_local_notifications / image_picker_android require API 36 compileSdk.
    // This is backward compatible with older Android versions at runtime.
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Core library desugaring is required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true

        // Keep Java 17 (matches Android Gradle Plugin 8.x defaults and your current setup).
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.app_medica"

        minSdk = flutter.minSdkVersion

        // You can compile with 36 but still target 34+ if desired.
        // Keeping targetSdk aligned to avoid plugin AAR metadata errors.
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    dependencies {
        // Required for Java 8+ API backports used by some AndroidX/libs.
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
