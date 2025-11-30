#!/bin/bash
# Quick wrapper for bump-and-build script with common scenarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 TeamSync Quick Build${NC}"
echo ""
echo "Choose a build type:"
echo ""
echo -e "  ${GREEN}1${NC} - Patch (bug fix)          - 1.7.9 → 1.7.10"
echo -e "  ${GREEN}2${NC} - Minor (new features)     - 1.7.9 → 1.8.0"
echo -e "  ${GREEN}3${NC} - Major (breaking changes) - 1.7.9 → 2.0.0"
echo -e "  ${GREEN}4${NC} - Build only (rebuild)     - 1.7.9+76 → 1.7.9+77"
echo ""
read -p "$(echo -e ${YELLOW}Enter choice [1-4]: ${NC})" -n 1 -r
echo ""

case $REPLY in
  1)
    exec "$SCRIPT_DIR/bump-and-build.sh" patch
    ;;
  2)
    exec "$SCRIPT_DIR/bump-and-build.sh" minor
    ;;
  3)
    exec "$SCRIPT_DIR/bump-and-build.sh" major
    ;;
  4)
    exec "$SCRIPT_DIR/bump-and-build.sh" build-only
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

