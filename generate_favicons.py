#!/usr/bin/env python3
"""
Generate favicon files from the app icon for web deployment.
This script uses PIL/Pillow to resize the app icon into various sizes needed for favicons.
"""

from PIL import Image
import os

# Paths
script_dir = os.path.dirname(os.path.abspath(__file__))
source_icon = os.path.join(script_dir, 'assets/images/pngs/icon.png')
web_dir = os.path.join(script_dir, 'web')
icons_dir = os.path.join(web_dir, 'icons')

# Ensure directories exist
os.makedirs(icons_dir, exist_ok=True)

# Define the sizes we need to generate
favicon_sizes = [
    (32, os.path.join(web_dir, 'favicon.png')),
    (192, os.path.join(icons_dir, 'Icon-192.png')),
    (512, os.path.join(icons_dir, 'Icon-512.png')),
    (192, os.path.join(icons_dir, 'Icon-maskable-192.png')),
    (512, os.path.join(icons_dir, 'Icon-maskable-512.png')),
]

def generate_favicons():
    """Generate all favicon sizes from the source icon."""
    print(f"Reading source icon: {source_icon}")

    # Open the source image
    with Image.open(source_icon) as img:
        print(f"Source image size: {img.size}")
        print(f"Source image mode: {img.mode}")

        # Ensure we're working with RGBA mode
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Generate each size
        for size, output_path in favicon_sizes:
            print(f"Generating {size}x{size} icon: {output_path}")

            # Resize using high-quality Lanczos resampling
            resized = img.resize((size, size), Image.Resampling.LANCZOS)

            # Save the resized image
            resized.save(output_path, 'PNG', optimize=True)
            print(f"✓ Saved: {output_path}")

    print("\n✓ All favicons generated successfully!")
    print("\nGenerated files:")
    for _, path in favicon_sizes:
        if os.path.exists(path):
            file_size = os.path.getsize(path)
            print(f"  - {path} ({file_size:,} bytes)")

if __name__ == '__main__':
    try:
        generate_favicons()
    except FileNotFoundError as e:
        print(f"Error: Source icon not found at {source_icon}")
        print(f"Please make sure the icon.png file exists in assets/images/pngs/")
    except Exception as e:
        print(f"Error generating favicons: {e}")
        import traceback
        traceback.print_exc()

