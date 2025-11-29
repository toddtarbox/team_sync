# GitHub Copilot Instructions for TeamSync Project

## Localization Requirements

### CRITICAL: All user-facing strings MUST be localized

When generating any new code, features, or UI elements, **ALWAYS** follow these localization rules:

### 1. Import Localization
Every widget file that displays user-facing text MUST import:
```dart
import 'package:team_sync/l10n/app_localizations.dart';
```

### 2. Use Localization Variable
In every widget's `build` method or helper method that uses strings, define:
```dart
final loc = AppLocalizations.of(context)!;
```

### 3. NEVER Use Hardcoded Strings
❌ **WRONG:**
```dart
Text('Save')
Text('Error: Something went wrong')
const Text('Settings')
title: const Text('Delete Item')
```

✅ **CORRECT:**
```dart
Text(loc.save)
Text(loc.errorMessage(error.toString()))
Text(loc.settings)
title: Text(loc.deleteItem)
```

### 4. Add New Keys to ALL ARB Files
When creating a new user-facing string, you MUST add it to ALL 6 language files:

**Required Files:**
1. `lib/l10n/app_en.arb` - English (template)
2. `lib/l10n/app_es.arb` - Spanish
3. `lib/l10n/app_fr.arb` - French
4. `lib/l10n/app_de.arb` - German
5. `lib/l10n/app_it.arb` - Italian
6. `lib/l10n/app_pt.arb` - Portuguese (Brazilian)

**Example for simple string:**
```json
// app_en.arb
"saveButton": "Save"

// app_es.arb
"saveButton": "Guardar"

// app_fr.arb
"saveButton": "Enregistrer"

// app_de.arb
"saveButton": "Speichern"

// app_it.arb
"saveButton": "Salva"

// app_pt.arb
"saveButton": "Salvar"
```

**Example for string with placeholder:**
```json
// app_en.arb
"errorMessage": "Error: {error}",
"@errorMessage": { "placeholders": { "error": {} } }

// app_es.arb
"errorMessage": "Error: {error}"

// app_fr.arb
"errorMessage": "Erreur : {error}"

// app_de.arb
"errorMessage": "Fehler: {error}"

// app_it.arb
"errorMessage": "Errore: {error}"

// app_pt.arb
"errorMessage": "Erro: {error}"
```

### 5. Using Localized Strings

**Simple strings:**
```dart
Text(loc.save)
AppBar(title: Text(loc.settings))
ElevatedButton(child: Text(loc.continueButton))
```

**Strings with placeholders (these become methods):**
```dart
// Use the generated method with the parameter
Text(loc.errorMessage(error.toString()))
Text(loc.welcomeUser(userName))
SnackBar(content: Text(loc.itemDeleted(itemName)))
```

**Building strings dynamically:**
```dart
// For "Currently: English" type strings
Text('${loc.currently}: ${_getLocaleName(languageCode)}')
```

### 6. Scoping Rules
- `loc` variable must be defined in the scope where it's used
- If using in a builder function, define `loc` inside the builder
- If using in multiple methods, define `loc` in each method

**Example with dialog:**
```dart
showDialog(
  context: context,
  builder: (context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.confirmDelete),
      content: Text(loc.deleteConfirmationMessage),
      actions: [
        TextButton(
          child: Text(loc.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(loc.delete),
          onPressed: () => _handleDelete(),
        ),
      ],
    );
  },
);
```

### 7. After Adding New Keys
Always run the localization generator:
```bash
flutter gen-l10n
```

This generates the Dart classes from ARB files.

### 8. Naming Conventions for Keys

Use camelCase for key names:
- ✅ `saveButton`, `errorMessage`, `deleteConfirmation`
- ❌ `save_button`, `error-message`, `DeleteConfirmation`

Be descriptive and specific:
- ✅ `deleteAccomplishmentConfirmation`
- ❌ `confirmation`, `message`

Group related keys with prefixes:
- `error...`: `errorMessage`, `errorLoadingData`, `errorSavingFile`
- `...Button`: `saveButton`, `cancelButton`, `deleteButton`

### 9. Common Patterns

**Dialog titles and actions:**
```dart
// Add to ARB files
"deleteItem": "Delete Item",
"deleteItemConfirmation": "Are you sure you want to delete this item?",
"cancel": "Cancel",
"delete": "Delete"

// Use in code
AlertDialog(
  title: Text(loc.deleteItem),
  content: Text(loc.deleteItemConfirmation),
  actions: [
    TextButton(child: Text(loc.cancel), ...),
    TextButton(child: Text(loc.delete), ...),
  ],
)
```

**Snackbar messages:**
```dart
// Add to ARB files
"itemSavedSuccessfully": "Item saved successfully",
"errorSavingItem": "Error saving item: {error}"

// Use in code
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(loc.itemSavedSuccessfully)),
);

// With error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(loc.errorSavingItem(e.toString()))),
);
```

**Form labels and hints:**
```dart
// Add to ARB files
"nameLabel": "Name",
"nameHint": "Enter your name",
"emailLabel": "Email",
"emailHint": "user@example.com"

// Use in code
TextField(
  decoration: InputDecoration(
    labelText: loc.nameLabel,
    hintText: loc.nameHint,
  ),
)
```

### 10. Testing Localization

Test that strings display correctly in all languages:
1. Go to Settings → Language
2. Select each language (English, Spanish, French, German, Italian, Portuguese)
3. Navigate through the new feature
4. Verify all text displays correctly

### 11. Don't Localize These

**DO NOT** localize:
- Technical identifiers (IDs, keys, database field names)
- URLs and email addresses
- Code/error codes
- Format strings used only internally
- Debug/log messages (but DO localize user-visible error messages)

### 12. Supported Languages

The app currently supports:
1. 🇺🇸 English (en) - Default/Template language
2. 🇪🇸 Spanish (es)
3. 🇫🇷 French (fr)
4. 🇩🇪 German (de)
5. 🇮🇹 Italian (it)
6. 🇧🇷 Portuguese (pt) - Brazilian variant

## Quick Checklist for New Features

Before committing code with new UI elements:

- [ ] All user-facing strings moved to ARB files
- [ ] Keys added to all 6 language files (en, es, fr, de, it, pt)
- [ ] Ran `flutter gen-l10n` to generate localization classes
- [ ] Used `loc.*` instead of hardcoded strings in code
- [ ] Tested in at least 2-3 different languages
- [ ] No hardcoded Text('...') strings remain
- [ ] Dialog titles, buttons, and messages localized
- [ ] Form labels and hints localized
- [ ] Error messages localized
- [ ] Success messages localized
- [ ] Tooltips localized

## Examples of Well-Localized Code

### Good Example 1: Menu Item
```dart
// ARB files (add to all 6)
"records": "Records"

// Dart code
PopupMenuItem<String>(
  value: 'records',
  child: Row(
    children: [
      const Icon(Icons.leaderboard),
      const SizedBox(width: 12),
      Text(loc.records),
    ],
  ),
),
```

### Good Example 2: Error Handling
```dart
// ARB files (add to all 6)
"errorLoadingData": "Error loading data: {error}",
"@errorLoadingData": { "placeholders": { "error": {} } }

// Dart code
} catch (e) {
  if (mounted) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.errorLoadingData(e.toString())),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
```

### Good Example 3: Confirmation Dialog
```dart
// ARB files (add to all 6)
"deleteConfirmation": "Delete Confirmation",
"deleteItemQuestion": "Are you sure you want to delete this item?",
"cancel": "Cancel",
"delete": "Delete"

// Dart code
Future<bool?> _showDeleteConfirmation() async {
  final loc = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc.deleteConfirmation),
      content: Text(loc.deleteItemQuestion),
      actions: [
        TextButton(
          child: Text(loc.cancel),
          onPressed: () => Navigator.pop(context, false),
        ),
        TextButton(
          child: Text(loc.delete),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
}
```

## Summary

**REMEMBER:** Every time you generate code that displays text to users:
1. ✅ Add keys to ALL 6 ARB files
2. ✅ Import AppLocalizations
3. ✅ Define `loc` variable
4. ✅ Use `loc.*` not hardcoded strings
5. ✅ Run `flutter gen-l10n`
6. ✅ Test in multiple languages

**Localization is NOT optional - it's a requirement for every user-facing string!**

