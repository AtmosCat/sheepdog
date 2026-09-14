group = "io.flutter.plugins.inapppurchase"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "io.flutter.plugins.inapppurchase"
    compileSdk = 36

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    lint {
        checkAllWarnings = false
        warningsAsErrors = false
        disable += setOf(
            "AndroidGradlePluginVersion",
            "InvalidPackage",
            "GradleDependency",
            "NewerVersionAvailable",
        )
    }
}

dependencies {
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("com.android.billingclient:billing:8.0.0")
}
