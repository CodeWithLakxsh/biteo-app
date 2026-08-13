import java.util.Properties

// 1. Load local.properties to read the MAPS_API_KEY
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")

if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use {
        localProperties.load(it)
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.biteo.biteo"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {

        // 🔥 REQUIRED FOR FIREBASE + NOTIFICATIONS
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17
    }

    kotlinOptions {

        jvmTarget =
            JavaVersion.VERSION_17.toString()
    }

    defaultConfig {

        applicationId = "com.biteo.biteo"

        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName

        multiDexEnabled = true

        // 🔥 MAPS API KEY
        val mapsApiKey =
            localProperties.getProperty(
                "MAPS_API_KEY"
            ) ?: "MISSING_KEY"

        manifestPlaceholders["MAPS_API_KEY"] =
            mapsApiKey
    }

    buildTypes {

        getByName("release") {

            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

flutter {

    source = "../.."
}

dependencies {

    // 🔥 FIXED VERSION
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}