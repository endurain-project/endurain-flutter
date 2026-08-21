# Endurain Flutter CI builder image.
#
# Bakes in the Flutter SDK, the Android SDK (command-line tools, platform and
# build-tools) and a JDK so the CI jobs do not have to download and verify the
# toolchain on every run. This mirrors the "prebuilt toolchain image" pattern
# used by the main Endurain repository's Docker images: the base is pinned by
# digest and every downloaded archive is checksum-verified.
#
# Build and publish with .forgejo/workflows/build-ci-docker-image.yml. Bump the ARG
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
# SDK download page. Flutter uses API 36, while Android dependencies still
# compile against APIs 35 and 34. CMake is required by the native-assets
# toolchain.
ARG ANDROID_CMDLINE_TOOLS_VERSION=15859902
ARG ANDROID_CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
ARG ANDROID_PLATFORM=android-36
ARG ANDROID_PLUGIN_PLATFORM=android-35
ARG ANDROID_LEGACY_PLATFORM=android-34
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358
ARG CMAKE_VERSION=3.22.1

# Node.js runtime. Forgejo/act runs JavaScript actions (actions/checkout,
# actions/cache) by exec'ing `node` inside this image, so the runtime must be
# baked in. The SHA256 is published in the release's SHASUMS256.txt.
ARG NODE_VERSION=22.23.2
ARG NODE_ARCHIVE=node-v22.23.2-linux-x64.tar.xz
ARG NODE_SHA256=d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV GRADLE_USER_HOME=/opt/gradle-home
ENV NODE_HOME=/opt/node
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${NODE_HOME}/bin:${PATH}"

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

# --- Node.js ----------------------------------------------------------------
RUN set -eu; \
    archive_path="/tmp/${NODE_ARCHIVE}"; \
    curl --fail --location --show-error \
        --output "${archive_path}" \
        "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_ARCHIVE}"; \
    echo "${NODE_SHA256}  ${archive_path}" | sha256sum --check -; \
    mkdir -p "${NODE_HOME}"; \
    tar -xf "${archive_path}" -C "${NODE_HOME}" --strip-components=1; \
    rm -f "${archive_path}"; \
    node --version | grep "v${NODE_VERSION}"

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
    flutter create --no-pub --platforms=android /tmp/gradle-bootstrap; \
    cp /tmp/gradle-wrapper.properties \
        /tmp/gradle-bootstrap/android/gradle/wrapper/gradle-wrapper.properties; \
    attempt=1; \
    until (cd /tmp/gradle-bootstrap/android && ./gradlew --version); do \
        if [ "${attempt}" -ge 3 ]; then \
            exit 1; \
        fi; \
        attempt=$((attempt + 1)); \
    done; \
    rm -rf /tmp/gradle-bootstrap /tmp/gradle-wrapper.properties

# Sanity check that the toolchain is wired up.
RUN flutter doctor -v
