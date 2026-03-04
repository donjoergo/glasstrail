#!/usr/bin/env bash
set -euo pipefail

# Run this from the repo root: /workspace/glasstrail (or equivalent)
REPO_DIR="${REPO_DIR:-$(pwd)}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
# Optional tag/branch/commit override, e.g. FLUTTER_REF=3.35.1
FLUTTER_REF="${FLUTTER_REF:-}"
RUN_CHECKS="${RUN_CHECKS:-true}"

if [ -z "${FLUTTER_ROOT:-}" ]; then
  FLUTTER_ROOT="$HOME/.local/flutter"
fi

if [ ! -f "$REPO_DIR/pubspec.yaml" ]; then
  echo "pubspec.yaml not found in $REPO_DIR. Run this in the glasstrail repo root."
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

export DEBIAN_FRONTEND=noninteractive

as_root() {
  if [ -n "$SUDO" ]; then
    "$SUDO" "$@"
  else
    "$@"
  fi
}

if command -v apt-get >/dev/null 2>&1 && \
  ( [ "$(id -u)" -eq 0 ] || [ -n "$SUDO" ] ); then
  as_root apt-get update
  as_root apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev
else
  echo "Skipping apt package install (no apt-get or no root/sudo access)."
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not installed."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not installed."
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required but not installed."
  exit 1
fi

if [ ! -d "$FLUTTER_ROOT/bin" ]; then
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  rm -rf "$FLUTTER_ROOT"
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" \
    https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
else
  # Keep existing installs aligned with the requested channel by default.
  git -C "$FLUTTER_ROOT" fetch --depth 1 origin "$FLUTTER_CHANNEL"
  git -C "$FLUTTER_ROOT" checkout -B "$FLUTTER_CHANNEL" \
    "origin/$FLUTTER_CHANNEL"
fi

if [ -n "$FLUTTER_REF" ]; then
  git -C "$FLUTTER_ROOT" fetch --depth 1 origin "$FLUTTER_REF"
  git -C "$FLUTTER_ROOT" checkout "$FLUTTER_REF"
fi

GLASSTRAIL_ENV_DIR="$HOME/.config/glasstrail"
GLASSTRAIL_FLUTTER_ENV_FILE="$GLASSTRAIL_ENV_DIR/flutter_env.sh"

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/flutter" <<EOF
#!/usr/bin/env bash
set -euo pipefail
FLUTTER_ROOT="\${FLUTTER_ROOT:-$FLUTTER_ROOT}"
ENV_FILE="\$HOME/.config/glasstrail/flutter_env.sh"
if [ -f "\$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  . "\$ENV_FILE"
fi
exec "\$FLUTTER_ROOT/bin/flutter" "\$@"
EOF
chmod +x "$HOME/.local/bin/flutter"

export PATH="$HOME/.local/bin:$FLUTTER_ROOT/bin:$PATH"

# Make Flutter available in future shells
if ! grep -q 'FLUTTER_ROOT=' ~/.bashrc 2>/dev/null; then
  {
    echo ""
    echo "export FLUTTER_ROOT=\"$FLUTTER_ROOT\""
    echo "export PATH=\"\$HOME/.local/bin:\$FLUTTER_ROOT/bin:\$PATH\""
  } >> ~/.bashrc
fi

if ! grep -q 'FLUTTER_ROOT=' ~/.profile 2>/dev/null; then
  {
    echo ""
    echo "export FLUTTER_ROOT=\"$FLUTTER_ROOT\""
    echo "export PATH=\"\$HOME/.local/bin:\$FLUTTER_ROOT/bin:\$PATH\""
  } >> ~/.profile
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is still not on PATH after install."
  echo "Try: export PATH=\"$HOME/.local/bin:$FLUTTER_ROOT/bin:\$PATH\""
  exit 1
fi

flutter --version
flutter config --no-analytics
flutter config --enable-web

# Pre-download web artifacts so `flutter run -d web-server` works without
# failing later due a blocked first-time download.
if [ -z "${FLUTTER_STORAGE_BASE_URL:-}" ]; then
  rm -f "$GLASSTRAIL_FLUTTER_ENV_FILE"
fi

if ! flutter precache --web; then
  if [ -z "${FLUTTER_STORAGE_BASE_URL:-}" ]; then
    echo "Default Flutter storage blocked. Retrying with flutter-io mirror."
    export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
    export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
    mkdir -p "$GLASSTRAIL_ENV_DIR"
    cat > "$GLASSTRAIL_FLUTTER_ENV_FILE" <<EOF
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
EOF
    flutter precache --web
  else
    echo "flutter precache --web failed with FLUTTER_STORAGE_BASE_URL=$FLUTTER_STORAGE_BASE_URL"
    exit 1
  fi
fi

cd "$REPO_DIR"
flutter pub get
if [ "$RUN_CHECKS" = "true" ]; then
  flutter analyze
  flutter test
fi

echo ""
echo "Setup complete."
echo "Run app (mock): flutter run -d chrome"
echo "Run app (backend): flutter run -d chrome --dart-define=USE_REMOTE_API=true --dart-define=API_BASE_URL=http://localhost:3000"
