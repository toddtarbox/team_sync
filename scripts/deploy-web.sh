#!/bin/bash
# Deploy Flutter web to Firebase Hosting
# Usage: ./scripts/deploy-web.sh [soccer|basketball|all] [firebase-options]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🚀 TeamSync Web Deployment${NC}"
echo "================================================"

# Determine target (default to soccer)
TARGET_SPORT=${1:-"soccer"}
shift || true # Remove first arg if it exists

# Function to deploy a specific sport
deploy_sport() {
  local sport=$1
  shift # Remove sport name from arguments
  local hosting_site="team-sync-$sport"
  local app_name="TeamSync $sport"
  
  echo -e "${BLUE}🏆 Deploying $app_name...${NC}"
  
  echo ""
  echo -e "${YELLOW}🔨 Building $app_name web...${NC}"
  "$SCRIPT_DIR/build.sh" web "$sport"

  echo ""
  echo -e "${YELLOW}🚀 Deploying $app_name to Firebase hosting site: $hosting_site...${NC}"
  cd "$PROJECT_ROOT"

  # Ensure we're using the correct Firebase project
  firebase use team-sync-soccer

  # Deploy to the specific hosting target
  if [ $# -eq 0 ]; then
    firebase deploy --only hosting:$hosting_site
  else
    firebase deploy --only hosting:$hosting_site "$@"
  fi

  echo ""
  echo -e "${GREEN}✅ $app_name deployment complete!${NC}"
}

# Execute based on target
case $TARGET_SPORT in
  soccer)
    deploy_sport "soccer" "$@"
    ;;
  basketball)
    deploy_sport "basketball" "$@"
    ;;
  all)
    echo -e "${YELLOW}Deploying both Soccer and Basketball apps...${NC}"
    deploy_sport "soccer" "$@"
    echo "------------------------------------------------"
    deploy_sport "basketball" "$@"
    ;;
  *)
    echo -e "${RED}❌ Unknown target: $TARGET_SPORT${NC}"
    echo "Usage: $0 [soccer|basketball|all] [firebase-options]"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}🎉 Web deployment process finished!${NC}"
