# Favicon Generation

This project includes a Python script to generate all required favicon sizes from the main app icon.

## Usage

To regenerate favicons from the app icon:

```bash
python3 generate_favicons.py
```

This will:
1. Read the source icon from `assets/images/pngs/icon.png`
2. Generate the following favicon files:
   - `web/favicon.png` (32x32) - Main browser favicon
   - `web/icons/Icon-192.png` (192x192) - PWA icon
   - `web/icons/Icon-512.png` (512x512) - PWA icon
   - `web/icons/Icon-maskable-192.png` (192x192) - Maskable PWA icon
   - `web/icons/Icon-maskable-512.png` (512x512) - Maskable PWA icon

## Requirements

The script requires Python 3 and Pillow:

```bash
pip3 install Pillow
```

## When to Regenerate

Regenerate favicons whenever you update the app icon (`assets/images/pngs/icon.png`).

## How It Works

The script uses PIL/Pillow to:
1. Load the source icon
2. Convert it to RGBA mode if needed
3. Resize using high-quality Lanczos resampling
4. Save optimized PNG files for each required size

## File Sizes

Typical generated file sizes:
- favicon.png: ~2.4 KB (32x32)
- Icon-192.png: ~45 KB (192x192)
- Icon-512.png: ~259 KB (512x512)
- Icon-maskable-192.png: ~45 KB (192x192)
- Icon-maskable-512.png: ~259 KB (512x512)

## After Generating

After running the script:
1. Clean the Flutter build: `flutter clean`
2. Rebuild for web: `flutter build web`
3. Test the favicon in your browser (you may need to clear cache)
4. Deploy the updated `build/web` folder

