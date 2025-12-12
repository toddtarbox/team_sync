#!/bin/bash
# Check iOS code signing certificates

echo "🔍 Checking iOS Code Signing Certificates..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Your App Configuration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Bundle ID: com.tsquared.teamsync.soccer"
echo "Team ID:   YW585V7K76"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Installed Signing Identities:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
security find-identity -v -p codesigning 2>/dev/null || echo "No valid identities found with private keys"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📜 All Distribution Certificates (may be missing private key):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
security find-certificate -a -c "Apple Distribution" 2>/dev/null | grep "labl" | sed 's/.*"labl"<blob>="\(.*\)"/  \1/'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ What You Need:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Certificate: Apple Distribution (for team YW585V7K76)"
echo "• With private key (must show in 'Installed Signing Identities' above)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Current Issue:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
FOUND_CORRECT=false
security find-identity -v -p codesigning 2>/dev/null | grep -q "YW585V7K76" && FOUND_CORRECT=true

if [ "$FOUND_CORRECT" = true ]; then
  echo "✅ Correct certificate found with private key!"
  echo "   iOS builds should work."
else
  echo "❌ Missing Apple Distribution certificate for team YW585V7K76"
  echo "   OR certificate exists but is missing private key"
  echo ""
  echo "🔧 Fix:"
  echo "   1. Open: open ios/Runner.xcworkspace"
  echo "   2. Xcode → Settings → Accounts"
  echo "   3. Sign in with Apple ID for team YW585V7K76"
  echo "   4. Download certificates: Manage Certificates → + → Apple Distribution"
  echo ""
  echo "   Or see: IOS_CERTIFICATE_FIX.md for detailed instructions"
fi
echo ""

