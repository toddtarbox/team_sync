#!/bin/bash
# Quick setup for GitHub Copilot CLI integration

set -e

echo "🚀 GitHub Copilot CLI Setup for Smart Commits"
echo "=============================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "📦 Install GitHub CLI:"
    echo "   macOS:    brew install gh"
    echo "   Linux:    See https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo "   Windows:  See https://github.com/cli/cli#installation"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI is installed"

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "🔐 Not authenticated with GitHub"
    echo "   Running: gh auth login"
    echo ""
    gh auth login
fi

echo "✅ Authenticated with GitHub"

# Check if Copilot extension is installed
if ! gh extension list | grep -q "github/gh-copilot"; then
    echo "📦 Installing GitHub Copilot CLI extension..."
    gh extension install github/gh-copilot

    if [ $? -eq 0 ]; then
        echo "✅ Copilot CLI extension installed"
    else
        echo "❌ Failed to install Copilot CLI extension"
        exit 1
    fi
else
    echo "✅ Copilot CLI extension already installed"
fi

# Verify Copilot is working
echo ""
echo "🧪 Testing Copilot CLI..."
if gh copilot --version &> /dev/null; then
    echo "✅ Copilot CLI is working!"
    gh copilot --version
else
    echo "❌ Copilot CLI test failed"
    echo ""
    echo "This might mean:"
    echo "  - You don't have GitHub Copilot access"
    echo "  - The extension needs to be updated"
    echo ""
    echo "Try: gh extension upgrade gh-copilot"
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "✨ You can now use AI-powered commit messages:"
echo "   commit          # Use the smart commit script"
echo ""
echo "💡 The commit script will automatically use Copilot when available"
echo ""
echo "📚 See docs/COPILOT_COMMIT_INTEGRATION.md for full documentation"

