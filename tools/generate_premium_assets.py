import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "textures")
os.makedirs(ASSETS_DIR, exist_ok=True)

def create_piece_shadow():
    """Soft realistic ground contact drop shadow"""
    size = 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    rx, ry = 72, 60 # Slightly elliptical for 2.5D perspective
    
    # Concentric soft layers
    for r in range(rx, 10, -3):
        frac = (r - 10) / (rx - 10)
        alpha = int(140 * (1.0 - frac**1.2))
        erx = int(r)
        ery = int(r * (ry / rx))
        draw.ellipse([cx - erx, cy - ery + 4, cx + erx, cy + ery + 4], fill=(12, 6, 2, alpha))
        
    img = img.filter(ImageFilter.GaussianBlur(5.0))
    img.save(os.path.join(ASSETS_DIR, "piece_shadow.png"))
    print("Saved piece_shadow.png")

def create_premium_pieces():
    """Create hyper-realistic 2.5D game pieces: Red Lacquer and Ivory Porcelain"""
    size = 512
    cx, cy = size / 2.0, size / 2.0
    radius = 210.0
    
    y, x = np.ogrid[:size, :size]
    dist = np.sqrt((x - cx)**2 + (y - cy)**2)
    norm_dist = np.clip(dist / radius, 0.0, 1.0)
    
    # 3D Normal Sphere approximation
    # z = sqrt(1 - (x^2 + y^2))
    z = np.sqrt(np.maximum(0.0, 1.0 - norm_dist**1.8))
    
    # Light vector (coming from top-left, slightly toward camera: [-0.45, -0.65, 0.61])
    lx, ly, lz = -0.45, -0.65, 0.61
    l_mag = math.sqrt(lx*lx + ly*ly + lz*lz)
    lx, ly, lz = lx/l_mag, ly/l_mag, lz/l_mag
    
    # Surface normals
    nx = np.where(dist <= radius, (x - cx) / radius, 0.0)
    ny = np.where(dist <= radius, (y - cy) / radius, 0.0)
    nz = z
    
    # Diffuse shading (N dot L)
    n_dot_l = np.clip(nx * lx + ny * ly + nz * lz, 0.0, 1.0)
    
    # Specular shading (Blinn-Phong)
    # View vector is [0, 0, 1]
    hx, hy, hz = lx, ly, lz + 1.0
    h_mag = np.sqrt(hx*hx + hy*hy + hz*hz)
    hx, hy, hz = hx/h_mag, hy/h_mag, hz/h_mag
    n_dot_h = np.clip(nx * hx + ny * hy + nz * hz, 0.0, 1.0)
    specular_sharp = np.power(n_dot_h, 36.0)
    specular_soft = np.power(n_dot_h, 12.0)
    
    # Secondary rim light from bottom-right [0.5, 0.5, 0.3]
    rx_l, ry_l, rz_l = 0.5, 0.5, 0.3
    rl_mag = math.sqrt(rx_l**2 + ry_l**2 + rz_l**2)
    rim = np.clip(nx * (rx_l/rl_mag) + ny * (ry_l/rl_mag) + nz * (rz_l/rl_mag), 0.0, 1.0)
    rim_pow = (1.0 - nz)**2 * rim * 0.4
    
    # Brass outer ring region: between radius*0.84 and radius*0.96
    is_brass = (dist >= radius * 0.83) & (dist <= radius * 0.96)
    
    # Chamfer/bevel step at radius * 0.83
    inner_dome = dist < radius * 0.83
    
    # Antialiased alpha edge
    alpha = np.zeros((size, size), dtype=np.uint8)
    inside = dist <= radius
    alpha[inside] = 255
    edge = (dist > radius) & (dist <= radius + 2.5)
    alpha[edge] = (np.clip(1.0 - (dist[edge] - radius) / 2.5, 0, 1) * 255).astype(np.uint8)
    
    # --- 1. PLAYER 1: DEEP GLOSSY RUBY RED PIECE ---
    red_arr = np.zeros((size, size, 4), dtype=np.uint8)
    
    # Ambient + Diffuse base
    # Deep crimson red gradient: [130, 10, 20] to [210, 30, 45]
    base_r = 85.0 + n_dot_l * 125.0 + inner_dome * 20.0
    base_g = 8.0 + n_dot_l * 28.0
    base_b = 14.0 + n_dot_l * 38.0
    
    # Brass ring colors
    brass_r = 180.0 + n_dot_l * 70.0
    brass_g = 135.0 + n_dot_l * 65.0
    brass_b = 55.0 + n_dot_l * 40.0
    
    # Combine with brass
    r_channel = np.where(is_brass, brass_r, base_r)
    g_channel = np.where(is_brass, brass_g, base_g)
    b_channel = np.where(is_brass, brass_b, base_b)
    
    # Add glossy specular catchlight & rim
    r_channel += (specular_sharp * 180.0 + specular_soft * 45.0 + rim_pow * 60.0)
    g_channel += (specular_sharp * 160.0 + specular_soft * 35.0 + rim_pow * 45.0)
    b_channel += (specular_sharp * 140.0 + specular_soft * 30.0 + rim_pow * 45.0)
    
    # Inner circular decorative groove on top face (radius * 0.48)
    groove_dist = np.abs(dist - radius * 0.48)
    groove = np.exp(-groove_dist**2 / 12.0)
    r_channel -= groove * 45.0
    g_channel -= groove * 15.0
    b_channel -= groove * 15.0
    
    red_arr[:, :, 0] = np.clip(r_channel, 0, 255).astype(np.uint8)
    red_arr[:, :, 1] = np.clip(g_channel, 0, 255).astype(np.uint8)
    red_arr[:, :, 2] = np.clip(b_channel, 0, 255).astype(np.uint8)
    red_arr[:, :, 3] = alpha
    
    red_img = Image.fromarray(red_arr)
    red_img.save(os.path.join(ASSETS_DIR, "piece_red.png"))
    print("Saved premium piece_red.png")
    
    # --- 2. PLAYER 2: PREMIUM IVORY / CREAM PORCELAIN PIECE ---
    ivory_arr = np.zeros((size, size, 4), dtype=np.uint8)
    
    # Warm ivory base: [205, 198, 185] with smooth lighting
    iv_base_r = 175.0 + n_dot_l * 60.0 + inner_dome * 10.0
    iv_base_g = 170.0 + n_dot_l * 60.0 + inner_dome * 10.0
    iv_base_b = 158.0 + n_dot_l * 62.0 + inner_dome * 10.0
    
    # Ivory with brass ring
    r_iv = np.where(is_brass, brass_r * 0.95 + 15, iv_base_r)
    g_iv = np.where(is_brass, brass_g * 0.95 + 15, iv_base_g)
    b_iv = np.where(is_brass, brass_b * 0.95 + 15, iv_base_b)
    
    # Specular catchlight on polished porcelain
    r_iv += (specular_sharp * 140.0 + specular_soft * 40.0 + rim_pow * 40.0)
    g_iv += (specular_sharp * 140.0 + specular_soft * 40.0 + rim_pow * 40.0)
    b_iv += (specular_sharp * 140.0 + specular_soft * 40.0 + rim_pow * 40.0)
    
    # Inner circular groove
    r_iv -= groove * 35.0
    g_iv -= groove * 35.0
    b_iv -= groove * 35.0
    
    ivory_arr[:, :, 0] = np.clip(r_iv, 0, 255).astype(np.uint8)
    ivory_arr[:, :, 1] = np.clip(g_iv, 0, 255).astype(np.uint8)
    ivory_arr[:, :, 2] = np.clip(b_iv, 0, 255).astype(np.uint8)
    ivory_arr[:, :, 3] = alpha
    
    ivory_img = Image.fromarray(ivory_arr)
    ivory_img.save(os.path.join(ASSETS_DIR, "piece_ivory.png"))
    print("Saved premium piece_ivory.png")

def create_board_socket():
    """Metallic recessed brass socket for board nodes"""
    size = 128
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2.0, size / 2.0
    
    # Outer carved drop shadow in wood
    draw.ellipse([cx - 46, cy - 46 + 2, cx + 46, cy + 46 + 2], fill=(18, 10, 4, 110))
    # Brass outer bevel
    draw.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(160, 125, 60, 240))
    # Brass bright rim
    draw.ellipse([cx - 37, cy - 37, cx + 37, cy + 37], fill=(225, 185, 105, 255))
    # Inner shadow transition
    draw.ellipse([cx - 31, cy - 31, cx + 31, cy + 31], fill=(60, 35, 15, 255))
    # Deep recessed center socket
    draw.ellipse([cx - 26, cy - 26, cx + 26, cy + 26], fill=(25, 12, 5, 255))
    # Upper-left light catch on brass rim
    draw.arc([cx - 37, cy - 37, cx + 37, cy + 37], start=210, end=330, fill=(255, 235, 170, 255), width=3)
    # Bottom-right shadow in pit
    draw.arc([cx - 26, cy - 26, cx + 26, cy + 26], start=30, end=150, fill=(12, 6, 2, 255), width=3)
    
    img = img.filter(ImageFilter.GaussianBlur(0.7))
    img.save(os.path.join(ASSETS_DIR, "node_socket.png"))
    print("Saved node_socket.png")

def create_highlights():
    """Soft pulsing destination and capture indicators"""
    size = 144
    cx, cy = size / 2.0, size / 2.0
    
    # 1. Valid move destination (soft glowing emerald ring with inner core)
    move_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(move_img)
    for r in range(48, 20, -2):
        frac = (r - 20) / 28.0
        alpha = int(140 * (1.0 - frac**1.4))
        mdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(45, 230, 130, alpha))
    mdraw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=(85, 255, 165, 220))
    mdraw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(225, 255, 240, 255))
    move_img = move_img.filter(ImageFilter.GaussianBlur(1.2))
    move_img.save(os.path.join(ASSETS_DIR, "move_highlight.png"))
    print("Saved move_highlight.png")
    
    # 2. Capture destination (fiery amber/ruby capture ring)
    cap_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(cap_img)
    for r in range(54, 22, -2):
        frac = (r - 22) / 32.0
        alpha = int(170 * (1.0 - frac**1.3))
        cdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 130, 20, alpha))
    cdraw.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(255, 65, 35, 235))
    cdraw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=(255, 215, 140, 255))
    cap_img = cap_img.filter(ImageFilter.GaussianBlur(1.2))
    cap_img.save(os.path.join(ASSETS_DIR, "capture_highlight.png"))
    print("Saved capture_highlight.png")
    
    # 3. Selection halo (large golden aura)
    sel_size = 256
    sel_img = Image.new("RGBA", (sel_size, sel_size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sel_img)
    scx, scy = sel_size / 2.0, sel_size / 2.0
    for r in range(120, 80, -2):
        frac = (r - 80) / 40.0
        alpha = int(180 * math.sin(frac * math.pi))
        sdraw.ellipse([scx - r, scy - r, scx + r, scy + r], outline=(255, 210, 60, alpha), width=3)
    sdraw.ellipse([scx - 100, scy - 100, scx + 100, scy + 100], outline=(255, 240, 140, 240), width=4)
    sel_img = sel_img.filter(ImageFilter.GaussianBlur(2.5))
    sel_img.save(os.path.join(ASSETS_DIR, "piece_selected_glow.png"))
    print("Saved piece_selected_glow.png")

def create_particles():
    """Diamond sparkle particle for capture & victory effects"""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    
    # Diamond / 4-point star
    pts = [
        (cx, cy - 26),
        (cx + 8, cy - 8),
        (cx + 26, cy),
        (cx + 8, cy + 8),
        (cx, cy + 26),
        (cx - 8, cy + 8),
        (cx - 26, cy),
        (cx - 8, cy - 8)
    ]
    draw.polygon(pts, fill=(255, 235, 160, 255))
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255, 255))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    img.save(os.path.join(ASSETS_DIR, "particle_sparkle.png"))
    print("Saved particle_sparkle.png")

def create_board_wood_frame():
    """Enhance the board wood texture with a handcrafted wooden bevel border & ambient occlusion"""
    board_path = os.path.join(ASSETS_DIR, "board_wood.jpg")
    if not os.path.exists(board_path):
        return
    img = Image.open(board_path).convert("RGBA")
    w, h = img.size
    
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Outer dark chamfer (border width 42px)
    bw = 42
    # Outer dark shadow vignette
    for i in range(bw):
        alpha = int(120 * (1.0 - i / float(bw)))
        draw.rectangle([i, i, w - 1 - i, h - 1 - i], outline=(15, 8, 3, alpha))
        
    # Golden inlay groove line inside the wooden bevel
    inlay = bw + 8
    draw.rectangle([inlay, inlay, w - 1 - inlay, h - 1 - inlay], outline=(220, 175, 75, 140), width=3)
    draw.rectangle([inlay + 2, inlay + 2, w - 1 - inlay - 2, h - 1 - inlay - 2], outline=(25, 12, 4, 180), width=2)
    
    overlay = overlay.filter(ImageFilter.GaussianBlur(1.0))
    combined = Image.alpha_composite(img, overlay).convert("RGB")
    combined.save(os.path.join(ASSETS_DIR, "board_wood.jpg"), quality=95)
    print("Saved enhanced board_wood.jpg with carved mitered frame")

if __name__ == "__main__":
    create_piece_shadow()
    create_premium_pieces()
    create_board_socket()
    create_highlights()
    create_particles()
    create_board_wood_frame()
    print("All premium visual assets successfully generated!")
