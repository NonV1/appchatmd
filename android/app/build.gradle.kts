plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin ต้องอยู่หลัง Android/Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.chatmd_v1"
    compileSdk = 36 // ✅ ตั้งค่าชัดเจนแทนการใช้ maxOf

    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ ใช้ Java 17 ตามที่ Android Gradle Plugin 8.0+ และ Health Connect ต้องการ
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // ✅ ให้ Kotlin ใช้ JVM 17 เช่นกัน
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.chatmd_v1"
        minSdk = 26  // ✅ Health Connect ต้องการอย่างน้อย Android 8 (API 26)
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ ใช้ signingConfig จริงภายหลังเมื่อ release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Align with the version used by the `health` plugin to maximize compatibility.
    implementation("androidx.health.connect:connect-client:1.1.0-rc03")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
}

flutter {
    source = "../.."
}
