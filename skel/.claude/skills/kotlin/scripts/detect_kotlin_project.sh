#!/usr/bin/env bash
# Summarise a Kotlin project's toolchain and conventions so code can match them.
# Usage: detect_kotlin_project.sh [project-root]   (read-only; never modifies files)
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" 2>/dev/null || { echo "Cannot cd into $ROOT" >&2; exit 1; }

# Build files, excluding build output and dependency caches.
mapfile -t BUILD_FILES < <(find . \( -name build -o -name .gradle -o -name node_modules -o -name .git \) -prune -o \
  \( -name '*.gradle.kts' -o -name '*.gradle' -o -name 'pom.xml' -o -name 'libs.versions.toml' -o -name 'gradle.properties' \) \
  -type f -print 2>/dev/null)

if [ ${#BUILD_FILES[@]} -eq 0 ]; then
  echo "No Gradle/Maven build files found under $(pwd)."
  exit 0
fi

has() { grep -qsE -- "$1" "${BUILD_FILES[@]}"; }
first_match() { grep -hsoE -- "$1" "${BUILD_FILES[@]}" | head -n1; }

echo "== Build"
[ -x ./gradlew ] && echo "Gradle wrapper: ./gradlew" || { [ -f ./gradlew ] && echo "Gradle wrapper: ./gradlew (not executable: use 'sh gradlew')"; }
[ -f ./mvnw ] && echo "Maven wrapper: ./mvnw"
[ -f pom.xml ] && [ ! -f ./mvnw ] && echo "Maven project (no wrapper)"
[ -f gradle/libs.versions.toml ] && echo "Version catalog: gradle/libs.versions.toml (add versions there)"
[ -f gradle/wrapper/gradle-wrapper.properties ] && \
  echo "Gradle: $(grep -oE 'gradle-[0-9][^-]*' gradle/wrapper/gradle-wrapper.properties | head -n1)"
MODS=$(grep -hoE 'include\(?[[:space:]]*"[^"]+"' settings.gradle.kts settings.gradle 2>/dev/null | grep -oE '"[^"]+"' | tr -d '"')
[ -n "$MODS" ] && echo "Modules ($(echo "$MODS" | wc -l | tr -d ' ')): $(echo "$MODS" | head -n 12 | paste -sd ' ' -)$( [ "$(echo "$MODS" | wc -l)" -gt 12 ] && echo ' ...')"

echo
echo "== Kotlin version"
KV=$(first_match '^kotlin[A-Za-z-]*[[:space:]]*=[[:space:]]*"[0-9][^"]*"')
[ -z "$KV" ] && KV=$(first_match 'kotlin\("[a-z.]+"\)[[:space:]]+version[[:space:]]+"[^"]+"')
[ -z "$KV" ] && KV=$(first_match 'org\.jetbrains\.kotlin(\.[a-z.-]+)?"\)?[[:space:]]+version[[:space:]]+"[^"]+"')
[ -z "$KV" ] && KV=$(first_match '<kotlin\.version>[^<]+</kotlin\.version>')
[ -z "$KV" ] && KV=$(first_match 'kotlin_version[[:space:]]*=[[:space:]]*[^[:space:]]+')
echo "${KV:-unknown. Try: ./gradlew -q buildEnvironment | grep kotlin-gradle-plugin  (else write 2.0-compatible code)}"
LV=$(first_match '(languageVersion|apiVersion)[^A-Za-z0-9]+[A-Za-z_.]*[0-9]_?[0-9]+')
[ -n "$LV" ] && echo "Pinned language/api version: $LV (this, not the plugin version, limits features)"

echo
echo "== Platform & plugins"
has 'kotlin\("multiplatform"\)|kotlin-multiplatform|org\.jetbrains\.kotlin\.multiplatform' && echo "- Kotlin Multiplatform"
has 'com\.android\.(application|library)|android\.application|android\.library' && echo "- Android"
has 'kotlin\("jvm"\)|org\.jetbrains\.kotlin\.jvm|kotlin-maven-plugin' && echo "- Kotlin/JVM"
has 'org\.springframework\.boot' && echo "- Spring Boot"
has 'plugin\.spring|kotlin-spring|allopen|<plugin>spring<' && echo "- all-open (Spring) plugin"
has 'plugin\.jpa|kotlin-jpa|noarg|<plugin>jpa<' && echo "- no-arg (JPA) plugin"
has 'io\.ktor' && echo "- Ktor"
has 'plugin\.serialization|kotlinx-serialization|kotlinx\.serialization' && echo "- kotlinx.serialization"
has 'jackson-module-kotlin' && echo "- Jackson Kotlin module"
has 'plugin\.compose|compose' && echo "- Compose"
has 'com\.google\.devtools\.ksp|\bksp\(' && echo "- KSP"
has '\bkapt\b' && echo "- kapt"
has 'kotlinx-coroutines' && echo "- kotlinx.coroutines"
has 'arrow-kt|io\.arrow-kt' && echo "- Arrow"
has 'kotlinx-datetime' && echo "- kotlinx-datetime"

echo
echo "== Tests"
has 'junit-jupiter|useJUnitPlatform|junit5' && echo "- JUnit 5"
has 'junit:junit:|"junit:junit|junit4' && echo "- JUnit 4"
has 'kotlin\("test"\)|kotlin-test' && echo "- kotlin.test"
has 'io\.kotest|kotest' && echo "- Kotest"
has 'io\.mockk|mockk' && echo "- MockK"
has 'mockito-kotlin|org\.mockito\.kotlin' && echo "- mockito-kotlin"
has 'mockito-core|mockito-inline' && echo "- Mockito"
has 'app\.cash\.turbine|turbine' && echo "- Turbine"
has 'kotlinx-coroutines-test' && echo "- kotlinx-coroutines-test"
has 'assertj' && echo "- AssertJ"
has 'kover' && echo "- Kover coverage"

echo
echo "== Style & API gates"
has 'detekt' && echo "- detekt$( [ -f config/detekt/detekt.yml ] && echo ' (config/detekt/detekt.yml)')"
has 'ktlint' && echo "- ktlint"
has 'spotless' && echo "- Spotless"
[ -f .editorconfig ] && echo "- .editorconfig$(grep -qs 'ktlint' .editorconfig && echo ' (has ktlint rules)')"
has 'explicitApi' && echo "- explicit API mode (explicit visibility + return types required)"
has 'binary-compatibility-validator|abiValidation|apiValidation' && echo "- binary compatibility validation (run apiCheck after public API changes)"
has 'allWarningsAsErrors[[:space:]]*(=|\.set\()[[:space:]]*\(?true|-Werror' && echo "- warnings are errors"
grep -hsoE -- '"-X[a-z][a-z-]+' $(printf '%s\n' "${BUILD_FILES[@]}" | grep -v 'gradle.properties$') 2>/dev/null | tr -d '"' | sort -u | sed 's|^|- compiler flag (kotlinc or javac): |'

echo
echo "== Source layout"
for d in src/main/kotlin src/main/java src/commonMain/kotlin app/src/main/java app/src/main/kotlin; do
  [ -d "$d" ] && echo "- $d ($(find "$d" -name '*.kt' | wc -l | tr -d ' ') .kt files)"
done
TOTAL_KT=$(find . \( -name build -o -name .gradle \) -prune -o -name '*.kt' -print 2>/dev/null | wc -l | tr -d ' ')
TOTAL_JAVA=$(find . \( -name build -o -name .gradle \) -prune -o -name '*.java' -print 2>/dev/null | wc -l | tr -d ' ')
echo "- totals: $TOTAL_KT .kt, $TOTAL_JAVA .java"
