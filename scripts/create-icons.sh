#!/bin/bash

# ClipPilot アイコン作成スクリプト（改善版）
# より高品質なアイコンとDMG背景を生成します

set -e

echo "🎨 ClipPilot 高品質アイコン作成中..."

# 出力ディレクトリ
ICON_DIR="ClipPilot/Resources"
ICONSET_DIR="${ICON_DIR}/AppIcon.iconset"
DMG_BG_DIR="dmg-resources"

# ディレクトリ作成
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"
mkdir -p "${DMG_BG_DIR}"

# Pillowのインストールチェック
python3 -c "import PIL" 2>/dev/null || {
    echo "⚠️  Pillowがインストールされていません。インストール中..."
    pip3 install Pillow 2>/dev/null || python3 -m pip install Pillow --user
}

# 高品質アイコンを生成
sizes=(16 32 128 256 512 1024)

for size in "${sizes[@]}"; do
    echo "  生成中: ${size}x${size}..."

    # 標準解像度
    python3 << EOF
from PIL import Image, ImageDraw, ImageFont
import math

size = ${size}
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# グラデーション背景（角丸の矩形）
# より洗練されたブルーグラデーション
def create_rounded_gradient_bg(draw, size):
    # 角丸矩形の背景
    margin = size // 20
    radius = size // 5

    # グラデーション（上から下へ）
    for y in range(size):
        # 青系のグラデーション（明るい青から深い青へ）
        ratio = y / size
        r = int(88 - ratio * 18)   # 88 -> 70
        g = int(150 - ratio * 20)  # 150 -> 130
        b = int(255 - ratio * 5)   # 255 -> 250
        color = (r, g, b)

        draw.rectangle([margin, y, size - margin, y + 1], fill=color)

    # マスクを作成して角丸にする
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([margin, margin, size - margin, size - margin],
                                 radius=radius, fill=255)

    # マスクを適用
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

# 角丸グラデーション背景を作成
img = create_rounded_gradient_bg(draw, size)
draw = ImageDraw.Draw(img)

# クリップボードのアイコンを描画
clipboard_width = size * 0.55
clipboard_height = size * 0.65
clipboard_x = (size - clipboard_width) // 2
clipboard_y = size * 0.2

# クリップボードの背景（白い矩形）
clip_radius = size // 20
draw.rounded_rectangle(
    [clipboard_x, clipboard_y,
     clipboard_x + clipboard_width, clipboard_y + clipboard_height],
    radius=clip_radius,
    fill=(255, 255, 255, 240),
    outline=(200, 200, 210, 255),
    width=max(1, size // 128)
)

# クリップの部分（上部）
clip_width = clipboard_width * 0.4
clip_height = size // 15
clip_x = clipboard_x + (clipboard_width - clip_width) / 2
clip_y = clipboard_y - clip_height // 2

# クリップの影
shadow_offset = max(1, size // 200)
draw.rounded_rectangle(
    [clip_x + shadow_offset, clip_y + shadow_offset,
     clip_x + clip_width + shadow_offset, clip_y + clip_height + shadow_offset],
    radius=clip_radius // 2,
    fill=(0, 0, 0, 30)
)

# クリップ本体（グレー）
draw.rounded_rectangle(
    [clip_x, clip_y, clip_x + clip_width, clip_y + clip_height],
    radius=clip_radius // 2,
    fill=(180, 185, 190, 255),
    outline=(140, 145, 150, 255),
    width=max(1, size // 256)
)

# 書類のアイコン（クリップボード上の紙）
doc_margin = clipboard_width * 0.15
doc_x = clipboard_x + doc_margin
doc_y = clipboard_y + clipboard_height * 0.15
doc_width = clipboard_width - doc_margin * 2
doc_height = clipboard_height * 0.65

# 書類の影
shadow_offset = max(1, size // 150)
draw.rounded_rectangle(
    [doc_x + shadow_offset, doc_y + shadow_offset,
     doc_x + doc_width + shadow_offset, doc_y + doc_height + shadow_offset],
    radius=clip_radius // 3,
    fill=(0, 0, 0, 20)
)

# 書類本体（薄い青）
draw.rounded_rectangle(
    [doc_x, doc_y, doc_x + doc_width, doc_y + doc_height],
    radius=clip_radius // 3,
    fill=(230, 240, 255, 255),
    outline=(180, 200, 230, 255),
    width=max(1, size // 256)
)

# 書類上のテキスト線（3本）
line_margin = doc_width * 0.15
line_spacing = doc_height * 0.18
line_y_start = doc_y + doc_height * 0.2

for i in range(3):
    line_y = line_y_start + i * line_spacing
    line_width = doc_width - line_margin * 2
    if i == 2:  # 最後の線は短く
        line_width *= 0.6

    draw.rectangle(
        [doc_x + line_margin, line_y,
         doc_x + line_margin + line_width, line_y + max(1, size // 200)],
        fill=(100, 130, 180, 200)
    )

img.save('${ICONSET_DIR}/icon_${size}x${size}.png')
EOF

    # Retina解像度（2x）
    if [ $size -lt 512 ]; then
        retina_size=$((size * 2))
        python3 << EOF
from PIL import Image, ImageDraw
import math

size = ${retina_size}
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

def create_rounded_gradient_bg(draw, size):
    margin = size // 20
    radius = size // 5

    for y in range(size):
        ratio = y / size
        r = int(88 - ratio * 18)
        g = int(150 - ratio * 20)
        b = int(255 - ratio * 5)
        color = (r, g, b)
        draw.rectangle([margin, y, size - margin, y + 1], fill=color)

    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([margin, margin, size - margin, size - margin],
                                 radius=radius, fill=255)

    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result

img = create_rounded_gradient_bg(draw, size)
draw = ImageDraw.Draw(img)

clipboard_width = size * 0.55
clipboard_height = size * 0.65
clipboard_x = (size - clipboard_width) // 2
clipboard_y = size * 0.2

clip_radius = size // 20
draw.rounded_rectangle(
    [clipboard_x, clipboard_y,
     clipboard_x + clipboard_width, clipboard_y + clipboard_height],
    radius=clip_radius,
    fill=(255, 255, 255, 240),
    outline=(200, 200, 210, 255),
    width=max(1, size // 128)
)

clip_width = clipboard_width * 0.4
clip_height = size // 15
clip_x = clipboard_x + (clipboard_width - clip_width) / 2
clip_y = clipboard_y - clip_height // 2

shadow_offset = max(1, size // 200)
draw.rounded_rectangle(
    [clip_x + shadow_offset, clip_y + shadow_offset,
     clip_x + clip_width + shadow_offset, clip_y + clip_height + shadow_offset],
    radius=clip_radius // 2,
    fill=(0, 0, 0, 30)
)

draw.rounded_rectangle(
    [clip_x, clip_y, clip_x + clip_width, clip_y + clip_height],
    radius=clip_radius // 2,
    fill=(180, 185, 190, 255),
    outline=(140, 145, 150, 255),
    width=max(1, size // 256)
)

doc_margin = clipboard_width * 0.15
doc_x = clipboard_x + doc_margin
doc_y = clipboard_y + clipboard_height * 0.15
doc_width = clipboard_width - doc_margin * 2
doc_height = clipboard_height * 0.65

shadow_offset = max(1, size // 150)
draw.rounded_rectangle(
    [doc_x + shadow_offset, doc_y + shadow_offset,
     doc_x + doc_width + shadow_offset, doc_y + doc_height + shadow_offset],
    radius=clip_radius // 3,
    fill=(0, 0, 0, 20)
)

draw.rounded_rectangle(
    [doc_x, doc_y, doc_x + doc_width, doc_y + doc_height],
    radius=clip_radius // 3,
    fill=(230, 240, 255, 255),
    outline=(180, 200, 230, 255),
    width=max(1, size // 256)
)

line_margin = doc_width * 0.15
line_spacing = doc_height * 0.18
line_y_start = doc_y + doc_height * 0.2

for i in range(3):
    line_y = line_y_start + i * line_spacing
    line_width = doc_width - line_margin * 2
    if i == 2:
        line_width *= 0.6

    draw.rectangle(
        [doc_x + line_margin, line_y,
         doc_x + line_margin + line_width, line_y + max(1, size // 200)],
        fill=(100, 130, 180, 200)
    )

img.save('${ICONSET_DIR}/icon_${size//2}x${size//2}@2x.png')
EOF
    fi
done

# .icnsファイルを生成
echo "📦 .icnsファイル生成中..."
iconutil -c icns "${ICONSET_DIR}" -o "${ICON_DIR}/AppIcon.icns"

echo "✅ アイコン作成完了: ${ICON_DIR}/AppIcon.icns"

# 高品質DMG背景画像を作成
echo "🖼️  高品質DMG背景画像作成中..."
python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

# DMG背景画像のサイズ
width = 520
height = 380

# グラデーション背景を作成
img = Image.new('RGB', (width, height), (255, 255, 255))
draw = ImageDraw.Draw(img)

# 微妙なグラデーション背景
for y in range(height):
    ratio = y / height
    r = int(245 - ratio * 5)
    g = int(248 - ratio * 8)
    b = int(252 - ratio * 7)
    draw.rectangle([0, y, width, y + 1], fill=(r, g, b))

# より美しい矢印を描画
arrow_y = 190
arrow_start_x = 180
arrow_end_x = 340

# 矢印の色（グラデーション用）
arrow_color_start = (80, 140, 255)
arrow_color_end = (60, 110, 240)

# 矢印の影を先に描く
shadow_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
shadow_draw = ImageDraw.Draw(shadow_img)

# 影の矢印線
shadow_offset = 3
shadow_draw.line(
    [(arrow_start_x + shadow_offset, arrow_y + shadow_offset),
     (arrow_end_x + shadow_offset, arrow_y + shadow_offset)],
    fill=(0, 0, 0, 40), width=8
)

# 影の矢印先端
arrow_head_size = 20
shadow_points = [
    (arrow_end_x + shadow_offset, arrow_y + shadow_offset),
    (arrow_end_x - arrow_head_size + shadow_offset, arrow_y - arrow_head_size + shadow_offset),
    (arrow_end_x - arrow_head_size + shadow_offset, arrow_y + arrow_head_size + shadow_offset)
]
shadow_draw.polygon(shadow_points, fill=(0, 0, 0, 40))

# 影をぼかす
shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=3))

# 影を背景に合成
img.paste(shadow_img, (0, 0), shadow_img)
draw = ImageDraw.Draw(img)

# メインの矢印を描く
# 矢印の線（太め、グラデーション風）
for i in range(6):
    offset = i - 3
    ratio = (i + 1) / 7
    color = tuple(int(arrow_color_start[j] + (arrow_color_end[j] - arrow_color_start[j]) * ratio)
                  for j in range(3))
    draw.line(
        [(arrow_start_x, arrow_y + offset), (arrow_end_x - 5, arrow_y + offset)],
        fill=color, width=2
    )

# 矢印の先端（三角形）- より大きく、滑らか
arrow_points = [
    (arrow_end_x, arrow_y),
    (arrow_end_x - arrow_head_size, arrow_y - arrow_head_size),
    (arrow_end_x - arrow_head_size + 5, arrow_y),
    (arrow_end_x - arrow_head_size, arrow_y + arrow_head_size)
]
draw.polygon(arrow_points, fill=arrow_color_end)

# 矢印の輪郭
draw.line(arrow_points + [arrow_points[0]], fill=arrow_color_start, width=2)

# テキストを追加（より高品質）
try:
    font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    font_medium = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
    font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
except:
    font_large = ImageFont.load_default()
    font_medium = ImageFont.load_default()
    font_small = ImageFont.load_default()

# "Drag to Install" テキスト（影付き）
text = "Drag to Install"
bbox = draw.textbbox((0, 0), text, font=font_large)
text_width = bbox[2] - bbox[0]
text_x = (width - text_width) // 2
text_y = 280

# テキストの影
draw.text((text_x + 2, text_y + 2), text, fill=(0, 0, 0, 50), font=font_large)
# メインテキスト
draw.text((text_x, text_y), text, fill=(50, 50, 50), font=font_large)

# ヒントテキスト
hint_text = "Drag ClipPilot.app to the Applications folder"
bbox = draw.textbbox((0, 0), hint_text, font=font_small)
hint_width = bbox[2] - bbox[0]
hint_x = (width - hint_width) // 2
hint_y = 325

draw.text((hint_x, hint_y), hint_text, fill=(120, 120, 130), font=font_small)

# 画像を保存
img.save('dmg-resources/background.png', quality=95, optimize=True)
print("✅ DMG背景画像作成完了: dmg-resources/background.png")

# @2x版も作成（より高解像度）
img_2x = img.resize((width * 2, height * 2), Image.Resampling.LANCZOS)
img_2x.save('dmg-resources/background@2x.png', quality=95, optimize=True)
print("✅ Retina背景画像作成完了: dmg-resources/background@2x.png")
PYEOF

echo ""
echo "🎉 すべての高品質アセット作成完了！"
echo "   - アプリアイコン: ${ICON_DIR}/AppIcon.icns"
echo "   - DMG背景: dmg-resources/background.png"
echo "   - DMG背景@2x: dmg-resources/background@2x.png"
