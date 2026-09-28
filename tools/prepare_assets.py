import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "textures")
BRAIN_DIR = r"C:\Users\KadiR-PC\.gemini\antigravity-ide\brain\30c4a385-7504-40c5-8874-c5afe73de951"
os.makedirs(ASSETS_DIR, exist_ok=True)

# 1. Tabletop
tabletop_src = os.path.join(BRAIN_DIR, "wood_tabletop_bg_1790543737525.jpg")
if os.path.exists(tabletop_src):
    img = Image.open(tabletop_src).convert("RGB")
    img.save(os.path.join(ASSETS_DIR, "tabletop_bg.jpg"), quality=95)

# 2. Board wood
board_src = os.path.join(BRAIN_DIR, "board_wood_surface_1790543771252.jpg")
if os.path.exists(board_src):
    img = Image.open(board_src).convert("RGB")
    img.save(os.path.join(ASSETS_DIR, "board_wood.jpg"), quality=95)

# 3. Pieces (Centered precisely)
piece_src = os.path.join(BRAIN_DIR, "p1_piece_red_1790543809464.jpg")
if os.path.exists(piece_src):
    orig = Image.open(piece_src).convert("RGBA")
    # Measured center: cx = 518.3, cy = 524.5, radius = 230
    cx, cy = 518.3, 524.5
    radius = 232.0
    margin = 24.0
    crop_size = int((radius + margin) * 2)
    half_size = crop_size / 2.0
    
    # Crop precisely centered on the token
    crop_box = (
        int(round(cx - half_size)),
        int(round(cy - half_size)),
        int(round(cx + half_size)),
        int(round(cy + half_size))
    )
    cropped = orig.crop(crop_box)
    cw, ch = cropped.size
    ccx, ccy = cw / 2.0, ch / 2.0
    
    arr_red = np.array(cropped)
    
    # Distance from center for each pixel
    y_coords, x_coords = np.ogrid[:ch, :cw]
    dist = np.sqrt((x_coords - ccx)**2 + (y_coords - ccy)**2)
    
    # Alpha mask:
    # 0 to radius: piece
    # radius to radius + 1.5: antialiased edge
    # radius + 1.5 to radius + 18: drop shadow
    alpha = np.zeros((ch, cw), dtype=np.uint8)
    inner = dist <= radius
    alpha[inner] = 255
    
    edge = (dist > radius) & (dist <= radius + 2.0)
    factor = 1.0 - (dist[edge] - radius) / 2.0
    alpha[edge] = (factor * 255).astype(np.uint8)
    
    shadow = (dist > radius + 2.0) & (dist <= radius + 20.0)
    s_factor = np.clip(1.0 - (dist[shadow] - (radius + 2.0)) / 18.0, 0, 1)
    alpha[shadow] = (s_factor * 85).astype(np.uint8)
    
    arr_red[:, :, 3] = alpha
    arr_red[shadow, 0] = 15
    arr_red[shadow, 1] = 8
    arr_red[shadow, 2] = 4
    
    red_img = Image.fromarray(arr_red).resize((256, 256), Image.Resampling.LANCZOS)
    red_img.save(os.path.join(ASSETS_DIR, "piece_red.png"))
    print("Saved piece_red.png")
    
    # Now generate IVORY piece from the centered cropped array
    arr_ivory = arr_red.copy()
    
    # Identify brass ring: gold brass has yellow/gold tint (g > 80 and b < 120 and r > 120)
    r = arr_red[:, :, 0].astype(float)
    g = arr_red[:, :, 1].astype(float)
    b = arr_red[:, :, 2].astype(float)
    
    # Brass detection
    is_brass = (r > 120) & (g > 100) & (b < 100) & (dist < radius * 0.95)
    
    # All other non-shadow parts of the token are lacquer body
    is_token = (dist <= radius) & (~is_brass)
    
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    token_lum = lum[is_token]
    min_l, max_l = np.min(token_lum), np.max(token_lum)
    norm_l = (lum - min_l) / max(1.0, max_l - min_l)
    
    # Premium ivory porcelain:
    iv_r = 205.0 + norm_l * 50.0
    iv_g = 198.0 + norm_l * 55.0
    iv_b = 185.0 + norm_l * 68.0
    
    arr_ivory[is_token, 0] = np.clip(iv_r[is_token], 0, 255).astype(np.uint8)
    arr_ivory[is_token, 1] = np.clip(iv_g[is_token], 0, 255).astype(np.uint8)
    arr_ivory[is_token, 2] = np.clip(iv_b[is_token], 0, 255).astype(np.uint8)
    
    ivory_img = Image.fromarray(arr_ivory).resize((256, 256), Image.Resampling.LANCZOS)
    ivory_img.save(os.path.join(ASSETS_DIR, "piece_ivory.png"))
    print("Saved piece_ivory.png")

# 4. Sockets & Highlights
socket_size = 128
socket_img = Image.new("RGBA", (socket_size, socket_size), (0, 0, 0, 0))
sdraw = ImageDraw.Draw(socket_img)
scx, scy = socket_size / 2.0, socket_size / 2.0
sdraw.ellipse([scx - 44, scy - 44, scx + 44, scy + 44], fill=(30, 15, 5, 80))
sdraw.ellipse([scx - 38, scy - 38, scx + 38, scy + 38], fill=(185, 145, 65, 230))
sdraw.ellipse([scx - 35, scy - 35, scx + 35, scy + 35], fill=(230, 195, 110, 255))
sdraw.ellipse([scx - 28, scy - 28, scx + 28, scy + 28], fill=(45, 25, 10, 255))
sdraw.ellipse([scx - 25, scy - 25, scx + 25, scy + 25], fill=(22, 10, 4, 255))
sdraw.arc([scx - 28, scy - 28, scx + 28, scy + 28], start=45, end=135, fill=(120, 75, 30, 255), width=2)
sdraw.arc([scx - 28, scy - 28, scx + 28, scy + 28], start=225, end=315, fill=(15, 8, 3, 255), width=2)
socket_img = socket_img.filter(ImageFilter.GaussianBlur(0.6))
socket_img.save(os.path.join(ASSETS_DIR, "node_socket.png"))

hl_size = 128
move_hl = Image.new("RGBA", (hl_size, hl_size), (0, 0, 0, 0))
mdraw = ImageDraw.Draw(move_hl)
mcx, mcy = hl_size / 2.0, hl_size / 2.0
for r_off in range(38, 14, -2):
    alpha = int(140 * (1.0 - (r_off - 14) / 24.0))
    mdraw.ellipse([mcx - r_off, mcy - r_off, mcx + r_off, mcy + r_off], fill=(40, 235, 120, alpha))
mdraw.ellipse([mcx - 16, mcy - 16, mcx + 16, mcy + 16], fill=(90, 255, 160, 255))
mdraw.ellipse([mcx - 8, mcy - 8, mcx + 8, mcy + 8], fill=(230, 255, 240, 255))
move_hl = move_hl.filter(ImageFilter.GaussianBlur(1.0))
move_hl.save(os.path.join(ASSETS_DIR, "move_highlight.png"))

cap_hl = Image.new("RGBA", (hl_size, hl_size), (0, 0, 0, 0))
cdraw = ImageDraw.Draw(cap_hl)
for r_off in range(44, 18, -2):
    alpha = int(160 * (1.0 - (r_off - 18) / 26.0))
    cdraw.ellipse([mcx - r_off, mcy - r_off, mcx + r_off, mcy + r_off], fill=(255, 150, 20, alpha))
cdraw.ellipse([mcx - 22, mcy - 22, mcx + 22, mcy + 22], fill=(255, 60, 30, 240))
cdraw.ellipse([mcx - 12, mcy - 12, mcx + 12, mcy + 12], fill=(255, 230, 160, 255))
cap_hl = cap_hl.filter(ImageFilter.GaussianBlur(1.0))
cap_hl.save(os.path.join(ASSETS_DIR, "capture_highlight.png"))

sel_hl = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(sel_hl)
scx, scy = 128, 128
for r_off in range(124, 98, -2):
    alpha = int(180 * (1.0 - (r_off - 98) / 26.0))
    s_draw.ellipse([scx - r_off, scy - r_off, scx + r_off, scy + r_off], outline=(255, 215, 60, alpha), width=3)
sel_hl = sel_hl.filter(ImageFilter.GaussianBlur(2.0))
sel_hl.save(os.path.join(ASSETS_DIR, "piece_selected_glow.png"))

# 5. Create Game Logo (16 GUTI / SHOLO GUTI)
logo_w, logo_h = 600, 240
logo_img = Image.new("RGBA", (logo_w, logo_h), (0, 0, 0, 0))
ldraw = ImageDraw.Draw(logo_img)
lcx, lcy = logo_w / 2.0, logo_h / 2.0

# Wooden crest backplate
ldraw.rounded_rectangle([20, 15, logo_w - 20, logo_h - 15], radius=32, fill=(45, 25, 12, 230), outline=(220, 180, 80, 255), width=4)
ldraw.rounded_rectangle([26, 21, logo_w - 26, logo_h - 21], radius=26, fill=(30, 16, 8, 220), outline=(130, 85, 30, 255), width=2)

# Load font or draw bold stylized typography
try:
    font_large = ImageFont.truetype("arialbd.ttf", 76)
    font_small = ImageFont.truetype("arialbd.ttf", 26)
except Exception:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Shadow
ldraw.text((lcx + 3, lcy - 35), "16 GUTI", fill=(0, 0, 0, 220), font=font_large, anchor="mm")
# Gold text
ldraw.text((lcx, lcy - 38), "16 GUTI", fill=(255, 215, 90, 255), font=font_large, anchor="mm")
# Subtitle
ldraw.text((lcx + 2, lcy + 42), "— SHOLO GUTI —", fill=(0, 0, 0, 200), font=font_small, anchor="mm")
ldraw.text((lcx, lcy + 40), "— SHOLO GUTI —", fill=(225, 195, 150, 255), font=font_small, anchor="mm")

logo_img.save(os.path.join(ASSETS_DIR, "game_logo.png"))
print("Saved game_logo.png")

print("Asset generation complete!")
