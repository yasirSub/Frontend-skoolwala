plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

android {
    namespace = "com.skoolwala.skoolwala"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Load keystore properties from android/key.properties
    val keystoreProperties = Properties().apply {
        val keyPropsFile = file("../key.properties")
        if (keyPropsFile.exists()) {
            keyPropsFile.inputStream().use { input ->
                this.load(input)
            }
        }
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Use a unique application ID for Play Store
        applicationId = "com.skoolwala.skoolwala"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release keystore for signed builds
            signingConfig = signingConfigs.getByName("release")
            // Temporarily disable code shrinking to fix timer issue
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     file("proguard-rules.pro")
            // )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Ensure GPU delegate classes are packaged for TensorFlow Lite
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
}
