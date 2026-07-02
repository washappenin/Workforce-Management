plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aurelia.workforce.aurelia_mobile"
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
        applicationId = "com.aurelia.workforce"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"

    productFlavors {
        create("employee") {
            dimension = "app"
            applicationId = "com.aurelia.workforce.employee"
            resValue("string", "app_name", "Aurelia Employee")
        }
        create("manager") {
            dimension = "app"
            applicationId = "com.aurelia.workforce.manager"
            resValue("string", "app_name", "Aurelia Manager")
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.aurelia.workforce.admin"
            resValue("string", "app_name", "Aurelia Admin")
        }
        create("platform") {
            dimension = "app"
            applicationId = "com.aurelia.workforce.platform"
            resValue("string", "app_name", "Aurelia Platform")
        }
    }

    buildTypes {
        release {
            // Store release signing is configured after Play Console setup.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
