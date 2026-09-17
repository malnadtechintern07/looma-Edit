import re
import os

dart_file = '/Users/apple/Desktop/ProCut/lib/features/ai_photo_edit/data/ai_photo_presets_data.dart'
with open(dart_file, 'r', encoding='utf-8') as f:
    dart_content = f.read()

pattern = re.compile(
    r"const AiPhotoPresetEntity\(\s*"
    r"id:\s*'([^']+)',\s*"
    r"title:\s*'([^']+)',\s*"
    r"category:\s*'([^']+)',\s*"
    r"badgeText:\s*'([^']+)',\s*"
    r"referenceImagePath:\s*'([^']+)',\s*"
    r"likesCount:\s*(\d+),\s*"
    r"aspectRatio:\s*'([^']+)',\s*"
    r"styleKeywords:\s*\[([^\]]+)\],\s*"
    r"prompt:\s*\n?\s*'([^']+)',"
    r"(?:\s*negativePrompt:\s*'([^']+)',)?"
    r"(?:\s*modelRecommendation:\s*'([^']+)',)?"
    r"(?:\s*lightingStyle:\s*'([^']+)',)?"
    r"(?:\s*cameraLens:\s*'([^']+)',)?",
    re.MULTILINE
)

matches = pattern.findall(dart_content)
print(f"Found {len(matches)} presets in Dart file")

php_presets = []
order = 1
for m in matches:
    pid, title, cat, badge, ref_img, likes, aspect, keywords_str, prompt, neg, model, light, cam = m
    
    tags = [k.strip().strip("'\"") for k in keywords_str.split(',') if k.strip()]
    tags_str = ', '.join(tags)
    
    neg = neg if neg else 'blurry, low resolution, bad anatomy, deformed limbs, watermark, cartoonish artifacts'
    model = model if model else 'Flux.1 Pro'
    light = light if light else 'Cinematic Lighting'
    cam = cam if cam else '85mm f/1.4 Portrait Prime'
    seed = str(1000000 + order * 83721)
    
    esc_title = title.replace("'", "\\'")
    esc_cat = cat.replace("'", "\\'")
    esc_prompt = prompt.replace("'", "\\'")
    esc_neg = neg.replace("'", "\\'")
    esc_model = model.replace("'", "\\'")
    esc_cam = cam.replace("'", "\\'")
    esc_light = light.replace("'", "\\'")
    esc_tags = tags_str.replace("'", "\\'")
    
    entry = f"""    [
        'id' => '{pid}',
        'type' => 'photo',
        'title' => '{esc_title}',
        'category' => '{esc_cat}',
        'prompt' => '{esc_prompt}',
        'negative_prompt' => '{esc_neg}',
        'reference_image_url' => '{ref_img}',
        'preview_video_url' => null,
        'model_name' => '{esc_model}',
        'style' => '{esc_cat} AI Art',
        'camera_movement' => '{esc_cam}',
        'lighting' => '{esc_light}',
        'seed' => '{seed}',
        'tags' => '{esc_tags}',
        'is_active' => 1,
        'display_order' => {order},
    ],"""
    php_presets.append(entry)
    order += 1

all_php_presets_code = '\n'.join(php_presets)

def update_php_seed(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    marker_start = "// ── AI PHOTO PRESETS ──"
    marker_end = "// ── AI VIDEO PRESETS (with playable video previews) ──"

    idx_start = content.find(marker_start)
    idx_end = content.find(marker_end)

    if idx_start == -1 or idx_end == -1:
        print(f"Could not find markers in {path}")
        return

    new_content = (
        content[:idx_start] +
        marker_start + "\n" +
        all_php_presets_code + "\n\n    " +
        content[idx_end:]
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated {path} successfully with {len(php_presets)} photo presets.")

update_php_seed('/Users/apple/Desktop/ProCut/server/database/seed_ai_presets.php')
update_php_seed('/Users/apple/Desktop/ProCut/procut_backend_infinityfree/database/seed_ai_presets.php')
