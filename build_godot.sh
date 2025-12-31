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

# Check dependencies
echo -e "\n${BLUE}Checking dependencies...${NC}"

# Check Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode Command Line Tools not found"
    echo "Please install with: xcode-select --install"
    exit 1
fi
print_status "Xcode Command Line Tools installed"

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
scons platform=macos \
    target=editor \
    arch=arm64 \
    use_volk=yes \
    vulkan_sdk_path="" \
    -j$NUM_CORES

if [ $? -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_status "Build completed successfully!"

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
