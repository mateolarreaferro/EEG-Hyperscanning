#!/usr/bin/env python3
"""Generate PDF from EX1_Report.md using reportlab."""

import os
import re
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER, TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, HRFlowable, Table, TableStyle,
    KeepTogether
)
from reportlab.lib import colors
from PIL import Image as PILImage

os.chdir(Path(__file__).parent)

# Setup
output_path = "EX1_Report.pdf"
page_w, page_h = letter
margin = 1 * inch
usable_w = page_w - 2 * margin

doc = SimpleDocTemplate(
    output_path,
    pagesize=letter,
    leftMargin=margin, rightMargin=margin,
    topMargin=margin, bottomMargin=margin
)

# Styles
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    'Title2', parent=styles['Title'],
    fontSize=16, spaceAfter=6, alignment=TA_CENTER,
    fontName='Times-Bold'
))
styles.add(ParagraphStyle(
    'Subtitle', parent=styles['Normal'],
    fontSize=12, alignment=TA_CENTER, spaceAfter=12,
    fontName='Times-Bold'
))
styles.add(ParagraphStyle(
    'H2', parent=styles['Heading2'],
    fontSize=14, spaceBefore=18, spaceAfter=8,
    fontName='Times-Bold', keepWithNext=True
))
styles.add(ParagraphStyle(
    'H3', parent=styles['Heading3'],
    fontSize=12, spaceBefore=12, spaceAfter=6,
    fontName='Times-Bold', keepWithNext=True
))
styles.add(ParagraphStyle(
    'Body', parent=styles['Normal'],
    fontSize=11, leading=16, alignment=TA_JUSTIFY,
    fontName='Times-Roman', spaceAfter=8
))
styles.add(ParagraphStyle(
    'Ref', parent=styles['Normal'],
    fontSize=10, leading=14, alignment=TA_LEFT,
    fontName='Times-Roman', spaceAfter=4,
    leftIndent=36, firstLineIndent=-36
))
styles.add(ParagraphStyle(
    'FigCaption', parent=styles['Normal'],
    fontSize=10, leading=14, alignment=TA_LEFT,
    fontName='Times-Italic', spaceAfter=6, spaceBefore=4
))


def md_to_rt(text):
    """Convert markdown inline formatting to reportlab XML tags."""
    # Bold+italic
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'<b><i>\1</i></b>', text)
    # Bold
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    # Italic
    text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
    # Subscript-like (r_s)
    text = text.replace('r_s', 'r<sub>s</sub>')
    return text


def crop_whitespace(img_path):
    """Crop whitespace from a topomap image, return path to cropped version."""
    pil_img = PILImage.open(img_path).convert("RGBA")
    # Create a white background reference
    bg = PILImage.new("RGBA", pil_img.size, (255, 255, 255, 255))
    diff = PILImage.new("L", pil_img.size)
    for x in range(pil_img.size[0]):
        for y in range(pil_img.size[1]):
            r1, g1, b1, a1 = pil_img.getpixel((x, y))
            r2, g2, b2, a2 = bg.getpixel((x, y))
            d = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            diff.putpixel((x, y), min(255, d))
    bbox = diff.getbbox()
    if bbox:
        # Add small padding
        pad = 5
        bbox = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                min(pil_img.size[0], bbox[2] + pad), min(pil_img.size[1], bbox[3] + pad))
        cropped = pil_img.crop(bbox)
        cropped_path = img_path.replace('.png', '_cropped.png')
        cropped.save(cropped_path)
        return cropped_path
    return img_path


def auto_crop(img_path):
    """Crop uniform background from topomap images using corner color detection."""
    import numpy as np
    pil_img = PILImage.open(img_path).convert("RGB")
    arr = np.array(pil_img)
    h, w = arr.shape[:2]
    # Sample corner regions to determine background color
    corners = np.concatenate([
        arr[:10, :10].reshape(-1, 3),
        arr[:10, -10:].reshape(-1, 3),
        arr[-10:, :10].reshape(-1, 3),
        arr[-10:, -10:].reshape(-1, 3),
    ])
    bg_color = np.median(corners, axis=0).astype(np.uint8)
    # Pixels that differ from background by more than threshold
    diff = np.abs(arr.astype(int) - bg_color.astype(int)).sum(axis=2)
    mask = diff > 30
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    if rows.any() and cols.any():
        rmin, rmax = np.where(rows)[0][[0, -1]]
        cmin, cmax = np.where(cols)[0][[0, -1]]
        pad = 10
        rmin = max(0, rmin - pad)
        rmax = min(h, rmax + pad)
        cmin = max(0, cmin - pad)
        cmax = min(w, cmax + pad)
        cropped = pil_img.crop((cmin, rmin, cmax, rmax))
        # Convert to white background
        bg = PILImage.new("RGB", cropped.size, (255, 255, 255))
        cropped_arr = np.array(cropped)
        bg_arr = np.array(bg)
        crop_diff = np.abs(cropped_arr.astype(int) - bg_color.astype(int)).sum(axis=2)
        bg_mask = crop_diff <= 30
        cropped_arr[bg_mask] = [255, 255, 255]
        result = PILImage.fromarray(cropped_arr)
        cropped_path = img_path.replace('.png', '_cropped.png')
        result.save(cropped_path)
        return cropped_path
    return img_path


def add_image(story, img_path, max_w=None, max_h=None):
    """Add an image scaled to fit."""
    if max_w is None:
        max_w = usable_w
    if max_h is None:
        max_h = 3.5 * inch
    if not os.path.exists(img_path):
        story.append(Paragraph(f"[Image not found: {img_path}]", styles['Body']))
        return
    try:
        pil_img = PILImage.open(img_path)
        iw, ih = pil_img.size
        aspect = iw / ih
        w = min(max_w, max_h * aspect)
        h = w / aspect
        if h > max_h:
            h = max_h
            w = h * aspect
        story.append(Image(img_path, width=w, height=h))
    except Exception as e:
        story.append(Paragraph(f"[Error loading {img_path}: {e}]", styles['Body']))


def add_topo_grid(story, paths, labels, max_per_row=4):
    """Add a grid of topomap images with labels, auto-cropping whitespace."""
    valid = [(p, l) for p, l in zip(paths, labels) if os.path.exists(p)]
    if not valid:
        story.append(Paragraph("[Topomap images not found]", styles['Body']))
        return

    cell_w = usable_w / max_per_row
    img_h = 2.8 * inch

    rows_data = []
    label_row = []
    img_row = []
    for i, (p, l) in enumerate(valid):
        label_row.append(Paragraph(f"<b>{l}</b>", ParagraphStyle('tc', parent=styles['Normal'], fontSize=9, alignment=TA_CENTER)))
        try:
            cropped_path = auto_crop(p)
            pil_img = PILImage.open(cropped_path)
            iw, ih = pil_img.size
            aspect = iw / ih
            w = min(cell_w - 6, img_h * aspect)
            h = w / aspect
            if h > img_h:
                h = img_h
                w = h * aspect
            img_row.append(Image(cropped_path, width=w, height=h))
        except:
            img_row.append(Paragraph("?", styles['Body']))

        if len(img_row) == max_per_row or i == len(valid) - 1:
            while len(label_row) < max_per_row:
                label_row.append("")
                img_row.append("")
            rows_data.append(label_row)
            rows_data.append(img_row)
            label_row = []
            img_row = []

    col_widths = [cell_w] * max_per_row
    t = Table(rows_data, colWidths=col_widths)
    t.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ]))
    story.append(t)


# ─── Build the document ───
story = []

# Title
story.append(Paragraph("Music 451C Exercise Report - W26 (2026/02/24)", styles['Title2']))
story.append(Paragraph("Piano Duet 2017 EEG Hyperscanning Study", styles['Subtitle']))
story.append(Paragraph("Mateo Larrea / Stanford University", ParagraphStyle(
    'Author', parent=styles['Normal'], fontSize=12, alignment=TA_CENTER,
    fontName='Times-Roman', spaceAfter=12
)))
story.append(Spacer(1, 12))

# Read markdown and parse
md_text = Path("EX1_Report.md").read_text()
lines = md_text.split('\n')

i = 0
in_references = False
pending_caption = None  # holds a figure caption to keep with next image
while i < len(lines):
    line = lines[i].strip()

    # Skip title lines (already added)
    if line.startswith('# Music 451C') or line == '**Piano Duet 2017 EEG Hyperscanning Study**' or line == 'Mateo Larrea / Stanford University':
        i += 1
        continue

    # Horizontal rule (skip)
    if line == '---':
        in_references = False
        i += 1
        continue

    # H2
    if line.startswith('## '):
        heading = line[3:].strip()
        story.append(Paragraph(md_to_rt(heading), styles['H2']))
        in_references = False
        i += 1
        continue

    # H3
    if line.startswith('### '):
        heading = line[4:].strip()
        story.append(Paragraph(md_to_rt(heading), styles['H3']))
        if 'References' in heading:
            in_references = True
        else:
            in_references = False
        i += 1
        continue

    # Image line — collect consecutive images into a grid
    img_match = re.match(r'!\[.*?\]\((.+?)\)', line)
    if img_match and not line.startswith('|'):
        # Collect consecutive image lines
        img_paths = []
        img_labels = []
        while i < len(lines):
            l = lines[i].strip()
            m = re.match(r'!\[(.*?)\]\((.+?)\)', l)
            if m:
                img_labels.append(m.group(1))
                img_paths.append(m.group(2))
                i += 1
            else:
                break
        # Build image elements
        img_elements = []
        if len(img_paths) == 1:
            # Single image: full width — build element list for KeepTogether
            img_path = img_paths[0]
            if os.path.exists(img_path):
                try:
                    pil_img = PILImage.open(img_path)
                    iw, ih = pil_img.size
                    aspect = iw / ih
                    max_w, max_h = usable_w, 3.5 * inch
                    w = min(max_w, max_h * aspect)
                    h = w / aspect
                    if h > max_h:
                        h = max_h
                        w = h * aspect
                    img_elements.append(Image(img_path, width=w, height=h))
                except:
                    pass
        else:
            # Multiple consecutive images: arrange in 2x2 grid
            short_labels = []
            for lbl in img_labels:
                lbl = lbl.replace('Alpha Topomap - ', '').replace('FRN Topomap - ', '')
                short_labels.append(lbl if lbl else '')
            # Build grid table directly
            grid_elements = []
            _story_tmp = []
            add_topo_grid(_story_tmp, img_paths, short_labels, max_per_row=2)
            img_elements.extend(_story_tmp)

        if pending_caption and img_elements:
            story.append(KeepTogether(img_elements + [pending_caption]))
            pending_caption = None
        else:
            story.extend(img_elements)
            if pending_caption:
                story.append(pending_caption)
                pending_caption = None
        continue

    # Table rows — collect consecutive image tables (possibly separated by blank lines)
    if line.startswith('|'):
        all_table_lines = []
        # Collect this table and any following tables separated by blank lines
        while True:
            while i < len(lines) and lines[i].strip().startswith('|'):
                all_table_lines.append(lines[i].strip())
                i += 1
            # Look ahead past blank lines for another table
            j = i
            while j < len(lines) and lines[j].strip() == '':
                j += 1
            if j < len(lines) and lines[j].strip().startswith('|') and '!' in ''.join(lines[j2].strip() for j2 in range(j, min(j+5, len(lines))) if lines[j2].strip().startswith('|')):
                # Skip blank lines and continue collecting
                i = j
            else:
                break

        # Check if any line contains images
        has_images = any('!' in tl for tl in all_table_lines)
        if has_images:
            all_header_labels = []
            all_img_paths = []
            for tl in all_table_lines:
                if '!' in tl:
                    img_matches = re.findall(r'!\[.*?\]\((.+?)\)', tl)
                    all_img_paths.extend(img_matches)
                elif ':---' not in tl and tl.count('|') > 2:
                    labels = [c.strip() for c in tl.split('|')[1:-1]]
                    all_header_labels.extend(labels)
            if all_img_paths:
                if not all_header_labels or len(all_header_labels) != len(all_img_paths):
                    all_header_labels = [os.path.splitext(os.path.basename(p))[0] for p in all_img_paths]
                grid_elements = []
                add_topo_grid(grid_elements, all_img_paths, all_header_labels)
                if pending_caption and grid_elements:
                    story.extend(grid_elements)
                    story.append(pending_caption)
                    pending_caption = None
                else:
                    story.extend(grid_elements)
        # else: skip non-image tables
        continue

    # Empty line
    if not line:
        i += 1
        continue

    # Paragraph text — collect consecutive non-empty, non-special lines
    para_lines = []
    while i < len(lines):
        l = lines[i].strip()
        if not l or l.startswith('#') or l.startswith('---') or l.startswith('|') or l.startswith('!['):
            break
        para_lines.append(l)
        i += 1

    if para_lines:
        text = ' '.join(para_lines)
        text = md_to_rt(text)

        # Figure caption — defer to keep with next image
        if text.startswith('<b>Figure'):
            if pending_caption:
                story.append(pending_caption)
            pending_caption = Paragraph(text, styles['FigCaption'])
        elif in_references:
            story.append(Paragraph(text, styles['Ref']))
        else:
            story.append(Paragraph(text, styles['Body']))
    else:
        i += 1

if pending_caption:
    story.append(pending_caption)

doc.build(story)
print(f"PDF generated: {output_path}")
print(f"Size: {os.path.getsize(output_path) / 1024:.0f} KB")
