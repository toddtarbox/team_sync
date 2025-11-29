# Localization Guidelines for Copilot

## 🌍 ALL user-facing strings MUST be localized!

### Quick Reference

**1. Import:**
```dart
import 'package:team_sync/l10n/app_localizations.dart';
```

**2. Define in every method that uses strings:**
```dart
final loc = AppLocalizations.of(context)!;
```

**3. Use localized strings:**
```dart
Text(loc.keyName)  // Simple string
Text(loc.keyName(value))  // String with placeholder
```

**4. Add to ALL 6 ARB files:**
- `lib/l10n/app_en.arb` (English)
- `lib/l10n/app_es.arb` (Spanish)  
- `lib/l10n/app_fr.arb` (French)
- `lib/l10n/app_de.arb` (German)
- `lib/l10n/app_it.arb` (Italian)
- `lib/l10n/app_pt.arb` (Portuguese)

**5. Generate localization:**
```bash
flutter gen-l10n
```

### ❌ NEVER DO THIS:
```dart
Text('Save')
const Text('Error occurred')
title: Text('Delete Item')
```

### ✅ ALWAYS DO THIS:
```dart
// 1. Add to all ARB files
"saveButton": "Save",
"errorOccurred": "Error occurred",
"deleteItem": "Delete Item"

// 2. Use in code
Text(loc.saveButton)
Text(loc.errorOccurred)
title: Text(loc.deleteItem)
```

### Strings with Placeholders:
```json
// ARB file
"errorMessage": "Error: {error}",
"@errorMessage": { "placeholders": { "error": {} } }

// Code
Text(loc.errorMessage(e.toString()))
```

## Supported Languages: 🇺🇸 🇪🇸 🇫🇷 🇩🇪 🇮🇹 🇧🇷

See `.github/copilot-instructions.md` for complete documentation.

