#!/usr/bin/env python3
"""Generate app icons for Resumate"""

from PIL import Image, ImageDraw
import math

def draw_icon(size, is_foreground=False):
    """Draw the Resumate app icon"""

    # Create image with transparent background for foreground, gradient for main
    if is_foreground:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    else:
        img = Image.new('RGBA', (size, size))

    draw = ImageDraw.Draw(img)

    # Background gradient (only for main icon)
    if not is_foreground:
        # Create gradient from indigo -> violet -> amber
        for y in range(size):
            progress = y / size
            if progress < 0.5:
                # indigo to violet
                t = progress * 2
                r = int(99 + (139 - 99) * t)
                g = int(102 + (92 - 102) * t)
                b = int(241 + (246 - 241) * t)
            else:
                # violet to amber
                t = (progress - 0.5) * 2
                r = int(139 + (245 - 139) * t)
                g = int(92 + (158 - 92) * t)
                b = int(246 + (11 - 246) * t)
            draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b, 255))

    # Document/paper icon
    center_x = size // 2
    center_y = size // 2
    doc_width = int(size * 0.45)
    doc_height = int(size * 0.55)
    corner_fold = int(size * 0.12)

    # White document
    doc_points = [
        (center_x - doc_width//2, center_y - doc_height//2),
        (center_x + doc_width//2 - corner_fold, center_y - doc_height//2),
        (center_x + doc_width//2, center_y - doc_height//2 + corner_fold),
        (center_x + doc_width//2, center_y + doc_height//2),
        (center_x - doc_width//2, center_y + doc_height//2),
    ]
    draw.polygon(doc_points, fill=(255, 255, 255, 255))

    # Corner fold (gray triangle)
    fold_points = [
        (center_x + doc_width//2 - corner_fold, center_y - doc_height//2),
        (center_x + doc_width//2, center_y - doc_height//2 + corner_fold),
        (center_x + doc_width//2 - corner_fold, center_y - doc_height//2 + corner_fold),
    ]
    draw.polygon(fold_points, fill=(229, 231, 235, 255))

    # Lines on document (indigo)
    line_color = (99, 102, 241, 255)
    line_width = max(2, int(size * 0.015))
    line_start = center_x - doc_width//2 + int(size * 0.08)
    line_end = center_x + doc_width//2 - int(size * 0.08)

    lines_y = [
        center_y - doc_height//2 + int(size * 0.15),
        center_y - doc_height//2 + int(size * 0.22),
        center_y - doc_height//2 + int(size * 0.29),
        center_y - doc_height//2 + int(size * 0.36),
    ]

    for i, y in enumerate(lines_y):
        end_x = line_end - int(size * 0.1) if i == 3 else line_end
        draw.line([(line_start, y), (end_x, y)], fill=line_color, width=line_width)

    # AI sparkle/star icon
    sparkle_x = center_x + doc_width//2 - int(size * 0.1)
    sparkle_y = center_y + doc_height//2 - int(size * 0.1)
    sparkle_size = int(size * 0.12)

    # Circle background for sparkle (amber)
    circle_radius = int(sparkle_size * 0.7)
    draw.ellipse(
        [sparkle_x - circle_radius, sparkle_y - circle_radius,
         sparkle_x + circle_radius, sparkle_y + circle_radius],
        fill=(245, 158, 11, 255)
    )

    # 8-pointed star (white)
    star_points = []
    for i in range(16):
        angle = (i * math.pi / 8) - math.pi / 2
        radius = sparkle_size * 0.5 if i % 2 == 0 else sparkle_size * 0.2
        x = sparkle_x + int(math.cos(angle) * radius)
        y = sparkle_y + int(math.sin(angle) * radius)
        star_points.append((x, y))

    draw.polygon(star_points, fill=(255, 255, 255, 255))

    return img

# Generate main icon (1024x1024)
print("Generating 1024x1024 main icon...")
main_icon = draw_icon(1024, is_foreground=False)
main_icon.save('assets/icon/app_icon.png', 'PNG')
print("Saved assets/icon/app_icon.png")

# Generate foreground icon (512x512) for Android adaptive icon
print("Generating 512x512 foreground icon...")
foreground_icon = draw_icon(512, is_foreground=True)
foreground_icon.save('assets/icon/app_icon_foreground.png', 'PNG')
print("Saved assets/icon/app_icon_foreground.png")

print("\nIcons generated successfully!")
print("Run: flutter pub run flutter_launcher_icons")
