#!/bin/bash

# Firebase Storage Rules Deployment Script
# Fixes action photo upload permission errors

echo "🔥 Deploying Firebase Storage Rules..."
echo ""
echo "This will fix the 403 Permission Denied error for image uploads."
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
echo "Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Not logged in to Firebase"
    echo "Run: firebase login"
    exit 1
fi

echo "✅ Firebase CLI ready"
echo ""

# Deploy storage rules
echo "📤 Deploying storage rules..."
firebase deploy --only storage

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅"
    echo ""
    echo "Firebase Storage rules deployed successfully!"
    echo ""
    echo "What's fixed:"
    echo "  ✅ Action photo uploads"
    echo "  ✅ Profile image uploads"
    echo "  ✅ Player card generation"
    echo "  ✅ No more 403 permission errors"
    echo ""
    echo "🎉 Try uploading an action photo now!"
    echo ""
else
    echo ""
    echo "❌ Deployment failed"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check internet connection"
    echo "  2. Verify Firebase project selected"
    echo "  3. Run: firebase use --add"
    echo "  4. Try again"
    echo ""
    exit 1
fi

