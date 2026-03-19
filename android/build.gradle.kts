import java.util.regex.Pattern
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 统一编译目录配置
val customBuildDir = File(rootProject.projectDir, "../build")
rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    val subprojectBuildDir = File(customBuildDir, project.name)
    project.layout.buildDirectory.value(project.layout.projectDirectory.dir(subprojectBuildDir.absolutePath))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(customBuildDir)
}

/**
 * 修复逻辑封装：统一对齐到 Java 1.8
 */
fun Project.applyJava8Fix() {
    val android = extensions.findByName("android")
    if (android != null) {
        try {
            val methods = android.javaClass.methods

            // 1. 强制对齐 compileOptions
            val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
            val version18 = JavaVersion.VERSION_1_8
            compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, version18)
            compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, version18)

            // 2. 强制对齐 KotlinOptions
            val kotlinOptions = android.javaClass.methods.find { it.name == "getKotlinOptions" }?.invoke(android)
            kotlinOptions?.javaClass?.getMethod("setJvmTarget", String::class.java)?.invoke(kotlinOptions, "1.8")
            
            // 3. 补全 Namespace (AGP 8.0 必需)
            val getNamespace = methods.find { it.name == "getNamespace" && it.parameterCount == 0 }
            if (getNamespace?.invoke(android) == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val matcher = Pattern.compile("package=\"([^\"]+)\"").matcher(manifestContent)
                    if (matcher.find()) {
                        val packageName = matcher.group(1)
                        if (!packageName.isNullOrEmpty()) {
                            android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, packageName)
                        }
                    }
                }
            }
        } catch (e: Exception) {}
    }
}

subprojects {
    // 强制同步所有任务级别的 Java 编译版本为 1.8
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "1.8"
        targetCompatibility = "1.8"
    }

    // 强制同步所有任务级别的 Kotlin 编译版本为 1.8
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }

    if (state.executed) {
        applyJava8Fix()
    } else {
        afterEvaluate {
            applyJava8Fix()
        }
    }
}
