# THBS1/TGFB3 稿件配套 Python 代码整理
本文档按上传文件逐一提取代码，保留原始逻辑和参数，没有擅自合并或改写。
## 文件总览
| 顺序 | 脚本 | 用途 |
|---|---|---|
| 1. Figure 3 重组脚本（v2） | `recompose_figure3.py` | Figure 3 v2：将原图顶部A+B、中间新增TISCH的TGFB3/THBS1热图、底部原图C+D重组为六面板图。 |
| 2. Figure 3 重组脚本（v3，后续修正版） | `recompose_figure3_v3.py` | Figure 3 v3：直接从原PDF裁剪A、B、E、F，替换C/D热图，并修复B面板残留的纵轴标签及F面板纵轴标签裁剪。 |
| 3. Figure 4 重组脚本（初版） | `recompose_figure4.py` | Figure 4初版：以新森林图替换A，原PDF裁剪B/C/D，重组为2×2版式。 |
| 4. Figure 4 重组脚本（v2） | `recompose_figure4_v2.py` | Figure 4 v2：重新精确裁剪原图B/C/D，替换A面板，输出PNG。 |
| 5. Figure 4 重组脚本（v3，后续修正版） | `recompose_figure4_v3.py` | Figure 4 v3：进一步收紧B/C/D裁剪区域，并在各面板行内垂直居中。 |
| 6. Word表格三线表格式脚本 | `three_line_tables.py` | 将Word文档中所有表格统一设置为三线表：顶线/底线1.5 pt，表头下横线0.75 pt，取消竖线。 |

## 运行前共同注意事项
- 原脚本均将工作目录硬编码为 `/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package`，在其他电脑运行前必须改为实际项目目录。
- Figure 3脚本依赖 `Pillow`；v3还依赖 `PyMuPDF`（`fitz`）。
- Figure 4脚本依赖 `Pillow`、`PyMuPDF`；v3额外导入 `numpy`，但代码中未实际使用。
- 三线表脚本依赖 `python-docx`，并会直接覆盖保存同名DOCX文件；建议先备份原稿或改为另存为。
- Figure 3 v3与Figure 3 v2是不同重组方案；Figure 4初版、v2、v3也是迭代版本，不建议连续运行，因为它们会写入相同输出文件名。

---

## 1. Figure 3 重组脚本（v2）

**原文件：** `recompose_figure3.py`

Figure 3 v2：将原图顶部A+B、中间新增TISCH的TGFB3/THBS1热图、底部原图C+D重组为六面板图。

```python
"""Recompose Figure 3 v2:
- Top strip: original A+B (UMAP + violin)
- Middle strip: new TGFB3 heatmap | new THBS1 heatmap
- Bottom strip: original C+D (GSE13507 expression + correlations)
We crop the original into top/bottom strips (no per-panel labels added inside),
then add our own A-F labels on the left margin.
"""
from PIL import Image, ImageDraw, ImageFont
import os

os.chdir("/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package")

full = Image.open("/tmp/fig3_full.png")
W, H = full.size
print("full:", W, H)

# The original figure has:
#   title ~y=0..80
#   top row (A+B plots) ~y=80..1200
#   old C/D titles ~y=1250..1400 (we drop these; new C/D are the heatmaps)
#   bottom row (C+D plots) ~y=1450..2700
top_strip = full.crop((0, 80, W, 1200))
bot_strip = full.crop((0, 1450, W, 2700))

# New heatmaps
hm_tgfb3 = Image.open("outputs_fig/新增指令3/TISCH_TGFB3_heatmap.jpeg")
hm_thbs1 = Image.open("outputs_fig/新增指令3/TISCH_THBS1_heatmap.jpeg")

# Resize everything to common width = W
def resize_to_width(img, w):
    ratio = w / img.width
    return img.resize((w, int(img.height * ratio)), Image.LANCZOS)

top_strip = resize_to_width(top_strip, W)
bot_strip = resize_to_width(bot_strip, W)
hm_tgfb3 = resize_to_width(hm_tgfb3, W//2 - 20)
hm_thbs1 = resize_to_width(hm_thbs1, W//2 - 20)

GAP = 30
MARGIN = 40
title_h = 90

row2_h = max(hm_tgfb3.height, hm_thbs1.height)
total_h = MARGIN + title_h + top_strip.height + GAP + row2_h + GAP + bot_strip.height + MARGIN

canvas = Image.new("RGB", (W + MARGIN*2, total_h), "white")
draw = ImageDraw.Draw(canvas)

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 44)
except:
    font_title = ImageFont.load_default()
    font_label = ImageFont.load_default()

title = ("Single-cell and external validation reveal the cellular context "
         "of the THBS1/TGFB3-associated phenotype")
draw.text((MARGIN, 20), title, fill="black", font=font_title)

y = MARGIN + title_h
# Row 1: top strip (A+B)
canvas.paste(top_strip, (MARGIN, y))
draw.text((MARGIN+5, y+10), "A", fill="black", font=font_label)
draw.text((MARGIN + W//2 + 5, y+10), "B", fill="black", font=font_label)
y += top_strip.height + GAP

# Row 2: new heatmaps
canvas.paste(hm_tgfb3, (MARGIN, y))
canvas.paste(hm_thbs1, (MARGIN + W//2 + 20, y))
draw.text((MARGIN+5, y+10), "C", fill="black", font=font_label)
draw.text((MARGIN + W//2 + 25, y+10), "D", fill="black", font=font_label)
y += row2_h + GAP

# Row 3: bottom strip (E+F)
canvas.paste(bot_strip, (MARGIN, y))
draw.text((MARGIN+5, y+10), "E", fill="black", font=font_label)
draw.text((MARGIN + W//2 + 5, y+10), "F", fill="black", font=font_label)

out_png = "outputs_fig/figure/Figure3_single_cell_external_context_6panel.png"
out_pdf = "outputs_fig/figure/Figure3_single_cell_external_context_6panel.pdf"
canvas.save(out_png, dpi=(300,300))
canvas.save(out_pdf, "PDF", resolution=300.0)
print("saved", out_png, canvas.size)
```

## 2. Figure 3 重组脚本（v3，后续修正版）

**原文件：** `recompose_figure3_v3.py`

Figure 3 v3：直接从原PDF裁剪A、B、E、F，替换C/D热图，并修复B面板残留的纵轴标签及F面板纵轴标签裁剪。

```python
"""Recompose Figure 3 v3: fix F panel y-axis labels, B panel title, residual text."""
from PIL import Image, ImageDraw, ImageFont
import fitz, os

os.chdir("/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package")

doc = fitz.open("outputs_fig/figure/Figure3_single_cell_external_context.pdf")
pix = doc[0].get_pixmap(matrix=fitz.Matrix(300/72, 300/72))
pix.save("/tmp/fig3_orig.png")
orig = Image.open("/tmp/fig3_orig.png")
W, H = orig.size
print(f"orig: {W}x{H}")

# A = UMAP left-top
A = orig.crop((50, 80, 1750, 1280))
# B = violin right-top -- extend left to capture full title
B = orig.crop((1800, 80, 3550, 1280))
# E = GSE13507 line plot left-bottom
E = orig.crop((50, 1400, 1750, 2680))
# F = correlation heatmap right-bottom -- extend left to capture y-axis labels
F = orig.crop((1650, 1400, 3550, 2680))

# Fix B: white out residual inverted y-label area and redraw
B_draw = ImageDraw.Draw(B)
# The residual inverted "THBS1" is on left side, around x=30-120, y=380-550
B_draw.rectangle([20, 370, 130, 560], fill="white")
try:
    font_y = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 26)
except:
    font_y = ImageFont.load_default()
label_img = Image.new("RGB", (130, 28), "white")
ld = ImageDraw.Draw(label_img)
ld.text((5, 2), "THBS1", fill="black", font=font_y)
label_rot = label_img.rotate(90, expand=True)
B.paste(label_rot, (35, 400))

# Load new heatmaps
C = Image.open("outputs_fig/新增指令3/TISCH_TGFB3_heatmap.jpeg")
D = Image.open("outputs_fig/新增指令3/TISCH_THBS1_heatmap.jpeg")

half_w = 1650
GAP_X = 60
GAP_Y = 60
MARGIN = 30

def resize_to_width(img, w):
    ratio = w / img.width
    return img.resize((w, int(img.height * ratio)), Image.LANCZOS)

A_r = resize_to_width(A, half_w)
B_r = resize_to_width(B, half_w)
C_r = resize_to_width(C, half_w)
D_r = resize_to_width(D, half_w)
E_r = resize_to_width(E, half_w)
F_r = resize_to_width(F, half_w)

row1_h = max(A_r.height, B_r.height)
row2_h = max(C_r.height, D_r.height)
row3_h = max(E_r.height, F_r.height)
total_h = MARGIN + row1_h + GAP_Y + row2_h + GAP_Y + row3_h + MARGIN
total_w = 2*half_w + GAP_X + 2*MARGIN

canvas = Image.new("RGB", (total_w, total_h), "white")
draw = ImageDraw.Draw(canvas)
try:
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 48)
except:
    font_label = ImageFont.load_default()

y = MARGIN
for panel, x_offset in [(A_r, 0), (B_r, half_w + GAP_X)]:
    py = y + (row1_h - panel.height) // 2
    canvas.paste(panel, (MARGIN + x_offset, py))
draw.text((MARGIN+5, y+5), "A", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP_X+5, y+5), "B", fill="black", font=font_label)
y += row1_h + GAP_Y

for panel, x_offset in [(C_r, 0), (D_r, half_w + GAP_X)]:
    py = y + (row2_h - panel.height) // 2
    canvas.paste(panel, (MARGIN + x_offset, py))
draw.text((MARGIN+5, y+5), "C", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP_X+5, y+5), "D", fill="black", font=font_label)
y += row2_h + GAP_Y

for panel, x_offset in [(E_r, 0), (F_r, half_w + GAP_X)]:
    py = y + (row3_h - panel.height) // 2
    canvas.paste(panel, (MARGIN + x_offset, py))
draw.text((MARGIN+5, y+5), "E", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP_X+5, y+5), "F", fill="black", font=font_label)

canvas.save("outputs_fig/figure/Figure3_single_cell_external_context_6panel.png", dpi=(300,300))
print(f"saved {canvas.size}")
```

## 3. Figure 4 重组脚本（初版）

**原文件：** `recompose_figure4.py`

Figure 4初版：以新森林图替换A，原PDF裁剪B/C/D，重组为2×2版式。

```python
"""Recompose Figure 4:
- A = new faceted forest plot (Figure4A_cox_forest_faceted.png)
- B, C, D = cropped from original Figure4 PDF
"""
from PIL import Image, ImageDraw, ImageFont
import fitz, os

os.chdir("/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package")

# Render original Figure 4 at 300 dpi
doc = fitz.open("outputs_fig/figure/Figure4_clinical_relevance_exploratory.pdf")
page = doc[0]
pix = page.get_pixmap(matrix=fitz.Matrix(300/72, 300/72))
pix.save("/tmp/fig4_orig.png")
orig = Image.open("/tmp/fig4_orig.png")
W, H = orig.size
print("orig fig4:", W, H)

# Original layout: 2x2, title on top
# A = top-left, B = top-right, C = bottom-left, D = bottom-right
# We crop out each panel (roughly half width, half height)
# Title occupies ~y=0..80
# Top row ~y=80..H/2, bottom row ~y=H/2..H
B = orig.crop((W//2, 80, W, H//2))
C = orig.crop((0, H//2, W//2, H))
D = orig.crop((W//2, H//2, W, H))

# Load new forest plot
newA = Image.open("outputs_fig/figure/Figure4A_cox_forest_faceted.png")

# Resize B/C/D to match newA width (each panel half of total width)
TARGET_W = W
half_w = W // 2
GAP = 30
MARGIN = 40
title_h = 90

def resize_to_width(img, w):
    ratio = w / img.width
    return img.resize((w, int(img.height * ratio)), Image.LANCZOS)

newA = resize_to_width(newA, half_w)
B = resize_to_width(B, half_w)
C = resize_to_width(C, half_w)
D = resize_to_width(D, half_w)

row1_h = max(newA.height, B.height)
row2_h = max(C.height, D.height)

total_h = MARGIN + title_h + row1_h + GAP + row2_h + MARGIN
canvas = Image.new("RGB", (W + 2*MARGIN, total_h), "white")
draw = ImageDraw.Draw(canvas)

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 44)
except:
    font_title = ImageFont.load_default()
    font_label = ImageFont.load_default()

title = "Clinical relevance and exploratory validation of the THBS1/TGFB3-associated stromal-immune phenotype"
draw.text((MARGIN, 20), title, fill="black", font=font_title)

y = MARGIN + title_h
canvas.paste(newA, (MARGIN, y))
canvas.paste(B, (MARGIN + half_w + GAP, y))
draw.text((MARGIN+5, y+5), "A", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "B", fill="black", font=font_label)
y += row1_h + GAP

canvas.paste(C, (MARGIN, y))
canvas.paste(D, (MARGIN+half_w+GAP, y))
draw.text((MARGIN+5, y+5), "C", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "D", fill="black", font=font_label)

out = "outputs_fig/figure/Figure4_clinical_relevance_exploratory.png"
canvas.save(out, dpi=(300,300))
print("saved", out, canvas.size)
```

## 4. Figure 4 重组脚本（v2）

**原文件：** `recompose_figure4_v2.py`

Figure 4 v2：重新精确裁剪原图B/C/D，替换A面板，输出PNG。

```python
"""Clean recompose of Figure 4 from scratch."""
from PIL import Image, ImageDraw, ImageFont
import fitz, os

os.chdir("/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package")

# Render original Figure 4 PDF at 300dpi, crop B/C/D panels EXACTLY
doc = fitz.open("outputs_fig/figure/Figure4_clinical_relevance_exploratory.pdf")
pix = doc[0].get_pixmap(matrix=fitz.Matrix(300/72, 300/72))
pix.save("/tmp/fig4_orig.png")
orig = Image.open("/tmp/fig4_orig.png")
W, H = orig.size  # 3600x2700
print(f"orig: {W}x{H}")

# Original layout (from visual inspection):
# Title: y=0..50
# Row 1 (A+B): y=50..1200
# Row 2 (C+D): y=1350..2650
# Left half x=0..1800, right half x=1800..3600
# A panel x-axis (residual): y=1100..1200 -- CROP THIS OUT

# B panel = right half, top row, skip old A x-axis area
B = orig.crop((1820, 70, 3580, 1200))
# C panel = left half, bottom row
C = orig.crop((40, 1380, 1800, 2650))
# D panel = right half, bottom row
D = orig.crop((1820, 1380, 3580, 2650))

# Load new forest plot
newA = Image.open("outputs_fig/figure/Figure4A_cox_forest_faceted.png")

# Layout: 2 columns, half width
half_w = 1680
GAP = 40
MARGIN = 40

def resize_to_width(img, w):
    ratio = w / img.width
    return img.resize((w, int(img.height * ratio)), Image.LANCZOS)

newA = resize_to_width(newA, half_w)
B = resize_to_width(B, half_w)
C = resize_to_width(C, half_w)
D = resize_to_width(D, half_w)

row1_h = max(newA.height, B.height)
row2_h = max(C.height, D.height)
total_h = MARGIN + row1_h + GAP + row2_h + MARGIN

canvas = Image.new("RGB", (2*half_w + GAP + 2*MARGIN, total_h), "white")
draw = ImageDraw.Draw(canvas)

try:
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 48)
except:
    font_label = ImageFont.load_default()

y = MARGIN
canvas.paste(newA, (MARGIN, y))
canvas.paste(B, (MARGIN + half_w + GAP, y))
draw.text((MARGIN+5, y+5), "A", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "B", fill="black", font=font_label)
y += row1_h + GAP

canvas.paste(C, (MARGIN, y))
canvas.paste(D, (MARGIN+half_w+GAP, y))
draw.text((MARGIN+5, y+5), "C", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "D", fill="black", font=font_label)

canvas.save("outputs_fig/figure/Figure4_clinical_relevance_exploratory.png", dpi=(300,300))
print(f"saved {canvas.size}")
```

## 5. Figure 4 重组脚本（v3，后续修正版）

**原文件：** `recompose_figure4_v3.py`

Figure 4 v3：进一步收紧B/C/D裁剪区域，并在各面板行内垂直居中。

```python
"""Final clean Figure 4: use newA PNG as-is, crop B/C/D from original PDF tightly."""
from PIL import Image, ImageDraw, ImageFont
import fitz, os, numpy as np

os.chdir("/Users/hannah/Desktop/论文/THBS1_TGFB3_revised_submission_package")

# Render original fig4 at 300dpi
doc = fitz.open("outputs_fig/figure/Figure4_clinical_relevance_exploratory.pdf")
pix = doc[0].get_pixmap(matrix=fitz.Matrix(300/72, 300/72))
pix.save("/tmp/fig4_orig.png")
orig = Image.open("/tmp/fig4_orig.png")
W, H = orig.size  # 3600x2700

# Crop B panel (KM curve): right half, top area, but EXCLUDE old A x-axis at bottom
# Old B panel title at y~100, KM plot itself from y~300 to y~1150
# We want B = (1830, 100) to (3580, 1150) -- just the KM plot area, no x-axis
B = orig.crop((1830, 100, 3580, 1150))
# Crop C panel: left half, bottom area
C = orig.crop((50, 1400, 1780, 2650))
# Crop D panel: right half, bottom area
D = orig.crop((1830, 1400, 3580, 2650))

# New forest plot as-is
newA = Image.open("outputs_fig/figure/Figure4A_cox_forest_faceted.png")

half_w = 1650
GAP = 50
MARGIN = 30

def resize_to_width(img, w):
    ratio = w / img.width
    return img.resize((w, int(img.height * ratio)), Image.LANCZOS)

newA_r = resize_to_width(newA, half_w)
B_r = resize_to_width(B, half_w)
C_r = resize_to_width(C, half_w)
D_r = resize_to_width(D, half_w)

row1_h = max(newA_r.height, B_r.height)
row2_h = max(C_r.height, D_r.height)
total_h = MARGIN + row1_h + GAP + row2_h + MARGIN

canvas = Image.new("RGB", (2*half_w + GAP + 2*MARGIN, total_h), "white")
draw = ImageDraw.Draw(canvas)
try:
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", 48)
except:
    font_label = ImageFont.load_default()

y = MARGIN
# Center newA vertically in row1
newA_y = y + (row1_h - newA_r.height) // 2
B_y = y + (row1_h - B_r.height) // 2
canvas.paste(newA_r, (MARGIN, newA_y))
canvas.paste(B_r, (MARGIN + half_w + GAP, B_y))
draw.text((MARGIN+5, y+5), "A", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "B", fill="black", font=font_label)
y += row1_h + GAP

C_y = y + (row2_h - C_r.height) // 2
D_y = y + (row2_h - D_r.height) // 2
canvas.paste(C_r, (MARGIN, C_y))
canvas.paste(D_r, (MARGIN+half_w+GAP, D_y))
draw.text((MARGIN+5, y+5), "C", fill="black", font=font_label)
draw.text((MARGIN+half_w+GAP+5, y+5), "D", fill="black", font=font_label)

canvas.save("outputs_fig/figure/Figure4_clinical_relevance_exploratory.png", dpi=(300,300))
print(f"saved {canvas.size}")
```

## 6. Word表格三线表格式脚本

**原文件：** `three_line_tables.py`

将Word文档中所有表格统一设置为三线表：顶线/底线1.5 pt，表头下横线0.75 pt，取消竖线。

```python
"""Convert tables to three-line (booktabs) style: top/bottom 1.5pt, header bottom 0.75pt, no vertical lines."""
from docx import Document
from docx.oxml.ns import qn, nsdecls
from docx.oxml import parse_xml
import copy

doc = Document("revised_manuscript_THBS1_TGFB3.docx")

def set_cell_border(cell, **kwargs):
    """Set cell borders. kwargs: top, bottom, left, right with dict {sz, val, color}."""
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = tcPr.find(qn('w:tcBorders'))
    if tcBorders is None:
        tcBorders = parse_xml(f'<w:tcBorders {nsdecls("w")}></w:tcBorders>')
        tcPr.append(tcBorders)
    for edge in ('top', 'left', 'bottom', 'right'):
        if edge in kwargs:
            edge_data = kwargs[edge]
            tag = qn(f'w:{edge}')
            el = tcBorders.find(tag)
            if el is None:
                el = parse_xml(f'<w:{edge} {nsdecls("w")}></w:{edge}>')
                tcBorders.append(el)
            for k, v in edge_data.items():
                el.set(qn(f'w:{k}'), str(v))

def make_three_line(table):
    n_rows = len(table.rows)
    n_cols = len(table.columns)
    for ri, row in enumerate(table.rows):
        for ci, cell in enumerate(row.cells):
            borders = {}
            # Top border: only first row gets thick top
            if ri == 0:
                borders['top'] = {'sz': 12, 'val': 'single', 'color': '000000'}  # 1.5pt
            else:
                borders['top'] = {'sz': 0, 'val': 'none'}
            # Bottom border: header row gets mid-rule, last row gets thick bottom
            if ri == 0:
                borders['bottom'] = {'sz': 6, 'val': 'single', 'color': '000000'}  # 0.75pt
            elif ri == n_rows - 1:
                borders['bottom'] = {'sz': 12, 'val': 'single', 'color': '000000'}  # 1.5pt
            else:
                borders['bottom'] = {'sz': 0, 'val': 'none'}
            # No vertical borders
            borders['left'] = {'sz': 0, 'val': 'none'}
            borders['right'] = {'sz': 0, 'val': 'none'}
            set_cell_border(cell, **borders)

for ti, table in enumerate(doc.tables):
    print(f"Processing Table {ti}: {len(table.rows)} rows x {len(table.columns)} cols")
    make_three_line(table)

doc.save("revised_manuscript_THBS1_TGFB3.docx")
print("Done.")
```
