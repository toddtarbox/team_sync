#!/bin/bash
# Bump version/build number and build TeamSync for Android and iOS simultaneously

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"
PID_FILE="$PROJECT_ROOT/build/.build_in_progress.pid"

echo -e "${BLUE}🚀 TeamSync Version Bump & Build${NC}"
echo "================================================"

# Check for ongoing builds
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if ps -p "$OLD_PID" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Found ongoing build (PID: $OLD_PID)${NC}"
    read -p "$(echo -e ${YELLOW}Cancel the ongoing build and start a new one? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}🛑 Cancelling ongoing build...${NC}"
      # Kill the process group to ensure all child processes are terminated
      pkill -TERM -P "$OLD_PID" 2>/dev/null || true
      kill -TERM "$OLD_PID" 2>/dev/null || true
      sleep 2
      # Force kill if still running
      if ps -p "$OLD_PID" > /dev/null 2>&1; then
        pkill -KILL -P "$OLD_PID" 2>/dev/null || true
        kill -KILL "$OLD_PID" 2>/dev/null || true
      fi
      rm -f "$PID_FILE"
      echo -e "${GREEN}✅ Previous build cancelled${NC}"
    else
      echo -e "${RED}❌ Cannot start new build while another is in progress${NC}"
      echo "   Wait for the current build to finish or manually kill PID $OLD_PID"
      exit 1
    fi
  else
    # PID file exists but process is not running (stale file)
    echo -e "${BLUE}ℹ️  Cleaning up stale build lock file${NC}"
    rm -f "$PID_FILE"
  fi
fi

# Create PID file for this build
mkdir -p "$PROJECT_ROOT/build"
echo $$ > "$PID_FILE"

# Cleanup function to remove PID file on exit
cleanup() {
  rm -f "$PID_FILE"
}
trap cleanup EXIT INT TERM

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_FILE" ]; then
  echo -e "${RED}❌ Error: pubspec.yaml not found at $PUBSPEC_FILE${NC}"
  exit 1
fi

# Extract current version and build number
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/.*+//')

echo -e "${YELLOW}Current version: $CURRENT_VERSION+$CURRENT_BUILD${NC}"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Determine bump type (default to patch)
BUMP_TYPE=${1:-patch}

case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  build-only)
    # Don't change version, only bump build number
    ;;
  *)
    echo -e "${RED}❌ Invalid bump type: $BUMP_TYPE${NC}"
    echo "Usage: $0 [major|minor|patch|build-only]"
    echo "  major      - Bump major version (e.g., 1.7.9 -> 2.0.0)"
    echo "  minor      - Bump minor version (e.g., 1.7.9 -> 1.8.0)"
    echo "  patch      - Bump patch version (e.g., 1.7.9 -> 1.7.10) [DEFAULT]"
    echo "  build-only - Only increment build number (e.g., +76 -> +77)"
    exit 1
    ;;
esac

# Always increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))

# Construct new version
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_VERSION_FULL="${NEW_VERSION}+${NEW_BUILD}"

echo -e "${GREEN}New version: $NEW_VERSION_FULL${NC}"

# Prompt for confirmation
read -p "$(echo -e ${YELLOW}Continue with version bump? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Cancelled${NC}"
  exit 1
fi

# Update pubspec.yaml
echo -e "${BLUE}📝 Updating pubspec.yaml...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION_FULL/" "$PUBSPEC_FILE"
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION_FULL/" "$PUBSPEC_FILE"
fi

echo -e "${GREEN}✅ Version updated to $NEW_VERSION_FULL${NC}"

# Create git commit (optional)
read -p "$(echo -e ${YELLOW}Create git commit for version bump? [y/N]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git add "$PUBSPEC_FILE"
  git commit -m "Bump version to $NEW_VERSION_FULL"
  echo -e "${GREEN}✅ Git commit created${NC}"
fi

echo ""
echo -e "${BLUE}🏗️  Starting builds...${NC}"
echo "================================================"

# Create build log directory
BUILD_LOG_DIR="$PROJECT_ROOT/build/logs"
mkdir -p "$BUILD_LOG_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ANDROID_LOG="$BUILD_LOG_DIR/android_${TIMESTAMP}.log"
IOS_LOG="$BUILD_LOG_DIR/ios_${TIMESTAMP}.log"

# Function to build and deploy Android
build_android() {
  echo -e "${BLUE}🤖 Starting Android build...${NC}" | tee "$ANDROID_LOG"
  cd "$PROJECT_ROOT"

  if "$SCRIPT_DIR/build-team-sync.sh" android >> "$ANDROID_LOG" 2>&1; then
    echo -e "${GREEN}✅ Android build completed successfully${NC}"
    echo -e "   Log: $ANDROID_LOG"

    # Automatically deploy to Google Play Internal Test Track
    echo -e "${BLUE}🚀 Auto-deploying to Google Play Internal Test Track...${NC}"
    if "$SCRIPT_DIR/deploy-mobile.sh" android >> "$ANDROID_LOG" 2>&1; then
      echo -e "${GREEN}✅ Android deployment completed successfully${NC}"
    else
      echo -e "${YELLOW}⚠️  Android deployment failed (check log: $ANDROID_LOG)${NC}"
    fi

    return 0
  else
    echo -e "${RED}❌ Android build failed${NC}"
    echo -e "   Check log: $ANDROID_LOG"
    return 1
  fi
}

# Function to build and deploy iOS
build_ios() {
  echo -e "${BLUE}📱 Starting iOS build...${NC}" | tee "$IOS_LOG"
  cd "$PROJECT_ROOT"

  if "$SCRIPT_DIR/build-team-sync.sh" ios >> "$IOS_LOG" 2>&1; then
    echo -e "${GREEN}✅ iOS build completed successfully${NC}"
    echo -e "   Log: $IOS_LOG"

    # Automatically deploy to TestFlight
    echo -e "${BLUE}🚀 Auto-deploying to TestFlight...${NC}"
    if "$SCRIPT_DIR/deploy-mobile.sh" ios >> "$IOS_LOG" 2>&1; then
      echo -e "${GREEN}✅ iOS deployment completed successfully${NC}"
    else
      echo -e "${YELLOW}⚠️  iOS deployment failed (check log: $IOS_LOG)${NC}"
    fi

    return 0
  else
    echo -e "${RED}❌ iOS build failed${NC}"
    echo -e "   Check log: $IOS_LOG"
    return 1
  fi
}

# Run builds in parallel
echo -e "${YELLOW}Running Android and iOS builds simultaneously...${NC}"
echo ""

# Start both builds in background
build_android &
ANDROID_PID=$!

build_ios &
IOS_PID=$!

# Wait for both builds to complete
ANDROID_SUCCESS=0
IOS_SUCCESS=0

wait $ANDROID_PID
ANDROID_EXIT=$?

wait $IOS_PID
IOS_EXIT=$?

echo ""
echo "================================================"
echo -e "${BLUE}📊 Build Summary${NC}"
echo "================================================"
echo -e "Version: ${GREEN}$NEW_VERSION_FULL${NC}"
echo ""

if [ $ANDROID_EXIT -eq 0 ]; then
  echo -e "Android: ${GREEN}✅ SUCCESS${NC}"
  echo "  Output: build/app/outputs/bundle/teamSyncRelease/"
  ANDROID_SUCCESS=1
else
  echo -e "Android: ${RED}❌ FAILED${NC}"
  echo "  Log: $ANDROID_LOG"
fi

if [ $IOS_EXIT -eq 0 ]; then
  echo -e "iOS:     ${GREEN}✅ SUCCESS${NC}"
  echo "  Output: build/ios/ipa/"
  IOS_SUCCESS=1
else
  echo -e "iOS:     ${RED}❌ FAILED${NC}"
  echo "  Log: $IOS_LOG"
fi

echo ""

# Exit with error if any build failed
if [ $ANDROID_SUCCESS -eq 1 ] && [ $IOS_SUCCESS -eq 1 ]; then
  echo -e "${GREEN}🎉 All builds and deployments completed successfully!${NC}"
  exit 0
elif [ $ANDROID_SUCCESS -eq 1 ] || [ $IOS_SUCCESS -eq 1 ]; then
  echo -e "${YELLOW}⚠️  Some builds completed, but some failed${NC}"
  echo -e "${BLUE}ℹ️  Successfully completed platforms were automatically deployed${NC}"
  exit 1
else
  echo -e "${RED}❌ All builds failed${NC}"
  exit 1
fi

