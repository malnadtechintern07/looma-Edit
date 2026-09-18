import json
import subprocess

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
    print("Error extracting presets:", res.stderr)
    exit(1)

presets = json.loads(res.stdout)
print(f"Loaded {len(presets)} presets")

sync_script = f'''<?php
/**
 * ProCut - 1-Click AI Presets Live Cloud Seeder & Sync
 * Access URL: http://procut.free.nf/sync_ai_presets.php
 */

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/database.php';

// Auto-create ai_presets table if it does not exist
try {{
    Database::query("
        CREATE TABLE IF NOT EXISTS ai_presets (
            id VARCHAR(64) PRIMARY KEY,
            type ENUM('photo', 'video') NOT NULL DEFAULT 'photo',
            title VARCHAR(255) NOT NULL,
            category VARCHAR(100) NOT NULL DEFAULT 'Trending',
            prompt TEXT NOT NULL,
            negative_prompt TEXT NULL,
            reference_image_url VARCHAR(500) NULL,
            preview_video_url VARCHAR(500) NULL,
            model_name VARCHAR(100) NULL,
            style VARCHAR(100) NULL,
            camera_movement VARCHAR(100) NULL,
            lighting VARCHAR(100) NULL,
            seed VARCHAR(64) NULL,
            duration_text VARCHAR(50) NULL,
            tags VARCHAR(500) NULL,
            is_active TINYINT(1) DEFAULT 1,
            display_order INT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_ai_type (type),
            INDEX idx_ai_order (display_order)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
}} catch (Throwable $e) {{
    // table might already exist
}}

// Preset data definition
$presetsJson = <<<'JSONDATA'
{json.dumps(presets, ensure_ascii=False)}
JSONDATA;

$presets = json_decode($presetsJson, true);
$inserted = 0;
$updated = 0;
$photoCount = 0;
$videoCount = 0;

foreach ($presets as $p) {{
    if (($p['type'] ?? 'photo') === 'video') {{
        $videoCount++;
    }} else {{
        $photoCount++;
    }}

    $id = $p['id'];
    $exists = Database::fetchOne("SELECT id FROM ai_presets WHERE id = ?", [$id]);

    $type = $p['type'] ?? 'photo';
    $title = $p['title'] ?? 'AI Preset';
    $cat = $p['category'] ?? 'Trending';
    $prompt = $p['prompt'] ?? '';
    $neg = $p['negative_prompt'] ?? 'blurry, low quality, artifacts, distorted';
    $refImg = $p['reference_image_url'] ?? '';
    $prevVid = $p['preview_video_url'] ?? null;
    $model = $p['model_name'] ?? 'Midjourney v6.1';
    $style = $p['style'] ?? 'Cinematic';
    $cam = $p['camera_movement'] ?? '50mm Lens';
    $light = $p['lighting'] ?? 'Volumetric Studio';
    $seed = $p['seed'] ?? '0';
    $dur = $p['duration_text'] ?? ($type === 'video' ? '5s' : 'Static');
    $tags = $p['tags'] ?? '';
    $active = (int)($p['is_active'] ?? 1);
    $order = (int)($p['display_order'] ?? 0);

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
        [$id, $type, $title, $cat, $prompt, $neg, $refImg, $prevVid, $model, $style, $cam, $light, $seed, $dur, $tags, $active, $order]
    );

    if ($exists) {{
        $updated++;
    }} else {{
        $inserted++;
    }}
}}

// JSON response if requested via API or Curl
if (isset($_GET['format']) && $_GET['format'] === 'json') {{
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status' => 'success',
        'message' => 'AI Presets successfully synced to database',
        'total' => count($presets),
        'photos' => $photoCount,
        'videos' => $videoCount,
        'inserted' => $inserted,
        'updated' => $updated,
        'timestamp' => date('c')
    ], JSON_PRETTY_PRINT);
    exit;
}}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ProCut AI Presets Sync — Complete</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        body {{
            font-family: 'Plus Jakarta Sans', -apple-system, sans-serif;
            background: #0B0F19;
            color: #F3F4F6;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }}
        .sync-card {{
            background: linear-gradient(180deg, rgba(26, 32, 53, 0.95) 0%, rgba(17, 24, 39, 0.98) 100%);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.7), 0 0 40px rgba(121, 40, 202, 0.15);
            max-width: 680px;
            width: 100%;
            padding: 36px;
        }}
        .badge-pro {{
            background: linear-gradient(135deg, #7928CA, #FF0080);
            color: #fff;
            font-weight: 700;
            padding: 6px 14px;
            border-radius: 50px;
            font-size: 0.75rem;
            letter-spacing: 0.05em;
        }}
        .stat-box {{
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 16px;
            padding: 18px 20px;
            text-align: center;
        }}
        .stat-num {{
            font-size: 2.2rem;
            font-weight: 800;
            line-height: 1;
            margin-bottom: 6px;
        }}
        .btn-gradient {{
            background: linear-gradient(135deg, #7928CA 0%, #FF0080 100%);
            border: none;
            color: #fff;
            font-weight: 600;
            border-radius: 14px;
            padding: 12px 28px;
            transition: all 0.2s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }}
        .btn-gradient:hover {{
            color: #fff;
            opacity: 0.95;
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(255, 0, 128, 0.3);
        }}
    </style>
</head>
<body>
    <div class="sync-card text-center">
        <div class="d-inline-flex align-items-center gap-2 mb-3">
            <span class="badge-pro"><i class="bi bi-stars me-1"></i>PRO GENERATIVE AI</span>
        </div>
        <h2 class="fw-bold mb-2 text-white">AI Presets Successfully Synced! 🎉</h2>
        <p class="text-secondary small mb-4">All latest AI Photo & Video prompt presets have been securely written to your live MySQL database.</p>

        <div class="row g-3 mb-4">
            <div class="col-4">
                <div class="stat-box">
                    <div class="stat-num text-primary"><?= number_format($photoCount) ?></div>
                    <div class="small text-muted fw-semibold">AI Photos</div>
                </div>
            </div>
            <div class="col-4">
                <div class="stat-box">
                    <div class="stat-num" style="color: #FF0080;"><?= number_format($videoCount) ?></div>
                    <div class="small text-muted fw-semibold">AI Videos</div>
                </div>
            </div>
            <div class="col-4">
                <div class="stat-box">
                    <div class="stat-num text-success"><?= number_format(count($presets)) ?></div>
                    <div class="small text-muted fw-semibold">Total Presets</div>
                </div>
            </div>
        </div>

        <div class="alert alert-dark border-secondary text-start small mb-4 py-2 px-3 d-flex align-items-center justify-content-between">
            <span><i class="bi bi-check-circle-fill text-success me-2"></i><strong>Database Updated:</strong> <?= $inserted ?> new presets added, <?= $updated ?> presets verified/updated.</span>
            <span class="badge bg-secondary"><?= date('H:i:s') ?> UTC</span>
        </div>

        <div class="d-flex justify-content-center gap-3 flex-wrap">
            <a href="/admin/ai_edits.php" class="btn-gradient">
                <i class="bi bi-speedometer2"></i> Open Admin Panel AI Studio
            </a>
            <a href="/api/ai/presets.php" target="_blank" class="btn btn-outline-light rounded-3 px-4 py-2 d-inline-flex align-items-center gap-2">
                <i class="bi bi-code-slash"></i> View Presets API
            </a>
        </div>
    </div>
</body>
</html>
'''

with open("server/sync_ai_presets.php", "w") as f:
    f.write(sync_script)

with open("procut_backend_infinityfree/sync_ai_presets.php", "w") as f:
    f.write(sync_script)

print("Generated sync_ai_presets.php in server/ and procut_backend_infinityfree/")
