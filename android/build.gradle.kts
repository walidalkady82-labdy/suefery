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
subprojects {
    subprojects {
    afterEvaluate {
        // Check if the project has the Android plugin applied
        if (extensions.findByName("android") != null) {
            // Force the configuration using the correct type
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
                ndkVersion = "28.2.13676358"
            }
        }
    }
}
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
