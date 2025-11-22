#!/bin/bash
# Quick setup for convenient aliases

# Get the absolute path to the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SHELL_RC=""

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  echo "Unknown shell. Please add aliases manually."
  exit 1
fi

echo "🔧 Setting up convenient aliases in $SHELL_RC"
echo "📁 Project root: $PROJECT_ROOT"
echo ""

# Remove old aliases if they exist
sed -i.bak '/alias commit=/d' "$SHELL_RC" 2>/dev/null
sed -i.bak '/alias build=/d' "$SHELL_RC" 2>/dev/null
rm -f "$SHELL_RC.bak"

# Add new aliases with absolute paths
echo "alias commit='$PROJECT_ROOT/scripts/smart-commit.sh'" >> "$SHELL_RC"
echo "✅ Added 'commit' alias"

echo "alias build='$PROJECT_ROOT/scripts/quick-build.sh'" >> "$SHELL_RC"
echo "✅ Added 'build' alias"

echo ""
echo "🎉 Aliases configured!"
echo ""
echo "📝 Added aliases:"
echo "   commit - Run smart-commit.sh"
echo "   build  - Run quick-build.sh"
echo ""
echo "⚡ To use immediately, run:"
echo "   source $SHELL_RC"
echo ""
echo "Or open a new terminal window."

