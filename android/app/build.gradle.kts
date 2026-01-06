plugins {
    id("com.android.application")
    // Le plugin Firebase doit être ici
    id("com.google.gms.google-services")
    id("kotlin-android")
    // Le plugin Flutter doit être après
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.salon_connect"
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
        // Assure-toi que cet ID correspond à ton google-services.json
        applicationId = "com.example.salon_connect"
        
        // --- MODIFICATION CRUCIALE POUR FIREBASE ---
        minSdk = flutter.minSdkVersion
        // -------------------------------------------

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --- AJOUT POUR ÉVITER LES CRASHS ---
        multiDexEnabled = true
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
