# GitHub Copilot Configuration

This directory contains configuration files for GitHub Copilot to ensure consistent code generation practices.

## Files

### `copilot-instructions.md`
Complete instructions for GitHub Copilot on how to handle localization in the TeamSync project.

**What it covers:**
- Localization requirements for all user-facing strings
- How to use AppLocalizations
- Adding keys to ARB files for all 6 supported languages
- Common patterns and examples
- Testing procedures

## How Copilot Uses These Instructions

GitHub Copilot automatically reads the `copilot-instructions.md` file and uses it as context when generating code suggestions. This ensures that:

1. **All generated UI code uses localization** - Copilot will suggest `Text(loc.keyName)` instead of hardcoded strings
2. **ARB files are updated** - When adding new features, Copilot knows to add translations to all language files
3. **Consistent patterns** - Code follows the established localization patterns

## Supported Languages

The app supports 6 languages with complete translations:
- 🇺🇸 English (en) - Default/Template
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇩🇪 German (de)
- 🇮🇹 Italian (it)
- 🇧🇷 Portuguese (pt) - Brazilian variant

## Quick Reference

When adding new user-facing text:

1. **Add to all 6 ARB files** (`lib/l10n/app_*.arb`)
2. **Run localization generator**: `flutter gen-l10n`
3. **Use in code**: `Text(loc.keyName)`
4. **Test in multiple languages**

## Additional Resources

- **`/LOCALIZATION_GUIDE.md`** - Quick reference guide
- **`/LOCALIZATION_TEMPLATE.md`** - Templates and translation patterns
- **`/scripts/check-localization.sh`** - Script to check for hardcoded strings

## Updating Instructions

If you need to update the Copilot instructions:

1. Edit `copilot-instructions.md`
2. Keep it focused on actionable rules
3. Include examples for common scenarios
4. Test that Copilot follows the new instructions

## Note for Developers

These instructions are primarily for GitHub Copilot, but they also serve as documentation for developers. When writing code manually, please follow the same guidelines to maintain consistency.

