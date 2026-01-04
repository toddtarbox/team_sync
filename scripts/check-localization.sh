#!/bin/bash
# Pre-commit hook to check for hardcoded strings in Dart files
# Place this in .git/hooks/pre-commit and make it executable

echo "🌍 Checking for hardcoded strings in Dart files..."

# Find all Dart files in lib
DART_FILES=$(find lib -name "*.dart")

if [ -z "$DART_FILES" ]; then
    echo "✅ No Dart files to check"
    exit 0
fi

# Track if we found any issues
FOUND_ISSUES=0

# Pattern to match hardcoded strings in common UI widgets
# This looks for Text('...') or similar patterns that should use localization
for FILE in $DART_FILES; do
    # Skip generated files and test files
    if [[ "$FILE" == *".g.dart" ]] || [[ "$FILE" == *"_test.dart" ]] || [[ "$FILE" == *"/l10n/"* ]]; then
        continue
    fi

    # Check for Text('...') that doesn't use loc.
    HARDCODED=$(grep -n "Text(['\"]" "$FILE" | grep -v "loc\." | grep -v "AppLocalizations" | grep -v "// ignore-localization" || true)

    if [ ! -z "$HARDCODED" ]; then
        if [ $FOUND_ISSUES -eq 0 ]; then
            echo ""
            echo "⚠️  WARNING: Possible hardcoded strings found!"
            echo ""
        fi
        echo "📄 $FILE:"
        echo "$HARDCODED" | sed 's/^/  /'
        echo ""
        FOUND_ISSUES=1
    fi

    # Check for common dialog/snackbar patterns
    DIALOG_HARDCODED=$(grep -n "AlertDialog\|SnackBar\|showDialog" "$FILE" -A 5 | grep "Text(['\"]" | grep -v "loc\." | grep -v "AppLocalizations" | grep -v "// ignore-localization" || true)

    if [ ! -z "$DIALOG_HARDCODED" ]; then
        if [ $FOUND_ISSUES -eq 0 ]; then
            echo ""
            echo "⚠️  WARNING: Possible hardcoded strings in dialogs/snackbars!"
            echo ""
        fi
        echo "📄 $FILE (dialogs/snackbars):"
        echo "$DIALOG_HARDCODED" | sed 's/^/  /'
        echo ""
        FOUND_ISSUES=1
    fi
done

if [ $FOUND_ISSUES -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌍 LOCALIZATION REMINDER:"
    echo ""
    echo "All user-facing strings should be localized!"
    echo ""
    echo "To localize a string:"
    echo "  1. Add key to all ARB files (lib/l10n/app_*.arb)"
    echo "  2. Run: flutter gen-l10n"
    echo "  3. Use: Text(loc.keyName) instead of Text('hardcoded')"
    echo ""
    echo "See LOCALIZATION_GUIDE.md for details"
    echo ""
    echo "To bypass this check for specific lines, add: // ignore-localization"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Commit will proceed, but please review these warnings!"
    echo ""
    # Uncomment the next line to make this a blocking check:
    # exit 1
fi

echo "✅ Localization check complete"
exit 0

