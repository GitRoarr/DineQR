#!/usr/bin/env python
"""
DineQR - Table QR Code Generator

Generates QR codes for restaurant tables.
Usage:
    python generate_qr_codes.py --tables 10 --base-url http://192.168.1.100:8000
"""

import os
import sys
import argparse
import qrcode
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.colormasks import SolidFillColorMask

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow is required: pip install Pillow")
    sys.exit(1)


def generate_qr_for_table(table_number, base_url, output_dir):
    """Generate a styled QR code for a specific table."""
    qr_data = f"{base_url}/table/{table_number}"

    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=12,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)

    # Create QR with gold color on dark background
    img = qr.make_image(
        fill_color="#F4C430",
        back_color="#0A0A0A",
    )
    img = img.convert('RGB')

    # Add table label below QR code
    qr_width, qr_height = img.size
    label_height = 60
    final_img = Image.new('RGB', (qr_width, qr_height + label_height), '#0A0A0A')
    final_img.paste(img, (0, 0))

    draw = ImageDraw.Draw(final_img)

    # Try to use a nice font, fallback to default
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("arial.ttf", 24)
            font_small = ImageFont.truetype("arial.ttf", 14)
        except (OSError, IOError):
            font = ImageFont.load_default()
            font_small = font

    # Draw "DineQR" branding
    brand_text = "DineQR"
    brand_bbox = draw.textbbox((0, 0), brand_text, font=font_small)
    brand_width = brand_bbox[2] - brand_bbox[0]
    draw.text(
        ((qr_width - brand_width) / 2, qr_height + 2),
        brand_text,
        fill="#F4C430",
        font=font_small,
    )

    # Draw table number
    table_text = f"Table {table_number}"
    text_bbox = draw.textbbox((0, 0), table_text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    draw.text(
        ((qr_width - text_width) / 2, qr_height + 22),
        table_text,
        fill="#F5F5F5",
        font=font,
    )

    # Draw scan instruction
    scan_text = "Scan • Order • Enjoy"
    scan_bbox = draw.textbbox((0, 0), scan_text, font=font_small)
    scan_width = scan_bbox[2] - scan_bbox[0]
    draw.text(
        ((qr_width - scan_width) / 2, qr_height + label_height - 16),
        scan_text,
        fill="#888888",
        font=font_small,
    )

    # Save
    filename = f"table_{table_number:03d}_qr.png"
    filepath = os.path.join(output_dir, filename)
    final_img.save(filepath, 'PNG')
    print(f"  Generated: {filepath}")
    return filepath


def main():
    parser = argparse.ArgumentParser(description='Generate DineQR table QR codes')
    parser.add_argument(
        '--tables', type=int, default=10,
        help='Number of tables to generate QR codes for (default: 10)',
    )
    parser.add_argument(
        '--base-url', type=str, default='http://localhost:8000',
        help='Base URL for QR code data (default: http://localhost:8000)',
    )
    parser.add_argument(
        '--output', type=str, default='qr_codes',
        help='Output directory for QR code images (default: qr_codes)',
    )
    args = parser.parse_args()

    # Create output directory
    os.makedirs(args.output, exist_ok=True)

    print(f"\n{'='*50}")
    print(f"  DineQR - Table QR Code Generator")
    print(f"{'='*50}")
    print(f"  Tables: 1 to {args.tables}")
    print(f"  Base URL: {args.base_url}")
    print(f"  Output: {args.output}/")
    print(f"{'='*50}\n")

    generated = []
    for i in range(1, args.tables + 1):
        path = generate_qr_for_table(i, args.base_url, args.output)
        generated.append(path)

    print(f"\n  Done! Generated {len(generated)} QR codes.")
    print(f"  Print these and place on restaurant tables.\n")


if __name__ == '__main__':
    main()
