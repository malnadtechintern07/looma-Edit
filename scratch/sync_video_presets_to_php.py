import re
import json
import subprocess

# Read video presets from Dart
with open('lib/features/ai_video_edit/data/ai_video_presets_data.dart') as f:
    dart_code = f.read()

# Extract presets from Dart
preset_blocks = re.findall(r'AiVideoPresetEntity\((.*?)\),', dart_code, re.DOTALL)
print(f"Found {len(preset_blocks)} video presets in Dart")

video_presets = []
for block in preset_blocks:
    def get_field(name):
        m = re.search(r'\b' + name + r':\s*[\x27\x22](.*?)[\x27\x22]\s*,', block, re.DOTALL)
        if m:
            return m.group(1).strip()
        return None
    
    tags_m = re.search(r'tags:\s*\[(.*?)\]', block, re.DOTALL)
    tags_list = []
    if tags_m:
        tags_raw = tags_m.group(1)
        tags_list = [t.strip().strip("'\"") for t in tags_raw.split(',') if t.strip()]

    pid = get_field('id')
    title = get_field('title')
    cat = get_field('category')
    video_path = get_field('videoAssetPath')
    dur = get_field('durationText') or '5s'
    model = get_field('modelName') or 'OpenAI Sora'
    style = get_field('style') or 'Cinematic'
    cam = get_field('cameraMovement') or 'Smooth Dolly'
    light = get_field('lighting') or 'Volumetric Atmospheric'
    seed = get_field('seed') or '0'
    prompt = get_field('prompt')
    neg = get_field('negativePrompt') or 'blurry, low resolution, artifacts'

    video_presets.append({
        'id': pid,
        'type': 'video',
        'title': title,
        'category': cat,
        'prompt': prompt,
        'negative_prompt': neg,
        'reference_image_url': '',
        'preview_video_url': video_path,
        'model_name': model,
        'style': style,
        'camera_movement': cam,
        'lighting': light,
        'seed': seed,
        'duration_text': dur,
        'tags': ', '.join(tags_list),
        'is_active': 1,
        'display_order': 200 + len(video_presets)
    })

print(f"Parsed {len(video_presets)} video presets.")

# Now let's update scratch/generate_all_seeders.py and scratch/make_sync_script.py
# First read current PHP seed_ai_presets.php
with open('procut_backend_infinityfree/database/seed_ai_presets.php') as f:
    php_content = f.read()

# Replace or re-generate all seeders
# Let's extract existing photo presets from PHP
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
all_existing = json.loads(res.stdout)
photo_presets = [p for p in all_existing if p.get('type') == 'photo']
print(f"Loaded {len(photo_presets)} existing photo presets.")

# Combine photo presets + new video presets
combined_presets = photo_presets + video_presets
print(f"Combined total: {len(combined_presets)} presets ({len(photo_presets)} photos, {len(video_presets)} videos)")

# Write updated seed_ai_presets.php
php_output = '''<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

echo "Seeding AI Presets...\\n";

$presets = [
'''

for p in combined_presets:
    php_output += "    [\n"
    php_output += f"        'id' => '{p.get('id', '')}',\n"
    php_output += f"        'type' => '{p.get('type', 'photo')}',\n"
    title_esc = str(p.get('title', '')).replace("'", "\\'")
    php_output += f"        'title' => '{title_esc}',\n"
    cat_esc = str(p.get('category', '')).replace("'", "\\'")
    php_output += f"        'category' => '{cat_esc}',\n"
    prompt_esc = str(p.get('prompt', '')).replace("'", "\\'")
    php_output += f"        'prompt' => '{prompt_esc}',\n"
    neg_esc = str(p.get('negative_prompt', '')).replace("'", "\\'")
    php_output += f"        'negative_prompt' => '{neg_esc}',\n"
    ref_esc = str(p.get('reference_image_url', '')).replace("'", "\\'")
    php_output += f"        'reference_image_url' => '{ref_esc}',\n"
    prev_vid = p.get('preview_video_url')
    if prev_vid:
        prev_vid_esc = str(prev_vid).replace("'", "\\'")
        php_output += f"        'preview_video_url' => '{prev_vid_esc}',\n"
    else:
        php_output += "        'preview_video_url' => null,\n"
    model_esc = str(p.get('model_name', '')).replace("'", "\\'")
    php_output += f"        'model_name' => '{model_esc}',\n"
    style_esc = str(p.get('style', '')).replace("'", "\\'")
    php_output += f"        'style' => '{style_esc}',\n"
    cam_esc = str(p.get('camera_movement', '')).replace("'", "\\'")
    php_output += f"        'camera_movement' => '{cam_esc}',\n"
    light_esc = str(p.get('lighting', '')).replace("'", "\\'")
    php_output += f"        'lighting' => '{light_esc}',\n"
    seed_esc = str(p.get('seed', '0')).replace("'", "\\'")
    php_output += f"        'seed' => '{seed_esc}',\n"
    dur_esc = str(p.get('duration_text', '5s' if p.get('type') == 'video' else 'Static')).replace("'", "\\'")
    php_output += f"        'duration_text' => '{dur_esc}',\n"
    tags_esc = str(p.get('tags', '')).replace("'", "\\'")
    php_output += f"        'tags' => '{tags_esc}',\n"
    php_output += f"        'is_active' => {p.get('is_active', 1)},\n"
    php_output += f"        'display_order' => {p.get('display_order', 0)},\n"
    php_output += "    ],\n"

php_output += '''
];

foreach ($presets as $p) {
    Database::query(
        "INSERT INTO ai_presets (id, type, title, category, prompt, negative_prompt, reference_image_url, preview_video_url, model_name, style, camera_movement, lighting, seed, duration_text, tags, is_active, display_order)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            title = VALUES(title),
            category = VALUES(category),
            prompt = VALUES(prompt),
            negative_prompt = VALUES(negative_prompt),
            reference_image_url = VALUES(reference_image_url),
            preview_video_url = VALUES(preview_video_url),
            model_name = VALUES(model_name),
            style = VALUES(style),
            camera_movement = VALUES(camera_movement),
            lighting = VALUES(lighting),
            seed = VALUES(seed),
            duration_text = VALUES(duration_text),
            tags = VALUES(tags),
            is_active = VALUES(is_active),
            display_order = VALUES(display_order)",
        [
            $p['id'],
            $p['type'] ?? 'photo',
            $p['title'] ?? 'AI Preset',
            $p['category'] ?? 'Trending',
            $p['prompt'] ?? '',
            $p['negative_prompt'] ?? 'blurry, low quality, artifacts, distorted',
            $p['reference_image_url'] ?? '',
            $p['preview_video_url'] ?? null,
            $p['model_name'] ?? 'Midjourney v6.1',
            $p['style'] ?? 'Cinematic',
            $p['camera_movement'] ?? '50mm Lens',
            $p['lighting'] ?? 'Volumetric Studio',
            $p['seed'] ?? '0',
            $p['duration_text'] ?? (($p['type'] ?? 'photo') === 'video' ? '5s' : 'Static'),
            $p['tags'] ?? '',
            $p['is_active'] ?? 1,
            $p['display_order'] ?? 0,
        ]
    );
}

echo "Successfully seeded " . count($presets) . " AI Presets.\\n";

// Update existing templates with video generation prompts
$templatePrompts = [
    'tmpl-viral-phonk' => 'Ultra-fast rhythmic cut video edit synced to Brazilian phonk drift bass beat, drift racing car tires smoking at night with hyper neon motion blur, chromatic aberration camera shake on drops.',
    'tmpl-golden-hour' => 'Dreamy slow-motion 120fps golden hour travel montage, warm backlit lens flare, couple walking on beach shoreline, nostalgic cinematic Kodak Portra 35mm grain.',
    'tmpl-cinematic-youtube' => 'Wide 2.39:1 anamorphic cinematic documentary B-roll sequence, majestic drone swooping over misty pine forest mountain ridge, orchestral swelling music with smooth gimbal tracking.',
    'tmpl-summer-tropical' => 'High-energy vibrant tropical island vacation montage, cliff diving into turquoise ocean, drone overhead top-down view of coral reef, rapid speed ramps and seamless whip transitions.',
    'tmpl-retro-90s' => 'Authentic 1990s VHS camcorder aesthetic, retro tracking distortion lines, timestamp watermark at bottom left, skate park stunts with fish-eye lens and nostalgic punk rock soundtrack.',
    'tmpl-urban-street' => 'Fast-paced street style fashion lookbook, downtown city neon reflections in puddles, glitch transitions, rhythmic jump cuts to heavy 808 trap beat.',
    'tmpl-vlog-minimal' => 'Aesthetic minimal daily morning routine vlog, warm natural daylight through apartment window, brewing pour-over coffee, soft ambient lofi music with clean typographic overlays.',
    'tmpl-hype-reel' => 'Dynamic social media teaser reel with kinetic typography, high-contrast black and electric blue flash frames, aggressive zoom-in impacts on beat drops.',
];

foreach ($templatePrompts as $tmplId => $prompt) {
    Database::query(
        "UPDATE templates SET prompt = ? WHERE id = ? AND (prompt IS NULL OR prompt = '')",
        [$prompt, $tmplId]
    );
}

echo "Successfully updated templates with video editing prompts.\\n";
'''

with open('server/database/seed_ai_presets.php', 'w') as f:
    f.write(php_output)
with open('procut_backend_infinityfree/database/seed_ai_presets.php', 'w') as f:
    f.write(php_output)

print("Saved updated seed_ai_presets.php to server/ and procut_backend_infinityfree/")
