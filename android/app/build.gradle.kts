import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()

if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "dev.glasstrail.glasstrail"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.glasstrail.glasstrail"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                val keystorePath =
                    requireNotNull(keystoreProperties.getProperty("storeFile")) {
                        "storeFile missing in android/key.properties"
                    }
                val releaseStoreFile = rootProject.file(keystorePath)
                require(releaseStoreFile.exists()) {
                    "Release keystore not found at ${releaseStoreFile.path}"
                }

                storeFile = releaseStoreFile
                storePassword =
                    requireNotNull(keystoreProperties.getProperty("storePassword")) {
                        "storePassword missing in android/key.properties"
                    }
                keyAlias =
                    requireNotNull(keystoreProperties.getProperty("keyAlias")) {
                        "keyAlias missing in android/key.properties"
                    }
                keyPassword =
                    requireNotNull(keystoreProperties.getProperty("keyPassword")) {
                        "keyPassword missing in android/key.properties"
                    }
            }
        }
    }

    buildTypes {
        release {
            // Use the real release keystore when present and fall back to the
            // debug key for local release builds that do not provide one.
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
