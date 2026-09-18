import json
import subprocess
import os

# Extract $presets from procut_backend_infinityfree/database/seed_ai_presets.php
cmd = """php -r '
$lines = file("procut_backend_infinityfree/database/seed_ai_presets.php");
$phpExtract = "<?php\\n";
$capturing = false;
foreach ($lines as $l) {
    if (strpos($l, "\\$presets = [") !== false) {
        $capturing = true;
    }
    if ($capturing) {
        $phpExtract .= $l;
        if (trim($l) === "];") {
            break;
        }
    }
}
$phpExtract .= "echo json_encode(\\$presets, JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);\\n";
eval("?>" . $phpExtract);
'"""

res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if res.returncode != 0:
    print("PHP error:", res.stderr)
    exit(1)

presets = json.loads(res.stdout)
print(f"Loaded {len(presets)} presets from seed_ai_presets.php")

# 1. Generate SQL seeder
sql_lines = [
    "-- ProCut AI Presets Seed File",
    "-- Auto-generated for direct import into phpMyAdmin or MySQL CLI",
    "",
    "CREATE TABLE IF NOT EXISTS ai_presets (",
    "    id VARCHAR(64) PRIMARY KEY,",
    "    type ENUM('photo', 'video') NOT NULL DEFAULT 'photo',",
    "    title VARCHAR(255) NOT NULL,",
    "    category VARCHAR(100) NOT NULL DEFAULT 'Trending',",
    "    prompt TEXT NOT NULL,",
    "    negative_prompt TEXT NULL,",
    "    reference_image_url VARCHAR(500) NULL,",
    "    preview_video_url VARCHAR(500) NULL,",
    "    model_name VARCHAR(100) NULL,",
    "    style VARCHAR(100) NULL,",
    "    camera_movement VARCHAR(100) NULL,",
    "    lighting VARCHAR(100) NULL,",
    "    seed VARCHAR(64) NULL,",
    "    duration_text VARCHAR(50) NULL,",
    "    tags VARCHAR(500) NULL,",
    "    is_active TINYINT(1) DEFAULT 1,",
    "    display_order INT DEFAULT 0,",
    "    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,",
    "    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,",
    "    INDEX idx_ai_type (type),",
    "    INDEX idx_ai_order (display_order)",
    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    ""
]

def esc(val):
    if val is None:
        return "NULL"
    s = str(val).replace("\\", "\\\\").replace("'", "''")
    return f"'{s}'"

for p in presets:
    pid = esc(p.get('id'))
    ptype = esc(p.get('type', 'photo'))
    title = esc(p.get('title', 'AI Preset'))
    cat = esc(p.get('category', 'Trending'))
    prompt = esc(p.get('prompt', ''))
    neg = esc(p.get('negative_prompt', 'blurry, low quality, artifacts, distorted'))
    ref_img = esc(p.get('reference_image_url', ''))
    prev_vid = esc(p.get('preview_video_url'))
    model = esc(p.get('model_name', 'Midjourney v6.1'))
    style = esc(p.get('style', 'Cinematic'))
    cam = esc(p.get('camera_movement', '50mm Lens'))
    light = esc(p.get('lighting', 'Volumetric Studio'))
    seed = esc(p.get('seed', '0'))
    dur = esc(p.get('duration_text', '5s' if p.get('type') == 'video' else 'Static'))
    tags = esc(p.get('tags', ''))
    active = int(p.get('is_active', 1))
    order = int(p.get('display_order', 0))

    q = f"""INSERT INTO ai_presets (id, type, title, category, prompt, negative_prompt, reference_image_url, preview_video_url, model_name, style, camera_movement, lighting, seed, duration_text, tags, is_active, display_order)
VALUES ({pid}, {ptype}, {title}, {cat}, {prompt}, {neg}, {ref_img}, {prev_vid}, {model}, {style}, {cam}, {light}, {seed}, {dur}, {tags}, {active}, {order})
ON DUPLICATE KEY UPDATE
    title = VALUES(title), category = VALUES(category), prompt = VALUES(prompt), negative_prompt = VALUES(negative_prompt),
    reference_image_url = VALUES(reference_image_url), preview_video_url = VALUES(preview_video_url), model_name = VALUES(model_name),
    style = VALUES(style), camera_movement = VALUES(camera_movement), lighting = VALUES(lighting), seed = VALUES(seed),
    duration_text = VALUES(duration_text), tags = VALUES(tags), is_active = VALUES(is_active), display_order = VALUES(display_order);"""
    sql_lines.append(q)

sql_content = "\n".join(sql_lines) + "\n"

with open("server/database/seed_ai_presets.sql", "w") as f:
    f.write(sql_content)
with open("procut_backend_infinityfree/database/seed_ai_presets.sql", "w") as f:
    f.write(sql_content)

print("Generated seed_ai_presets.sql in both server/ and procut_backend_infinityfree/")
