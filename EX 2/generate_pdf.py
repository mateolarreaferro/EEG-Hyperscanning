#!/usr/bin/env python3
"""Generate PDF from EX2_Report.md using reportlab."""

import os
import re
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER, TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle,
    KeepTogether, PageBreak
)
from reportlab.lib import colors
from PIL import Image as PILImage
import numpy as np

os.chdir(Path(__file__).parent)

# Setup
output_path = "EX2_Report.pdf"
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
styles.add(ParagraphStyle(
    'TableCell', parent=styles['Normal'],
    fontSize=10, leading=12, alignment=TA_CENTER,
    fontName='Times-Roman'
))
styles.add(ParagraphStyle(
    'TableHeader', parent=styles['Normal'],
    fontSize=10, leading=12, alignment=TA_CENTER,
    fontName='Times-Bold'
))
styles.add(ParagraphStyle(
    'Keywords', parent=styles['Normal'],
    fontSize=11, leading=14, alignment=TA_LEFT,
    fontName='Times-Italic', spaceAfter=12
))
styles.add(ParagraphStyle(
    'ListItem', parent=styles['Normal'],
    fontSize=11, leading=16, alignment=TA_JUSTIFY,
    fontName='Times-Roman', spaceAfter=4,
    leftIndent=24, firstLineIndent=-24
))


def md_to_rt(text):
    """Convert markdown inline formatting to reportlab XML tags."""
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'<b><i>\1</i></b>', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
    text = text.replace('r_s', 'r<sub>s</sub>')
    return text


def auto_crop(img_path):
    """Crop uniform background from images using corner color detection."""
    pil_img = PILImage.open(img_path).convert("RGB")
    arr = np.array(pil_img)
    h, w = arr.shape[:2]
    corners = np.concatenate([
        arr[:10, :10].reshape(-1, 3),
        arr[:10, -10:].reshape(-1, 3),
        arr[-10:, :10].reshape(-1, 3),
        arr[-10:, -10:].reshape(-1, 3),
    ])
    bg_color = np.median(corners, axis=0).astype(np.uint8)
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
        cropped_arr = np.array(cropped)
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


def add_topo_grid(story, paths, labels, max_per_row=2):
    """Add a grid of topomap images with labels."""
    valid = [(p, l) for p, l in zip(paths, labels) if os.path.exists(p)]
    if not valid:
        story.append(Paragraph("[Topomap images not found]", styles['Body']))
        return

    cell_w = usable_w / max_per_row
    img_h = 2.5 * inch

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
            # Images first, labels below
            rows_data.append(img_row)
            rows_data.append(label_row)
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


def parse_md_table(lines_block):
    """Parse a markdown table into header and data rows."""
    rows = []
    for line in lines_block:
        if re.match(r'^[\|\s\-:]+$', line) or line.strip() == '':
            continue
        cells = [c.strip() for c in line.split('|')[1:-1]]
        if cells:
            rows.append(cells)
    return rows


def add_md_table(story, table_rows):
    """Render a parsed markdown table."""
    if not table_rows:
        return
    # Build table data with Paragraphs
    data = []
    for ri, row in enumerate(table_rows):
        style_name = 'TableHeader' if ri == 0 else 'TableCell'
        data.append([Paragraph(md_to_rt(c), styles[style_name]) for c in row])

    ncols = max(len(r) for r in data)
    col_w = usable_w / ncols
    t = Table(data, colWidths=[col_w] * ncols)
    style_cmds = [
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('FONTNAME', (0, 0), (-1, 0), 'Times-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('BACKGROUND', (0, 0), (-1, 0), colors.Color(0.9, 0.9, 0.9)),
    ]
    t.setStyle(TableStyle(style_cmds))
    story.append(t)
    story.append(Spacer(1, 8))


# ─── Build the document ───
story = []

# Title
story.append(Paragraph("Music 451C Final Report - W26", styles['Title2']))
story.append(Paragraph("Drum Duet Improvisation: Timbre Deviance Monitoring During Joint Musical Improvisation", styles['Subtitle']))
story.append(Paragraph("Mateo Larrea / Stanford University", ParagraphStyle(
    'Author', parent=styles['Normal'], fontSize=12, alignment=TA_CENTER,
    fontName='Times-Roman', spaceAfter=12
)))
story.append(Spacer(1, 12))

# Read markdown
md_text = Path("EX2_Report.md").read_text()
lines = md_text.split('\n')

i = 0
in_references = False
pending_caption = None

while i < len(lines):
    line = lines[i].strip()

    # Skip title lines (already added)
    if line.startswith('# Music 451C') or line.startswith('**Drum Duet') or line == 'Mateo Larrea / Stanford University':
        i += 1
        continue

    # Keywords line — display and add page break after title page
    if line.startswith('Keywords:'):
        story.append(Paragraph(md_to_rt(line), styles['Keywords']))
        story.append(PageBreak())
        i += 1
        continue

    # H2
    if line.startswith('## '):
        heading = line[3:].strip()
        # Page break before Introduction (after Abstract)
        if heading.startswith('1.'):
            story.append(PageBreak())
        if 'References' in heading:
            in_references = True
        else:
            in_references = False
        story.append(Paragraph(md_to_rt(heading), styles['H2']))
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

    # Standalone image
    img_match = re.match(r'!\[.*?\]\((.+?)\)', line)
    if img_match and not line.startswith('|'):
        img_path = img_match.group(1)
        elems = []
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
                elems.append(Image(img_path, width=w, height=h))
            except:
                pass
        # Caption goes BELOW the image
        if pending_caption:
            elems.append(pending_caption)
            pending_caption = None
        if elems:
            story.append(KeepTogether(elems))
        i += 1
        continue

    # Table block (could be data table or image table)
    if line.startswith('|'):
        table_lines = []
        while i < len(lines) and lines[i].strip().startswith('|'):
            table_lines.append(lines[i].strip())
            i += 1

        # Check if this table contains images
        has_images = any('!' in tl for tl in table_lines)
        if has_images:
            # Extract images and labels
            all_img_paths = []
            all_labels = []
            for tl in table_lines:
                if '!' in tl:
                    matches = re.findall(r'!\[.*?\]\((.+?)\)', tl)
                    all_img_paths.extend(matches)
                elif ':---' not in tl and tl.count('|') > 2:
                    cells = [c.strip() for c in tl.split('|')[1:-1]]
                    all_labels.extend(cells)
            if all_img_paths:
                if not all_labels or len(all_labels) != len(all_img_paths):
                    all_labels = [os.path.splitext(os.path.basename(p))[0] for p in all_img_paths]
                # Check for row headers (e.g., **Complementary**)
                row_headers = []
                for tl in table_lines:
                    if '!' in tl:
                        cells = [c.strip() for c in tl.split('|')[1:-1]]
                        if cells and '!' not in cells[0]:
                            row_headers.append(cells[0])
                add_topo_grid(story, all_img_paths, all_labels)
                # Caption goes BELOW the image grid
                if pending_caption:
                    story.append(pending_caption)
                    pending_caption = None
        else:
            # Data table
            parsed = parse_md_table(table_lines)
            if parsed:
                add_md_table(story, parsed)
        continue

    # Empty line
    if not line:
        i += 1
        continue

    # Numbered list item (e.g., "1. **Bold text:**...")
    list_match = re.match(r'^(\d+)\.\s+(.+)', line)
    if list_match:
        # Collect continuation lines for this list item
        item_lines = [line]
        i += 1
        while i < len(lines):
            l = lines[i].strip()
            # Stop at blank lines, headings, new list items, tables, images
            if not l or l.startswith('#') or l.startswith('|') or l.startswith('![') or re.match(r'^\d+\.\s+', l):
                break
            item_lines.append(l)
            i += 1
        text = ' '.join(item_lines)
        text = md_to_rt(text)
        story.append(Paragraph(text, styles['ListItem']))
        continue

    # Paragraph text
    para_lines = []
    while i < len(lines):
        l = lines[i].strip()
        if not l or l.startswith('#') or l.startswith('---') or l.startswith('|') or l.startswith('![') or re.match(r'^\d+\.\s+', l):
            break
        para_lines.append(l)
        i += 1

    if para_lines:
        text = ' '.join(para_lines)
        text = md_to_rt(text)

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
