ARG BASE_TAG=bookworm
FROM mcr.microsoft.com/vscode/devcontainers/base:dev-${BASE_TAG}

# Install prerequisites for Flutter and Android development
RUN apt-get update -qq \
  && apt-get -yqq upgrade \
  && apt-get install -yqq \
  clang \
  cmake \
  lib32z1 \
  libbz2-1.0:amd64 \
  libc6:amd64 \
  libglu1-mesa \
  libgtk-3-dev \
  libstdc++6:amd64 \
  ninja-build \
  openjdk-17-jdk-headless \
  pkg-config \
  usbutils

# Install latest stable Flutter SDK
ARG FLUTTER_CHANNEL=stable

ENV PATH="$PATH:/opt/flutter/bin"
RUN export FLUTTER_RELEASES_URL=https://storage.googleapis.com/flutter_infra_release/releases \
  && curl -sS "${FLUTTER_RELEASES_URL}/releases_linux.json" \
  | jq -r ". as \$r | \$r.releases[] | select(.hash == \$r.current_release.stable) | (\"${FLUTTER_RELEASES_URL}/\" + .archive)" \
  | xargs -I {} curl -sS {} \
  | tar -xJC /opt


USER vscode

# Install Android SDK
ARG ANDROID_CMDLINE_TOOLS_VERSION=12266719
ARG ANDROID_PLATFORM_VERSION=35
ARG ANDROID_BUILD_TOOLS_VERSION=35.0.0

ENV PATH="$PATH:/home/vscode/Android/Sdk/cmdline-tools/latest/bin:/home/vscode/Android/Sdk/platform-tools"
RUN curl -sS "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
  -o /tmp/cmdline-tools.zip \
  && mkdir -p ~/Android/Sdk/cmdline-tools \
  && unzip -q /tmp/cmdline-tools.zip -d ~/Android/Sdk/cmdline-tools \
  && mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest \
  && rm /tmp/cmdline-tools.zip

# Install required Android SDK components
RUN yes | sdkmanager --licenses \
  && sdkmanager \
  "platforms;android-${ANDROID_PLATFORM_VERSION}" \
  "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
  "platform-tools"

RUN echo 'alias ll="ls -alF"' >> ~/.bashrc \
  && flutter config --no-analytics \
  && flutter precache
