#!/bin/bash
# Smart commit script that:
# - Ignores sensitive configuration files
# - Stages all other changes
# - Generates intelligent commit message based on changes
# - Prompts to push to current branch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo -e "${BLUE}🚀 Smart Commit Script${NC}"
echo "================================================"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}❌ Not a git repository${NC}"
  exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${CYAN}Current branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo ""

# List of sensitive files to exclude
SENSITIVE_FILES=(
  "lib/firebase_options.dart"
  "android/app/google-services.json"
  "android/app/src/teamSync/google-services.json"
  "ios/Runner/GoogleService-Info.plist"
  "ios/Runner/Info.plist"
)

echo -e "${YELLOW}🔒 Excluding sensitive files:${NC}"
for file in "${SENSITIVE_FILES[@]}"; do
  echo "   - $file"
done
echo ""

# Check for unstaged changes
if git diff --quiet && git diff --cached --quiet; then
  echo -e "${YELLOW}⚠️  No changes to commit${NC}"
  exit 0
fi

# Reset any previously staged sensitive files
echo -e "${BLUE}📝 Unstaging sensitive files...${NC}"
for file in "${SENSITIVE_FILES[@]}"; do
  if [ -f "$file" ]; then
    git reset HEAD "$file" 2>/dev/null || true
  fi
done

# Add all files except sensitive ones
echo -e "${BLUE}📦 Staging changes...${NC}"
git add .

# Unstage sensitive files again (in case they were added)
for file in "${SENSITIVE_FILES[@]}"; do
  if [ -f "$file" ]; then
    git reset HEAD "$file" 2>/dev/null || true
  fi
done

# Check if there are staged changes
if git diff --cached --quiet; then
  echo -e "${YELLOW}⚠️  No changes to commit (only sensitive files were modified)${NC}"
  exit 0
fi

echo ""
echo -e "${GREEN}✅ Changes staged successfully${NC}"
echo ""

# Show staged files
echo -e "${CYAN}📋 Staged files:${NC}"
git diff --cached --name-status | while IFS=$'\t' read -r status file; do
  case $status in
    A) echo -e "   ${GREEN}+${NC} $file" ;;
    M) echo -e "   ${YELLOW}~${NC} $file" ;;
    D) echo -e "   ${RED}-${NC} $file" ;;
    R*) echo -e "   ${BLUE}→${NC} $file" ;;
    *) echo "   $status $file" ;;
  esac
done
echo ""

# Function to handle push
do_push() {
  echo ""
  echo -e "${YELLOW}🚀 Push to remote?${NC}"
  echo -e "   Branch: ${GREEN}$CURRENT_BRANCH${NC}"
  read -p "$(echo -e "${YELLOW}Push changes? [y/N]: ${NC}")" -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📤 Pushing to $CURRENT_BRANCH...${NC}"

    if git ls-remote --heads origin "$CURRENT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
      git push origin "$CURRENT_BRANCH"
    else
      echo -e "${YELLOW}⚠️  Remote branch doesn't exist, creating...${NC}"
      git push -u origin "$CURRENT_BRANCH"
    fi

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✅ Successfully pushed to origin/$CURRENT_BRANCH${NC}"
    else
      echo -e "${RED}❌ Push failed${NC}"
      exit 1
    fi
  else
    echo -e "${YELLOW}⏭️  Skipped push${NC}"
    echo -e "${CYAN}💡 You can push later with: ${NC}git push origin $CURRENT_BRANCH"
  fi

  echo ""
  echo -e "${GREEN}🎉 Done!${NC}"
  exit 0
}

# Generate commit message based on changes
echo -e "${BLUE}🤖 Generating commit message...${NC}"
echo ""

SUGGESTED_MSG=""

# 1. Try Gemini
if [ -n "$GEMINI_API_KEY" ]; then
  echo -e "${CYAN}✨ Gemini API key detected! Generating AI commit message...${NC}"
  
  DIFF_OUT=$(git diff --cached | head -n 2000)
  
  # output diff to debug if needed
  # echo "$DIFF_OUT" > /tmp/debug_diff.txt

  # Use set +e to prevent script from exiting if python script fails
  set +e
  # Use python3 for robust JSON handling
  GEMINI_Response=$(python3 -c "
import sys, json, urllib.request, os, traceback

try:
    api_key = '$GEMINI_API_KEY'.strip()
    diff = sys.stdin.read().strip()
    if not diff:
        print('')
        sys.exit(0)
        
    url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-001:generateContent?key=' + api_key
    
    prompt = \"Write a concise git commit message for the following diff. Only output the message text. Use standard conventional commits format (feat, fix, refactor, etc). Keep it under 72 chars if possible. Diff:\\n\" + diff

    data = {
        'contents': [{
            'parts': [{'text': prompt}]
        }]
    }

    req = urllib.request.Request(url, json.dumps(data).encode('utf-8'), {'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        print(result['candidates'][0]['content']['parts'][0]['text'].strip())
except urllib.error.HTTPError as e:
    print('HTTP Error ' + str(e.code) + ': ' + str(e.reason), file=sys.stderr)
    try:
        print(e.read().decode('utf-8'), file=sys.stderr)
    except:
        pass
    sys.exit(1)
except Exception:
    # Print error to stderr so it doesn't get captured in the variable but shows in terminal
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
" <<< "$DIFF_OUT")
  
  GEMINI_EXIT_CODE=$?
  set -e

  if [ $GEMINI_EXIT_CODE -eq 0 ] && [ -n "$GEMINI_Response" ]; then
    SUGGESTED_MSG="$GEMINI_Response"
    echo -e "${GREEN}✅ Gemini generated a message!${NC}"
  else
    echo -e "${YELLOW}⚠️  Gemini API call failed or empty. Falling back to template logic.${NC}"
    # check if response was empty but exit code was 0?
  fi
fi

# 2. Fallback to Template if SUGGESTED_MSG is empty
if [ -z "$SUGGESTED_MSG" ]; then
  echo -e "${CYAN}📝 Generating template message...${NC}"

  # Analyze changes
  ADDED_FILES=$(git diff --cached --name-status | grep -E "^A" | wc -l | tr -d ' ')
  MODIFIED_FILES=$(git diff --cached --name-status | grep -E "^M" | wc -l | tr -d ' ')
  DELETED_FILES=$(git diff --cached --name-status | grep -E "^D" | wc -l | tr -d ' ')
  RENAMED_FILES=$(git diff --cached --name-status | grep -E "^R" | wc -l | tr -d ' ')

  # Get list of changed files
  CHANGED_FILES=$(git diff --cached --name-only)

  # Detect what types of changes were made
  HAS_DART=false
  HAS_SCRIPT=false
  HAS_DOCS=false
  HAS_ASSETS=false
  HAS_CONFIG=false
  HAS_IOS=false
  HAS_ANDROID=false
  HAS_WEB=false

  while IFS= read -r file; do
    case $file in
      *.dart) HAS_DART=true ;;
      *.sh|scripts/*) HAS_SCRIPT=true ;;
      *.md|docs/*) HAS_DOCS=true ;;
      assets/*|*.png|*.jpg|*.svg) HAS_ASSETS=true ;;
      pubspec.yaml|*.json|*.yaml) HAS_CONFIG=true ;;
      ios/*) HAS_IOS=true ;;
      android/*) HAS_ANDROID=true ;;
      web/*) HAS_WEB=true ;;
    esac
  done <<< "$CHANGED_FILES"

  # Determine primary action
  if [ $ADDED_FILES -gt 0 ] && [ $MODIFIED_FILES -eq 0 ] && [ $DELETED_FILES -eq 0 ]; then
    COMMIT_MSG="Add"
  elif [ $DELETED_FILES -gt 0 ] && [ $ADDED_FILES -eq 0 ] && [ $MODIFIED_FILES -eq 0 ]; then
    COMMIT_MSG="Remove"
  elif [ $MODIFIED_FILES -gt 0 ] && [ $ADDED_FILES -eq 0 ] && [ $DELETED_FILES -eq 0 ]; then
    COMMIT_MSG="Update"
  elif [ $RENAMED_FILES -gt 0 ]; then
    COMMIT_MSG="Refactor"
  else
    COMMIT_MSG="Update"
  fi

  # Add component info
  COMPONENTS=""
  if [ "$HAS_DART" = true ]; then COMPONENTS="${COMPONENTS}code, "; fi
  if [ "$HAS_SCRIPT" = true ]; then COMPONENTS="${COMPONENTS}scripts, "; fi
  if [ "$HAS_DOCS" = true ]; then COMPONENTS="${COMPONENTS}docs, "; fi
  if [ "$HAS_ASSETS" = true ]; then COMPONENTS="${COMPONENTS}assets, "; fi
  if [ "$HAS_CONFIG" = true ]; then COMPONENTS="${COMPONENTS}config, "; fi
  if [ "$HAS_IOS" = true ]; then COMPONENTS="${COMPONENTS}iOS, "; fi
  if [ "$HAS_ANDROID" = true ]; then COMPONENTS="${COMPONENTS}Android, "; fi
  if [ "$HAS_WEB" = true ]; then COMPONENTS="${COMPONENTS}web, "; fi

  # Remove trailing comma and space
  COMPONENTS=${COMPONENTS%, }

  # Build full commit message
  if [ -n "$COMPONENTS" ]; then
    SUGGESTED_MSG="$COMMIT_MSG $COMPONENTS"
  else
    SUGGESTED_MSG="$COMMIT_MSG files"
  fi

  # Add stats
  STATS=""
  if [ $ADDED_FILES -gt 0 ]; then STATS="${STATS}+$ADDED_FILES "; fi
  if [ $MODIFIED_FILES -gt 0 ]; then STATS="${STATS}~$MODIFIED_FILES "; fi
  if [ $DELETED_FILES -gt 0 ]; then STATS="${STATS}-$DELETED_FILES "; fi

  if [ -n "$STATS" ]; then
    SUGGESTED_MSG="$SUGGESTED_MSG ($STATS)"
  fi
fi

echo ""
echo -e "${CYAN}📝 Suggested commit message:${NC}"
echo -e "${GREEN}   $SUGGESTED_MSG${NC}"
echo ""

# Prompt for commit message
read -p "$(echo -e ${YELLOW}Use this message? [Y/n/edit]: ${NC})" -n 1 -r
echo ""

FINAL_MSG="$SUGGESTED_MSG"

if [[ $REPLY =~ ^[Ee]$ ]]; then
  # Edit mode
  echo -e "${BLUE}Enter your commit message (press Enter when done):${NC}"
  read -r CUSTOM_MSG
  if [ -n "$CUSTOM_MSG" ]; then
    FINAL_MSG="$CUSTOM_MSG"
  fi
elif [[ $REPLY =~ ^[Nn]$ ]]; then
  # Manual entry
  echo -e "${BLUE}Enter your commit message:${NC}"
  read -r CUSTOM_MSG
  if [ -z "$CUSTOM_MSG" ]; then
    echo -e "${RED}❌ Commit message cannot be empty${NC}"
    exit 1
  fi
  FINAL_MSG="$CUSTOM_MSG"
fi

# Commit changes
echo ""
echo -e "${BLUE}💾 Creating commit...${NC}"
git commit -m "$FINAL_MSG"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Commit created successfully!${NC}"

  # Show commit details
  echo ""
  echo -e "${CYAN}📊 Commit details:${NC}"
  git log -1 --stat --color=always | head -20

  do_push
else
  echo -e "${RED}❌ Commit failed${NC}"
  exit 1
fi


