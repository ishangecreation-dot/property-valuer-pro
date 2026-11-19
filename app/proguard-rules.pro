# Add project specific ProGuard rules here.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.propertyvaluerpro.app.data.models.**$$serializer { *; }
-keepclassmembers class com.propertyvaluerpro.app.data.models.** {
    *** Companion;
}
-keepclasseswithmembers class com.propertyvaluerpro.app.data.models.** {
    kotlinx.serialization.KSerializer serializer(...);
}
