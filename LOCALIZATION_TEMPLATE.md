# Localization Key Template

Use this template when adding new localization keys to the ARB files.

## For Simple Strings

### English (app_en.arb)
```json
"keyName": "English text here"
```

### Spanish (app_es.arb)
```json
"keyName": "Texto en español aquí"
```

### French (app_fr.arb)
```json
"keyName": "Texte français ici"
```

### German (app_de.arb)
```json
"keyName": "Deutscher Text hier"
```

### Italian (app_it.arb)
```json
"keyName": "Testo italiano qui"
```

### Portuguese (app_pt.arb)
```json
"keyName": "Texto em português aqui"
```

---

## For Strings with Placeholders

### English (app_en.arb)
```json
"keyName": "Text with {placeholder}",
"@keyName": { "placeholders": { "placeholder": {} } }
```

### Spanish (app_es.arb)
```json
"keyName": "Texto con {placeholder}"
```

### French (app_fr.arb)
```json
"keyName": "Texte avec {placeholder}"
```

### German (app_de.arb)
```json
"keyName": "Text mit {placeholder}"
```

### Italian (app_it.arb)
```json
"keyName": "Testo con {placeholder}"
```

### Portuguese (app_pt.arb)
```json
"keyName": "Texto com {placeholder}"
```

---

## Common Translation Patterns

### Buttons
| English | Spanish | French | German | Italian | Portuguese |
|---------|---------|--------|--------|---------|------------|
| Save | Guardar | Enregistrer | Speichern | Salva | Salvar |
| Cancel | Cancelar | Annuler | Abbrechen | Annulla | Cancelar |
| Delete | Eliminar | Supprimer | Löschen | Elimina | Excluir |
| Add | Agregar | Ajouter | Hinzufügen | Aggiungi | Adicionar |
| Edit | Editar | Modifier | Bearbeiten | Modifica | Editar |
| Close | Cerrar | Fermer | Schließen | Chiudi | Fechar |
| Confirm | Confirmar | Confirmer | Bestätigen | Conferma | Confirmar |
| Continue | Continuar | Continuer | Weiter | Continua | Continuar |

### Common Words
| English | Spanish | French | German | Italian | Portuguese |
|---------|---------|--------|--------|---------|------------|
| Error | Error | Erreur | Fehler | Errore | Erro |
| Success | Éxito | Succès | Erfolg | Successo | Sucesso |
| Loading | Cargando | Chargement | Wird geladen | Caricamento | Carregando |
| Settings | Configuración | Paramètres | Einstellungen | Impostazioni | Configurações |
| Search | Buscar | Rechercher | Suchen | Cerca | Pesquisar |
| Filter | Filtrar | Filtrer | Filtern | Filtra | Filtrar |
| Sort | Ordenar | Trier | Sortieren | Ordina | Ordenar |
| Name | Nombre | Nom | Name | Nome | Nome |
| Description | Descripción | Description | Beschreibung | Descrizione | Descrição |

### Status Messages
| English | Spanish | French | German | Italian | Portuguese |
|---------|---------|--------|--------|---------|------------|
| Successfully saved | Guardado con éxito | Enregistré avec succès | Erfolgreich gespeichert | Salvato con successo | Salvo com sucesso |
| Failed to load | Error al cargar | Échec du chargement | Fehler beim Laden | Caricamento fallito | Falha ao carregar |
| No data available | No hay datos disponibles | Aucune donnée disponible | Keine Daten verfügbar | Nessun dato disponibile | Nenhum dado disponível |
| Please wait | Por favor espere | Veuillez patienter | Bitte warten | Attendere prego | Por favor aguarde |

### Questions/Confirmations
| English | Spanish | French | German | Italian | Portuguese |
|---------|---------|--------|--------|---------|------------|
| Are you sure? | ¿Estás seguro? | Êtes-vous sûr ? | Sind Sie sicher? | Sei sicuro? | Tem certeza? |
| Delete this item? | ¿Eliminar este elemento? | Supprimer cet élément ? | Dieses Element löschen? | Eliminare questo elemento? | Excluir este item? |
| Confirm deletion | Confirmar eliminación | Confirmer la suppression | Löschung bestätigen | Conferma eliminazione | Confirmar exclusão |

---

## Quick Translation Tips

### Spanish
- Use "tú" form for casual (most apps)
- Accents: á, é, í, ó, ú, ñ
- Question marks: ¿...?
- Exclamations: ¡...!

### French
- Use formal "vous" for apps
- Accents: é, è, ê, à, ù, ç
- Always use space before : ! ? ;
- Example: "Êtes-vous sûr ?" not "Êtes-vous sûr?"

### German
- All nouns capitalized
- Formal "Sie" for apps
- Umlauts: ä, ö, ü, ß
- Longer compound words

### Italian
- Similar to Spanish but use proper Italian grammar
- Accents: à, è, é, ì, ò, ù
- More formal tone

### Portuguese (Brazilian)
- Brazilian variant, not European
- Accents: á, â, ã, é, ê, í, ó, ô, õ, ú, ç
- More casual than European Portuguese
- "Você" form (not "tu")

---

## After Adding Keys

Always run:
```bash
flutter gen-l10n
```

This generates the Dart classes from the ARB files.

