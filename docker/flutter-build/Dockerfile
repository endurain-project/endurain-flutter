# Endurain Flutter CI builder image.
#
# Bakes in the Flutter SDK, the Android SDK (command-line tools, platform and
# build-tools) and a JDK so the CI jobs do not have to download and verify the
# toolchain on every run. This mirrors the "prebuilt toolchain image" pattern
# used by the main Endurain repository's Docker images: the base is pinned by
# digest and every downloaded archive is checksum-verified.
#
# Build and publish with .github/workflows/build-ci-docker-image.yml. Bump the ARG
# defaults (and re-run that workflow) when upgrading the toolchain.

# Pinned base. The digest is the multi-arch manifest digest for the tag in the
# trailing comment.
FROM eclipse-temurin:17-jdk-jammy@sha256:beabb759e6f9653c843958d1d1f5cecb881dfb85aa6081e2bef099ab1260344e
# eclipse-temurin:17-jdk-jammy

# --- Toolchain versions (override via --build-arg to upgrade) ---------------
# Flutter SDK. The SHA256 is published by the Flutter release storage bucket.
ARG FLUTTER_VERSION=3.47.1
ARG FLUTTER_ARCHIVE=flutter_linux_3.47.1-stable.tar.xz
ARG FLUTTER_SHA256=a1d8166c0309267cb7dc99f1424eecf08b86946ad3b50723c6f59945964aea45
ARG FLUTTER_STORAGE_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux

# Android SDK. The command-line tools SHA256 is published directly on the
# SDK download page. Secure storage compiles against API 37, main's Flutter
# template still targets API 36 (kept installed for the shared image tag's
# other consumers), while other Android dependencies compile against APIs 35
# and 34. CMake is required by the native-assets toolchain. Build-tools tracks
# AGP's default revision.
# Do not bump cmdline-tools past 15859902: build 16111833 replaces sdkmanager
# with the new `android` CLI, making `sdkmanager --licenses` below a no-op.
ARG ANDROID_CMDLINE_TOOLS_VERSION=15859902
ARG ANDROID_CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
ARG ANDROID_PLATFORM=android-37
ARG ANDROID_FLUTTER_PLATFORM=android-36
ARG ANDROID_PLUGIN_PLATFORM=android-35
ARG ANDROID_LEGACY_PLATFORM=android-34
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358
ARG CMAKE_VERSION=3.22.1

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV GRADLE_USER_HOME=/opt/gradle-home
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# --- OS dependencies --------------------------------------------------------
RUN set -eu; \
    apt-get update; \
    apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils; \
    rm -rf /var/lib/apt/lists/*

# --- Android SDK ------------------------------------------------------------
RUN set -eu; \
    tools_zip="/tmp/android-cmdline-tools.zip"; \
    tmp_dir="/tmp/android-cmdline-tools"; \
    tools_dir="${ANDROID_SDK_ROOT}/cmdline-tools/latest"; \
    mkdir -p "${tmp_dir}" "${tools_dir}"; \
    curl --fail --location --show-error \
        --output "${tools_zip}" \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip"; \
    echo "${ANDROID_CMDLINE_TOOLS_SHA256}  ${tools_zip}" | sha256sum --check -; \
    unzip -q "${tools_zip}" -d "${tmp_dir}"; \
    mv "${tmp_dir}/cmdline-tools/"* "${tools_dir}/"; \
    rm -rf "${tmp_dir}" "${tools_zip}"; \
    yes | sdkmanager --licenses >/dev/null; \
    sdkmanager \
        "platform-tools" \
        "platforms;${ANDROID_PLATFORM}" \
        "platforms;${ANDROID_FLUTTER_PLATFORM}" \
        "platforms;${ANDROID_PLUGIN_PLATFORM}" \
        "platforms;${ANDROID_LEGACY_PLATFORM}" \
        "build-tools;${ANDROID_BUILD_TOOLS}" \
        "ndk;${ANDROID_NDK_VERSION}" \
        "cmake;${CMAKE_VERSION}"

# --- Flutter SDK ------------------------------------------------------------
RUN set -eu; \
    archive_path="/tmp/${FLUTTER_ARCHIVE}"; \
    curl --fail --location --show-error \
        --output "${archive_path}" \
        "${FLUTTER_STORAGE_URL}/${FLUTTER_ARCHIVE}"; \
    echo "${FLUTTER_SHA256}  ${archive_path}" | sha256sum --check -; \
    tar -xf "${archive_path}" -C /opt; \
    rm -f "${archive_path}"; \
    # CI checks out the repository as a different owner than the image build,
    # so mark all directories as safe for the git invocations Flutter makes.
    git config --global --add safe.directory '*'; \
    flutter --version | grep "Flutter ${FLUTTER_VERSION}"; \
    flutter config --android-sdk "${ANDROID_SDK_ROOT}" --no-analytics; \
    yes | flutter doctor --android-licenses >/dev/null || true; \
    flutter precache --android --universal

# Preload the project's Gradle distribution so container jobs do not depend on
# services.gradle.org. Retries keep image publication resilient to a truncated
# first download.
COPY android/gradle/wrapper/gradle-wrapper.properties /tmp/gradle-wrapper.properties
RUN set -eu; \
    # Underscore: flutter create derives a Dart package name from the directory.
    flutter create --no-pub --platforms=android /tmp/gradle_bootstrap; \
    cp /tmp/gradle-wrapper.properties \
        /tmp/gradle_bootstrap/android/gradle/wrapper/gradle-wrapper.properties; \
    attempt=1; \
    until (cd /tmp/gradle_bootstrap/android && ./gradlew --version); do \
        if [ "${attempt}" -ge 3 ]; then \
            exit 1; \
        fi; \
        attempt=$((attempt + 1)); \
    done; \
    rm -rf /tmp/gradle_bootstrap /tmp/gradle-wrapper.properties

# Sanity check that the toolchain is wired up.
RUN flutter doctor -v
