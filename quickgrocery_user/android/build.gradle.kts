import org.gradle.api.Project

// google-services version is declared in settings.gradle.kts (FlutterFire).

fun applyAndroidJava17(project: Project) {
    val android = project.extensions.findByName("android") ?: return
    try {
        val compileOptions =
            android.javaClass.methods.first { it.name == "getCompileOptions" }.invoke(android)
        compileOptions.javaClass.methods
            .first { it.name == "setSourceCompatibility" }
            .invoke(compileOptions, JavaVersion.VERSION_17)
        compileOptions.javaClass.methods
            .first { it.name == "setTargetCompatibility" }
            .invoke(compileOptions, JavaVersion.VERSION_17)
    } catch (_: Exception) {
        // Non-standard Android extension; skip.
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Push Java 17 through Flutter plugin modules (no duplicate AGP on classpath).
subprojects {
    val sub = this
    pluginManager.withPlugin("com.android.library") {
        applyAndroidJava17(sub)
    }
    pluginManager.withPlugin("com.android.application") {
        applyAndroidJava17(sub)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
