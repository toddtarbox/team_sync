# Localization System Documentation

## Overview

TeamSync is fully localized and supports 6 languages. This document provides a complete overview of the localization system and how to maintain it.

## Supported Languages

| Language | Code | Flag | Status | Native Speakers |
|----------|------|------|--------|----------------|
| English | en | 🇺🇸 | Template | ~400M+ |
| Spanish | es | 🇪🇸 | Complete | ~500M+ |
| French | fr | 🇫🇷 | Complete | ~300M+ |
| German | de | 🇩🇪 | Complete | ~100M+ |
| Italian | it | 🇮🇹 | Complete | ~85M+ |
| Portuguese | pt | 🇧🇷 | Complete | ~260M+ |

**Total Potential Reach: 1.6+ Billion People**

## Architecture

### File Structure

```
team_sync/
├── lib/
│   └── l10n/
│       ├── app_en.arb          # English (template)
│       ├── app_es.arb          # Spanish translations
│       ├── app_fr.arb          # French translations
│       ├── app_de.arb          # German translations
│       ├── app_it.arb          # Italian translations
│       ├── app_pt.arb          # Portuguese translations
│       ├── app_localizations.dart         # Generated
│       ├── app_localizations_en.dart      # Generated
│       ├── app_localizations_es.dart      # Generated
│       ├── app_localizations_fr.dart      # Generated
│       ├── app_localizations_de.dart      # Generated
│       ├── app_localizations_it.dart      # Generated
│       └── app_localizations_pt.dart      # Generated
├── .github/
│   ├── copilot-instructions.md  # Copilot configuration
│   └── README.md                # Copilot documentation
├── scripts/
│   └── check-localization.sh    # Pre-commit hook script
├── LOCALIZATION_GUIDE.md         # Quick reference
├── LOCALIZATION_TEMPLATE.md      # Translation templates
└── l10n.yaml                     # Localization config
```

### How It Works

1. **ARB Files** - JSON files containing key-value pairs for each language
2. **Code Generation** - Flutter generates Dart classes from ARB files
3. **Runtime Selection** - App automatically uses device language or user selection
4. **Type Safety** - All localization keys are type-checked at compile time

### Language Selection

Users can:
- Use system default language (auto-detects device language)
- Manually select from 6 supported languages in Settings
- Selection persists across app restarts

## Developer Workflow

### Adding a New String

**Step 1: Add to English ARB (template)**
```json
// lib/l10n/app_en.arb
{
  "myNewKey": "My new text",
  // ... other keys
}
```

**Step 2: Add to all other ARB files**
```json
// app_es.arb
"myNewKey": "Mi nuevo texto"

// app_fr.arb
"myNewKey": "Mon nouveau texte"

// app_de.arb
"myNewKey": "Mein neuer Text"

// app_it.arb
"myNewKey": "Il mio nuovo testo"

// app_pt.arb
"myNewKey": "Meu novo texto"
```

**Step 3: Generate Dart classes**
```bash
flutter gen-l10n
```

**Step 4: Use in code**
```dart
import 'package:team_sync/l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Text(loc.myNewKey);
  }
}
```

### Adding Strings with Placeholders

**ARB files:**
```json
// app_en.arb
{
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "placeholders": {
      "name": {}
    }
  }
}

// app_es.arb
{
  "welcomeUser": "¡Bienvenido, {name}!"
}

// ... add to all languages
```

**Usage:**
```dart
Text(loc.welcomeUser(userName))
```

## Configuration Files

### `l10n.yaml`
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### Main App Configuration
```dart
MaterialApp(
  locale: localeNotifier.locale,  // User's selected locale
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

## Copilot Integration

### Automatic Code Generation

GitHub Copilot reads `.github/copilot-instructions.md` and automatically:
- Suggests localized strings instead of hardcoded text
- Reminds to add translations to all language files
- Follows established patterns

### Example

When you type:
```dart
Text('Hello')
```

Copilot suggests:
```dart
Text(loc.hello)
```

And reminds you to add to ARB files.

## Quality Assurance

### Pre-Commit Hook

Install the localization check:
```bash
cp scripts/check-localization.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

This checks for hardcoded strings before each commit.

### Manual Testing

1. **Settings → Language**
2. **Select each language**
3. **Navigate through all features**
4. **Verify text displays correctly**

### Automated Testing

Run the analyzer:
```bash
dart analyze lib/
```

Check for hardcoded strings:
```bash
./scripts/check-localization.sh
```

## Common Patterns

### Dialog
```dart
showDialog(
  context: context,
  builder: (context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.confirmTitle),
      content: Text(loc.confirmMessage),
      actions: [
        TextButton(
          child: Text(loc.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(loc.confirm),
          onPressed: () => _doAction(),
        ),
      ],
    );
  },
);
```

### SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(loc.savedSuccessfully)),
);
```

### Error Handling
```dart
try {
  // ... operation
} catch (e) {
  if (mounted) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.errorMessage(e.toString()))),
    );
  }
}
```

### Form Fields
```dart
TextField(
  decoration: InputDecoration(
    labelText: loc.emailLabel,
    hintText: loc.emailHint,
  ),
)
```

## Maintenance

### Adding a New Language

To add a new language (e.g., Japanese):

1. Create `lib/l10n/app_ja.arb`
2. Copy all keys from `app_en.arb`
3. Translate all values to Japanese
4. Run `flutter gen-l10n`
5. Test the new language

### Updating Translations

1. Locate the key in all ARB files
2. Update the translation
3. Run `flutter gen-l10n`
4. Test changes

### Finding Missing Keys

```bash
# Compare key counts
wc -l lib/l10n/app_*.arb
```

All files should have similar line counts.

## Best Practices

### ✅ DO:
- Add keys to ALL language files simultaneously
- Use descriptive, semantic key names (e.g., `deleteConfirmation`)
- Group related keys with prefixes (e.g., `error*`, `*Button`)
- Test in multiple languages before committing
- Use placeholders for dynamic values
- Run `flutter gen-l10n` after adding keys

### ❌ DON'T:
- Hardcode user-facing strings
- Use technical terms as keys (e.g., `btn1`, `msg2`)
- Forget to translate for all languages
- Use `const` with localized Text widgets
- Localize technical identifiers or debug logs

## Troubleshooting

### Localization not updating
```bash
flutter clean
flutter pub get
flutter gen-l10n
```

### Missing translation at runtime
- Check ARB files have the key
- Verify `flutter gen-l10n` was run
- Restart the app

### Copilot not suggesting localization
- Check `.github/copilot-instructions.md` exists
- Reload VS Code/IDE
- Verify Copilot is enabled

## Statistics

**Current Coverage:**
- Total localization keys: ~270+
- Total translations: ~1,620 (270 × 6 languages)
- Files using localization: 30+
- Languages supported: 6

## Resources

- **Quick Reference**: `LOCALIZATION_GUIDE.md`
- **Templates**: `LOCALIZATION_TEMPLATE.md`
- **Copilot Config**: `.github/copilot-instructions.md`
- **Check Script**: `scripts/check-localization.sh`

## Support

For questions or issues with localization:
1. Check this documentation
2. Review example code in existing widgets
3. Run the localization check script
4. Test in multiple languages

---

**Last Updated:** November 2025
**Maintained By:** TeamSync Development Team

