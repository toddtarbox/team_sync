#!/usr/bin/env python3
"""Add QR code localization keys to all ARB files."""

import json
from pathlib import Path

# Define the new keys for each language
new_keys = {
    'app_en.arb': {
        'playerProfileQRCode': 'Player Profile QR Code',
        'scanQRCodeToViewProfile': 'Scan QR code to view this player\'s profile',
        'tapToEnlarge': 'Tap to enlarge',
        'playerProfileLink': 'Player Profile: {playerName}',
        'errorSharingLink': 'Error sharing link',
    },
    'app_es.arb': {
        'playerProfileQRCode': 'Código QR del Perfil del Jugador',
        'scanQRCodeToViewProfile': 'Escanea el código QR para ver el perfil de este jugador',
        'tapToEnlarge': 'Toca para ampliar',
        'playerProfileLink': 'Perfil del Jugador: {playerName}',
        'errorSharingLink': 'Error al compartir el enlace',
    },
    'app_fr.arb': {
        'playerProfileQRCode': 'Code QR du Profil du Joueur',
        'scanQRCodeToViewProfile': 'Scannez le code QR pour voir le profil de ce joueur',
        'tapToEnlarge': 'Appuyez pour agrandir',
        'playerProfileLink': 'Profil du Joueur: {playerName}',
        'errorSharingLink': 'Erreur lors du partage du lien',
    },
    'app_de.arb': {
        'playerProfileQRCode': 'Spielerprofil QR-Code',
        'scanQRCodeToViewProfile': 'QR-Code scannen, um dieses Spielerprofil anzuzeigen',
        'tapToEnlarge': 'Tippen zum Vergrößern',
        'playerProfileLink': 'Spielerprofil: {playerName}',
        'errorSharingLink': 'Fehler beim Teilen des Links',
    },
    'app_it.arb': {
        'playerProfileQRCode': 'Codice QR del Profilo Giocatore',
        'scanQRCodeToViewProfile': 'Scansiona il codice QR per visualizzare il profilo di questo giocatore',
        'tapToEnlarge': 'Tocca per ingrandire',
        'playerProfileLink': 'Profilo Giocatore: {playerName}',
        'errorSharingLink': 'Errore nella condivisione del link',
    },
    'app_pt.arb': {
        'playerProfileQRCode': 'Código QR do Perfil do Jogador',
        'scanQRCodeToViewProfile': 'Escaneie o código QR para ver o perfil deste jogador',
        'tapToEnlarge': 'Toque para ampliar',
        'playerProfileLink': 'Perfil do Jogador: {playerName}',
        'errorSharingLink': 'Erro ao compartilhar o link',
    },
}

def add_keys_to_arb_file(file_path, keys_to_add):
    """Add new keys to an ARB file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Add new keys
    for key, value in keys_to_add.items():
        if key not in data:
            data[key] = value

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(f"✅ Added {len(keys_to_add)} keys to {file_path.name}")

def main():
    base_path = Path('lib/l10n')

    for filename, keys in new_keys.items():
        file_path = base_path / filename
        if file_path.exists():
            add_keys_to_arb_file(file_path, keys)
        else:
            print(f"⚠️  File not found: {file_path}")

    print("\n✅ All ARB files updated!")
    print("Don't forget to run: flutter gen-l10n")

if __name__ == '__main__':
    main()

