#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  filey build script  –  Arch Linux
#  Usage:  ./build.sh [release|debug]
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

MODE="${1:-release}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$SCRIPT_DIR/core"
APP_DIR="$SCRIPT_DIR/flutter_app"

# Standard Arch Colors for better feedback
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Filey Build  ·  mode: $MODE             ${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

# ── 1. Check Dependencies ────────────────────────────────────────
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: flutter not found in PATH."
    exit 1
fi

# ── 2. Build C++ shared library ──────────────────────────────────
echo -e "\n▶  Building libfiley_core.so..."
g++ -std=c++17 -O2 -fPIC -shared \
    -I"$CORE_DIR/include" \
    "$CORE_DIR/src/filey_project.cpp" \
    "$CORE_DIR/src/filey_ffi.cpp" \
    -o "$CORE_DIR/libfiley_core.so"
echo -e "   ${GREEN}✓${NC} $CORE_DIR/libfiley_core.so"

# ── 3. Run CLI smoke test ────────────────────────────────────────
echo -e "\n▶  Running C++ smoke tests..."
g++ -std=c++17 -O2 \
    -I"$CORE_DIR/include" \
    "$CORE_DIR/src/filey_project.cpp" \
    "$CORE_DIR/src/filey_ffi.cpp" \
    "$CORE_DIR/src/filey_cli.cpp" \
    -o "$CORE_DIR/filey_cli"

# Execute smoke test
"$CORE_DIR/filey_cli"
echo -e "   ${GREEN}✓${NC} All C++ tests passed"

# ── 4. Flutter Build ─────────────────────────────────────────────
echo -e "\n▶  Building Flutter Linux app (${MODE})..."
cd "$APP_DIR"
flutter pub get
flutter build linux --"$MODE"

# Define bundle directory based on mode
BUNDLE_DIR="$APP_DIR/build/linux/x64/${MODE}/bundle"

# ── 5. Bundle Shared Library ─────────────────────────────────────
echo -e "\n▶  Bundling libfiley_core.so..."
mkdir -p "$BUNDLE_DIR/lib"
cp "$CORE_DIR/libfiley_core.so" "$BUNDLE_DIR/lib/"
echo -e "   ${GREEN}✓${NC} Copied to $BUNDLE_DIR/lib/libfiley_core.so"

# ── 6. Create portable run script ────────────────────────────────
# Note: Using $ORIGIN allows the loader to find the libs relative to the binary
RUN_SCRIPT="$BUNDLE_DIR/run_filey.sh"
cat > "$RUN_SCRIPT" <<'EOF'
#!/usr/bin/env bash
# Run Filey with the bundled C++ library on the path
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"

# Find the executable name (usually same as project name in pubspec)
EXE_NAME=$(find "$SCRIPT_DIR" -maxdepth 1 -executable -type f -not -name "*.sh" -print -quit)

if [ -f "$EXE_NAME" ]; then
    exec "$EXE_NAME" "$@"
else
    echo "Executable not found in $SCRIPT_DIR"
    exit 1
fi
EOF

chmod +x "$RUN_SCRIPT"

echo -e "\n${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Build complete!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Launch the app: $RUN_SCRIPT"
echo ""