# ---- Room ----
-keep class androidx.room.** { *; }
-dontwarn androidx.room.paging.**

# ---- Kotlinx Serialization ----
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ---- Apache POI (Excel) ----
-dontwarn org.apache.poi.**
-dontwarn org.openxmlformats.**
-dontwarn org.apache.xmlbeans.**
-dontwarn com.microsoft.schemas.**
-dontwarn org.etsi.uri.**
-dontwarn org.w3.x2000.**
-dontwarn org.osgi.**
-dontwarn javax.xml.stream.**
-dontwarn org.apache.logging.log4j.**
-dontwarn java.awt.**
-dontwarn javax.swing.**
-keep class org.apache.poi.** { *; }
-keep class org.openxmlformats.** { *; }
-keep class org.apache.xmlbeans.** { *; }
-keep class com.microsoft.schemas.** { *; }
-keep class com.fasterxml.aalto.** { *; }

# ---- General model classes (Room entities etc.) ----
-keep class org.chirag.springshed.data.entities.** { *; }
