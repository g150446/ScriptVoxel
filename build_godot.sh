#!/bin/bash
set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GODOT_VERSION="4.4-stable"
GODOT_REPO="https://github.com/godotengine/godot.git"
VOXEL_REPO="https://github.com/Zylann/godot_voxel.git"
BUILD_DIR="$(pwd)/build"
GODOT_SOURCE_DIR="$BUILD_DIR/godot"
VOXEL_MODULE_DIR="$GODOT_SOURCE_DIR/modules/voxel"
OUTPUT_DIR="$(pwd)"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Godot + Voxel Module Build Script${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

print_status "Running on macOS"

# Display system information
echo -e "\n${BLUE}System Information:${NC}"
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_BUILD=$(sw_vers -buildVersion)
print_info "macOS Version: $MACOS_VERSION (Build $MACOS_BUILD)"

CPU_BRAND=$(sysctl -n machdep.cpu.brand_string)
CPU_ARCH=$(uname -m)
print_info "CPU: $CPU_BRAND ($CPU_ARCH)"

AVAILABLE_SPACE=$(df -h . | tail -n 1 | awk '{print $4}')
print_info "Available disk space: $AVAILABLE_SPACE (Godot build requires ~10GB)"

# Check dependencies
echo -e "\n${BLUE}Checking dependencies...${NC}"

# Check Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode Command Line Tools not found"
    echo "Please install with: xcode-select --install"
    exit 1
fi
XCODE_PATH=$(xcode-select -p)
print_status "Xcode Command Line Tools installed at: $XCODE_PATH"

# Check xcodebuild version
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_status "$XCODE_VERSION"
else
    print_info "xcodebuild not found (Command Line Tools only installation)"
fi

# Check Homebrew
if ! command -v brew &> /dev/null; then
    print_error "Homebrew not found"
    echo "Please install from: https://brew.sh"
    exit 1
fi
print_status "Homebrew installed"

# Check Python 3
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found"
    echo "Installing Python 3 via Homebrew..."
    brew install python3
fi
print_status "Python 3 installed ($(python3 --version))"

# Check SCons
if ! command -v scons &> /dev/null; then
    print_info "SCons not found, installing via pip3..."
    pip3 install scons
fi
print_status "SCons installed ($(scons --version | head -n 1))"

# Create build directory
echo -e "\n${BLUE}Setting up build directory...${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone or update Godot
if [ -d "$GODOT_SOURCE_DIR" ]; then
    print_info "Godot source already exists, updating..."
    cd "$GODOT_SOURCE_DIR"
    git fetch --all --tags
    git checkout "$GODOT_VERSION"
    git pull origin "$GODOT_VERSION" || true
else
    print_info "Cloning Godot source (this may take a while)..."
    git clone --branch "$GODOT_VERSION" --depth 1 "$GODOT_REPO" "$GODOT_SOURCE_DIR"
    cd "$GODOT_SOURCE_DIR"
fi
print_status "Godot source ready ($GODOT_VERSION)"

# Clone or update voxel module
if [ -d "$VOXEL_MODULE_DIR" ]; then
    print_info "Voxel module already exists, updating..."
    cd "$VOXEL_MODULE_DIR"
    git pull
else
    print_info "Cloning voxel module..."
    mkdir -p "$GODOT_SOURCE_DIR/modules"
    git clone "$VOXEL_REPO" "$VOXEL_MODULE_DIR"
fi
print_status "Voxel module ready"

# Build Godot
cd "$GODOT_SOURCE_DIR"
echo -e "\n${BLUE}Building Godot with voxel module...${NC}"
print_info "This will take 30-60 minutes depending on your Mac"
print_info "Build configuration: macOS Editor (tools=yes, target=editor)"

# Detect number of CPU cores for parallel compilation
NUM_CORES=$(sysctl -n hw.ncpu)
print_info "Using $NUM_CORES CPU cores for compilation"

# Build command
echo -e "${YELLOW}Starting build at $(date)${NC}"
scons platform=macos \
    target=editor \
    arch=arm64 \
    use_volk=yes \
    vulkan_sdk_path="" \
    -j$NUM_CORES

BUILD_EXIT_CODE=$?
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    print_error "Build failed with exit code $BUILD_EXIT_CODE"
    echo ""
    echo "Common issues on M4 Macs:"
    echo "1. Update Command Line Tools: xcode-select --install"
    echo "2. Accept Xcode license: sudo xcodebuild -license accept"
    echo "3. Install missing dependencies: brew install pkg-config"
    echo "4. Check build log above for specific errors"
    echo ""
    echo "For detailed logs, run with: bash -x build_godot.sh 2>&1 | tee build_log.txt"
    exit 1
fi

# Verify binary was created
EXPECTED_BINARY="$GODOT_SOURCE_DIR/bin/godot.macos.editor.arm64"
if [ ! -f "$EXPECTED_BINARY" ]; then
    print_error "Build reported success but binary not found at: $EXPECTED_BINARY"
    echo "Available files in bin/:"
    ls -lh "$GODOT_SOURCE_DIR/bin/" || echo "bin/ directory not found"
    exit 1
fi

print_status "Build completed successfully!"
echo -e "${YELLOW}Build finished at $(date)${NC}"
print_info "Binary size: $(du -sh "$EXPECTED_BINARY" | cut -f1)"

# Create .app bundle
echo -e "\n${BLUE}Creating application bundle...${NC}"

APP_NAME="Godot_Voxel.app"
APP_PATH="$OUTPUT_DIR/$APP_NAME"

# Remove old bundle if exists
rm -rf "$APP_PATH"

# Create bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy binary
cp "$GODOT_SOURCE_DIR/bin/godot.macos.editor.arm64" "$APP_PATH/Contents/MacOS/Godot"
chmod +x "$APP_PATH/Contents/MacOS/Godot"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Godot</string>
    <key>CFBundleIdentifier</key>
    <string>org.godotengine.godot</string>
    <key>CFBundleName</key>
    <string>Godot_Voxel</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$GODOT_VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Verify app bundle was created
if [ ! -d "$APP_PATH" ]; then
    print_error "Failed to create application bundle at: $APP_PATH"
    exit 1
fi

if [ ! -f "$APP_PATH/Contents/MacOS/Godot" ]; then
    print_error "Application bundle created but executable missing"
    exit 1
fi

print_status "Application bundle created: $APP_PATH"

# Print summary
echo -e "\n${GREEN}=================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo -e "Binary location: ${BLUE}$APP_PATH${NC}"
echo -e "Binary size: $(du -sh "$APP_PATH" | cut -f1)"
echo ""
echo -e "To run the editor:"
echo -e "  ${YELLOW}open $APP_PATH${NC}"
echo ""
echo -e "To run from command line:"
echo -e "  ${YELLOW}$APP_PATH/Contents/MacOS/Godot --editor${NC}"
echo ""
echo -e "To open your project:"
echo -e "  ${YELLOW}$APP_PATH/Contents/MacOS/Godot --editor $(pwd)/project/project.godot${NC}"
echo ""
