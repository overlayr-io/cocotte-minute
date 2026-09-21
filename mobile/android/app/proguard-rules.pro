# Play Core (deferred components) référencé par le Flutter embedding mais non
# utilisé par l'app — évite un crash R8 "class missing" au build release.
-dontwarn com.google.android.play.core.**

# RevenueCat sérialise ses modèles en JSON réflexivement.
-keep class com.revenuecat.purchases.** { *; }

# Supabase (gotrue/postgrest) : modèles de réponse désérialisés par nom de champ.
-keep class io.github.jan.supabase.** { *; }
