import os
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps, ImageDraw

ASSETS_DIR = r"c:\Users\KadiR-PC\Documents\Antigravity\Go_dot\16 GUTI\16-guti\assets\textures"

def create_themes():
    board_base_path = os.path.join(ASSETS_DIR, "board_wood.jpg")
    tabletop_base_path = os.path.join(ASSETS_DIR, "tabletop_bg.jpg")
    
    board_base = Image.open(board_base_path).convert("RGB")
    tabletop_base = Image.open(tabletop_base_path).convert("RGB")
    
    # 1. CLASSIC THEME
    board_base.save(os.path.join(ASSETS_DIR, "board_wood_classic.jpg"), quality=95)
    tabletop_base.save(os.path.join(ASSETS_DIR, "tabletop_classic.jpg"), quality=95)
    print("Created Classic Wood theme assets")
    
    # 2. ROYAL MAHOGANY / ROSEWOOD (Rich deep reddish-chestnut / wine rosewood)
    arr_b = np.array(board_base, dtype=np.float32)
    # Deep lustrous red-brown mahogany
    arr_b[:, :, 0] = np.clip(arr_b[:, :, 0] * 1.05 + 10, 0, 255)
    arr_b[:, :, 1] = np.clip(arr_b[:, :, 1] * 0.68 + 2, 0, 255)
    arr_b[:, :, 2] = np.clip(arr_b[:, :, 2] * 0.52 + 2, 0, 255)
    img_mahogany_b = Image.fromarray(arr_b.astype(np.uint8))
    img_mahogany_b = ImageEnhance.Contrast(img_mahogany_b).enhance(1.18)
    img_mahogany_b = ImageEnhance.Brightness(img_mahogany_b).enhance(0.92)
    img_mahogany_b.save(os.path.join(ASSETS_DIR, "board_wood_mahogany.jpg"), quality=95)
    
    arr_t = np.array(tabletop_base, dtype=np.float32)
    arr_t[:, :, 0] = np.clip(arr_t[:, :, 0] * 1.06 + 8, 0, 255)
    arr_t[:, :, 1] = np.clip(arr_t[:, :, 1] * 0.70 + 2, 0, 255)
    arr_t[:, :, 2] = np.clip(arr_t[:, :, 2] * 0.54 + 2, 0, 255)
    img_mahogany_t = Image.fromarray(arr_t.astype(np.uint8))
    img_mahogany_t = ImageEnhance.Contrast(img_mahogany_t).enhance(1.15)
    img_mahogany_t = ImageEnhance.Brightness(img_mahogany_t).enhance(0.90)
    img_mahogany_t.save(os.path.join(ASSETS_DIR, "tabletop_mahogany.jpg"), quality=95)
    print("Created Royal Mahogany theme assets")
    
    # 3. IVORY MAPLE / LIGHT BIRCH THEME (Light Mode)
    arr_lb = np.array(board_base, dtype=np.float32)
    norm = arr_lb / 255.0
    lifted = np.power(norm, 0.44)
    out_r = np.clip(lifted[:, :, 0] * 238.0 + 16.0, 0, 255)
    out_g = np.clip(lifted[:, :, 1] * 218.0 + 22.0, 0, 255)
    out_b = np.clip(lifted[:, :, 2] * 188.0 + 32.0, 0, 255)
    arr_light_b = np.stack([out_r, out_g, out_b], axis=2)
    img_light_b = Image.fromarray(arr_light_b.astype(np.uint8))
    img_light_b = ImageEnhance.Contrast(img_light_b).enhance(1.08)
    
    w_b, h_b = img_light_b.size
    overlay_lb = Image.new("RGBA", (w_b, h_b), (0, 0, 0, 0))
    draw_lb = ImageDraw.Draw(overlay_lb)
    for i in range(40):
        a = int(85 * (1.0 - i / 40.0))
        draw_lb.rectangle([i, i, w_b - 1 - i, h_b - 1 - i], outline=(110, 85, 55, a))
    inlay = 48
    draw_lb.rectangle([inlay, inlay, w_b - 1 - inlay, h_b - 1 - inlay], outline=(150, 115, 65, 170), width=3)
    draw_lb.rectangle([inlay + 2, inlay + 2, w_b - 1 - inlay - 2, h_b - 1 - inlay - 2], outline=(80, 58, 35, 150), width=2)
    overlay_lb = overlay_lb.filter(ImageFilter.GaussianBlur(0.8))
    img_light_b = Image.alpha_composite(img_light_b.convert("RGBA"), overlay_lb).convert("RGB")
    img_light_b.save(os.path.join(ASSETS_DIR, "board_wood_light.jpg"), quality=95)
    
    arr_lt = np.array(tabletop_base, dtype=np.float32)
    norm_t = arr_lt / 255.0
    lifted_t = np.power(norm_t, 0.42)
    out_tr = np.clip(lifted_t[:, :, 0] * 232.0 + 22.0, 0, 255)
    out_tg = np.clip(lifted_t[:, :, 1] * 214.0 + 26.0, 0, 255)
    out_tb = np.clip(lifted_t[:, :, 2] * 186.0 + 36.0, 0, 255)
    arr_light_t = np.stack([out_tr, out_tg, out_tb], axis=2)
    img_light_t = Image.fromarray(arr_light_t.astype(np.uint8))
    img_light_t = ImageEnhance.Contrast(img_light_t).enhance(1.06)
    img_light_t.save(os.path.join(ASSETS_DIR, "tabletop_light.jpg"), quality=95)
    print("Created Ivory Maple (Light Mode) theme assets")

if __name__ == "__main__":
    create_themes()
