# Endurain Flutter CI builder image.
#
# Bakes in the Flutter SDK, the Android SDK (command-line tools, platform and
# build-tools) and a JDK so the CI jobs do not have to download and verify the
# toolchain on every run. This mirrors the "prebuilt toolchain image" pattern
# used by the main Endurain repository's Docker images: the base is pinned by
# digest and every downloaded archive is checksum-verified.
#
# Build and publish with .forgejo/workflows/build-image.yml. Bump the ARG
# defaults (and re-run that workflow) when upgrading the toolchain.

# Pinned base. The digest is the multi-arch manifest digest for the tag in the
# trailing comment.
FROM eclipse-temurin:17-jdk-jammy@sha256:beabb759e6f9653c843958d1d1f5cecb881dfb85aa6081e2bef099ab1260344e
# eclipse-temurin:17-jdk-jammy

# --- Toolchain versions (override via --build-arg to upgrade) ---------------
# Flutter SDK. The SHA256 is published by the Flutter release storage bucket.
ARG FLUTTER_VERSION=3.44.1
ARG FLUTTER_ARCHIVE=flutter_linux_3.44.1-stable.tar.xz
ARG FLUTTER_SHA256=287937458126a53284ed112c8c7dbc647bea2d09ab65d46e2d5cf94e901aac69
ARG FLUTTER_STORAGE_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux

# Android SDK. The command-line tools SHA256 is verified against the archive
# (Google only publishes SHA1 in its manifest, so it was cross-checked against
# that SHA1). The platform/build-tools versions must satisfy the Flutter-derived
# compileSdk.
ARG ANDROID_CMDLINE_TOOLS_VERSION=14742923
ARG ANDROID_CMDLINE_TOOLS_SHA256=04453066b540409d975c676d781da1477479dde3761310f1a7eb92a1dfb15af7
ARG ANDROID_PLATFORM=android-36
ARG ANDROID_BUILD_TOOLS=36.0.0

# Node.js runtime. Forgejo/act runs JavaScript actions (actions/checkout,
# actions/cache) by exec'ing `node` inside this image, so the runtime must be
# baked in. The SHA256 is published in the release's SHASUMS256.txt.
ARG NODE_VERSION=22.20.0
ARG NODE_ARCHIVE=node-v22.20.0-linux-x64.tar.xz
ARG NODE_SHA256=00bbd05e306ea68b6e13e17360d0e2f680b493ef95f2fea1c4296ff7437530bc

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
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
        "build-tools;${ANDROID_BUILD_TOOLS}"

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

# Sanity check that the toolchain is wired up.
RUN flutter doctor -v
