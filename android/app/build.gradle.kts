import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.firebase.crashlytics")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}
val signingFile = rootProject.file("key.properties")
val hasReleaseSigning = signingFile.exists()
val releaseKeys = Properties()
if (hasReleaseSigning) signingFile.inputStream().use { releaseKeys.load(it) }
android {
    namespace = "com.usmanch.bloodbank"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.usmanch.bloodbank"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
            }
        }
    }
    buildTypes {
        release {
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
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
