#!/usr/bin/env python3
"""
Script to remove duplicate keys from ARB files.
Keeps the first occurrence of each key and removes duplicates.
"""

import json
import sys
from pathlib import Path
from collections import OrderedDict

def remove_duplicates_from_arb(file_path):
    """Remove duplicate keys from an ARB file, keeping the first occurrence."""
    print(f"\nProcessing: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse JSON while tracking duplicates
    lines = content.split('\n')
    seen_keys = OrderedDict()
    duplicates = []

    # Parse the JSON to find duplicates
    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"  ❌ Error parsing JSON: {e}")
        return False

    # Check for duplicates by parsing line by line
    current_key = None
    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith('"') and '":' in stripped:
            # Extract key from line like: "keyName": "value",
            key_part = stripped.split('":')[0].strip('"')
            if key_part and not key_part.startswith('@'):
                if key_part in seen_keys:
                    duplicates.append((key_part, line_num, seen_keys[key_part]))
                else:
                    seen_keys[key_part] = line_num

    if not duplicates:
        print(f"  ✅ No duplicates found")
        return True

    print(f"  ⚠️  Found {len(duplicates)} duplicate key(s):")
    for key, dup_line, orig_line in duplicates:
        print(f"    - '{key}' (original: line {orig_line}, duplicate: line {dup_line})")

    # Remove duplicates by keeping only first occurrence
    cleaned_data = OrderedDict()
    for key in seen_keys.keys():
        if key in data:
            cleaned_data[key] = data[key]

    # Write back to file with proper formatting
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(cleaned_data, f, ensure_ascii=False, indent=2)
        f.write('\n')  # Add trailing newline

    print(f"  ✅ Cleaned and saved")
    return True

def main():
    # Find all ARB files
    base_path = Path(__file__).parent / 'lib' / 'l10n'
    arb_files = sorted(base_path.glob('app_*.arb'))

    if not arb_files:
        print("❌ No ARB files found in lib/l10n/")
        sys.exit(1)

    print(f"Found {len(arb_files)} ARB file(s) to process:")
    for f in arb_files:
        print(f"  - {f.name}")

    success = True
    for arb_file in arb_files:
        if not remove_duplicates_from_arb(arb_file):
            success = False

    if success:
        print("\n✅ All files processed successfully!")
        print("\n⚠️  Don't forget to run: flutter gen-l10n")
    else:
        print("\n❌ Some files had errors")
        sys.exit(1)

if __name__ == '__main__':
    main()

