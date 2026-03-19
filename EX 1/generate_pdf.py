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
    """Add a grid of topomap images with labels."""
    valid = [(p, l) for p, l in zip(paths, labels) if os.path.exists(p)]
    if not valid:
        story.append(Paragraph("[Topomap images not found]", styles['Body']))
        return

    cell_w = usable_w / max_per_row
    cell_h = 1.8 * inch
    img_h = 1.5 * inch

    rows_data = []
    label_row = []
    img_row = []
    for i, (p, l) in enumerate(valid):
        label_row.append(Paragraph(f"<b>{l}</b>", ParagraphStyle('tc', parent=styles['Normal'], fontSize=8, alignment=TA_CENTER)))
        try:
            pil_img = PILImage.open(p)
            iw, ih = pil_img.size
            aspect = iw / ih
            w = min(cell_w - 10, img_h * aspect)
            h = w / aspect
            img_row.append(Image(p, width=w, height=h))
        except:
            img_row.append(Paragraph("?", styles['Body']))

        if len(img_row) == max_per_row or i == len(valid) - 1:
            # Pad if needed
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
story.append(Paragraph("Music 451C Exercise Report — W26 (2026/02/24)", styles['Title2']))
story.append(Paragraph("Piano Duet 2017 EEG Hyperscanning Study", styles['Subtitle']))
story.append(HRFlowable(width="100%", thickness=1, color=colors.grey))
story.append(Spacer(1, 12))

# Read markdown and parse
md_text = Path("EX1_Report.md").read_text()
lines = md_text.split('\n')

i = 0
in_references = False
while i < len(lines):
    line = lines[i].strip()

    # Skip title lines (already added)
    if line.startswith('# Music 451C') or line == '**Piano Duet 2017 EEG Hyperscanning Study**':
        i += 1
        continue

    # Horizontal rule
    if line == '---':
        story.append(HRFlowable(width="100%", thickness=0.5, color=colors.grey, spaceBefore=12, spaceAfter=12))
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
        # Single image: full width
        if len(img_paths) == 1:
            add_image(story, img_paths[0])
        else:
            # Multiple consecutive images: arrange in 2x2 grid
            # Extract short labels from the alt text
            short_labels = []
            for lbl in img_labels:
                lbl = lbl.replace('Alpha Topomap - ', '').replace('FRN Topomap - ', '')
                short_labels.append(lbl if lbl else '')
            add_topo_grid(story, img_paths, short_labels, max_per_row=2)
        continue

    # Table with images (topomap grids)
    if line.startswith('|') and '!' in line:
        # Parse the table: header row, separator, image row
        header_line = line
        labels = [c.strip() for c in header_line.split('|')[1:-1]]
        i += 1  # skip separator
        if i < len(lines) and lines[i].strip().startswith('|'):
            i += 1  # skip alignment row
        if i < len(lines) and lines[i].strip().startswith('|'):
            img_line = lines[i].strip()
            img_matches = re.findall(r'!\[.*?\]\((.+?)\)', img_line)
            if img_matches:
                add_topo_grid(story, img_matches, labels)
            i += 1
        continue

    # Regular table (skip header-only tables)
    if line.startswith('|') and '!' not in line:
        i += 1
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

        # Figure caption
        if text.startswith('<b>Figure'):
            story.append(Paragraph(text, styles['FigCaption']))
        elif in_references:
            story.append(Paragraph(text, styles['Ref']))
        else:
            story.append(Paragraph(text, styles['Body']))
    else:
        i += 1

doc.build(story)
print(f"PDF generated: {output_path}")
print(f"Size: {os.path.getsize(output_path) / 1024:.0f} KB")
