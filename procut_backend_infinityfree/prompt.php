<?php
/**
 * ProCut AI Studio - Prompt Share & Landing Page
 * Allows anyone with the shared link to view the prompt name, preview, 
 * download ProCut app, and copy the full pro prompt.
 */

// Buffer output
if (!ob_get_level()) {
    @ob_start();
}

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/helpers/database.php';

$presetId = trim($_GET['id'] ?? '');
$titleParam = trim($_GET['title'] ?? '');
$catParam = trim($_GET['cat'] ?? $_GET['category'] ?? '');
$imgParam = trim($_GET['img'] ?? '');

$preset = null;

// Attempt database lookup if ID provided
if (!empty($presetId)) {
    try {
        $preset = Database::fetchOne("SELECT * FROM ai_presets WHERE id = ?", [$presetId]);
    } catch (\Throwable $e) {
        // Fallback gracefully
    }
}

// Fallback to query params or defaults
$title = $preset['title'] ?? ($titleParam ?: 'Cyberpunk Neon City');
$category = $preset['category'] ?? ($catParam ?: 'Cyberpunk Style');
$prompt = $preset['prompt'] ?? ($preset['generation_prompt'] ?? 'Futuristic cyberpunk portrait of a person bathed in electric cyan and magenta neon lights, wet rainy streets reflecting holographic signage, cinematic lighting, 8k resolution, ultra-detailed, photorealistic.');
$negativePrompt = $preset['negative_prompt'] ?? 'blurry, low resolution, deformed anatomy, extra limbs, watermark, text, grainy, cartoon';
$modelName = $preset['model_name'] ?? 'Midjourney v6.1 / Flux.1 Pro';
$lighting = $preset['lighting'] ?? 'Neon Volumetric Rain & Cyan Rim Light';
$camera = $preset['camera_movement'] ?? '85mm f/1.2 Cine Prime';
$tags = !empty($preset['tags']) ? explode(',', $preset['tags']) : ['Cyberpunk', 'Neon', 'Sci-Fi', 'Night', 'Tokyo'];

$imageUrl = $preset['reference_image_url'] ?? $imgParam;
if (empty($imageUrl)) {
    $imageUrl = '/media/templates/tmpl-golden-hour.jpg';
}
if (!str_starts_with($imageUrl, 'http://') && !str_starts_with($imageUrl, 'https://')) {
    $imageUrl = APP_BASE_URL . '/' . ltrim($imageUrl, '/');
}

$playStoreUrl = 'https://play.google.com/store/apps/details?id=com.procut.app';
$appSchemeUrl = 'procut://prompt?id=' . urlencode($presetId);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title><?= htmlspecialchars($title) ?> - ProCut AI Style & Prompt</title>
    
    <!-- OpenGraph & Social Sharing Meta Tags -->
    <meta property="og:title" content="<?= htmlspecialchars($title) ?> | ProCut AI Prompt">
    <meta property="og:description" content="View prompt details for <?= htmlspecialchars($title) ?>. Download ProCut Video & AI Editor to copy and generate in 8K!">
    <meta property="og:image" content="<?= htmlspecialchars($imageUrl) ?>">
    <meta property="og:type" content="article">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="<?= htmlspecialchars($title) ?> - ProCut AI Studio">
    <meta name="twitter:description" content="Copy this cinematic 8K AI prompt and create stunning videos on ProCut.">
    <meta name="twitter:image" content="<?= htmlspecialchars($imageUrl) ?>">
    <meta name="theme-color" content="#0F172A">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">

    <style>
        :root {
            --primary: #00C2CB;
            --primary-hover: #00A3AB;
            --accent: #8B5CF6;
            --bg: #0B0F19;
            --card-bg: rgba(30, 41, 59, 0.7);
            --card-border: rgba(255, 255, 255, 0.08);
            --text-main: #F8FAFC;
            --text-muted: #94A3B8;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background-color: var(--bg);
            background-image: 
                radial-gradient(at 0% 0%, rgba(0, 194, 203, 0.12) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.12) 0px, transparent 50%);
            color: var(--text-main);
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px 16px 40px;
        }

        .container {
            width: 100%;
            max-width: 480px;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        /* Top Brand Bar */
        .brand-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 4px;
        }
        .brand-logo {
            display: flex;
            align-items: center;
            gap: 10px;
            text-decoration: none;
            color: #fff;
        }
        .brand-badge {
            background: linear-gradient(135deg, #00C2CB, #8B5CF6);
            width: 34px;
            height: 34px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(0, 194, 203, 0.3);
        }
        .brand-title {
            font-weight: 800;
            font-size: 17px;
            letter-spacing: 0.5px;
        }
        .brand-sub {
            font-size: 11px;
            color: var(--primary);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        /* Hero Card */
        .prompt-card {
            background: var(--card-bg);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }

        .hero-media-wrapper {
            position: relative;
            width: 100%;
            height: 320px;
            background: #1e293b;
            overflow: hidden;
        }
        .hero-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.5s ease;
        }
        .hero-gradient-overlay {
            position: absolute;
            inset: 0;
            background: linear-gradient(to top, rgba(15, 23, 42, 0.95) 0%, rgba(15, 23, 42, 0.2) 60%, transparent 100%);
        }
        .hero-badge-floating {
            position: absolute;
            top: 16px;
            left: 16px;
            background: rgba(0, 0, 0, 0.65);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.15);
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            color: var(--primary);
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .card-content {
            padding: 24px;
            display: flex;
            flex-direction: column;
            gap: 18px;
        }

        .title-row h1 {
            font-size: 26px;
            font-weight: 800;
            line-height: 1.25;
            color: #FFFFFF;
            margin-bottom: 6px;
        }
        .title-row .category-label {
            font-size: 13px;
            color: var(--text-muted);
            font-weight: 500;
        }

        .tags-row {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
        }
        .tag-pill {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.08);
            color: #E2E8F0;
            font-size: 11.5px;
            font-weight: 600;
            padding: 4px 12px;
            border-radius: 12px;
        }

        /* Specs Bar */
        .specs-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 14px;
            padding: 12px;
        }
        .spec-item {
            display: flex;
            flex-direction: column;
            gap: 3px;
        }
        .spec-label {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--text-muted);
            font-weight: 600;
        }
        .spec-value {
            font-size: 12px;
            font-weight: 700;
            color: #F1F5F9;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* Prompt Box */
        .prompt-box-container {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .prompt-box-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .prompt-box-title {
            font-size: 13px;
            font-weight: 700;
            color: #F8FAFC;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .prompt-box {
            background: #090D16;
            border: 1px solid rgba(255, 255, 255, 0.09);
            border-radius: 14px;
            padding: 16px;
            font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 13.5px;
            line-height: 1.65;
            color: #CBD5E1;
            user-select: text;
            position: relative;
        }

        /* Action Buttons */
        .action-buttons-group {
            display: flex;
            flex-direction: column;
            gap: 12px;
            margin-top: 6px;
        }
        .btn-copy {
            background: linear-gradient(135deg, #00C2CB 0%, #0284C7 100%);
            color: #000;
            font-weight: 800;
            font-size: 14.5px;
            border: none;
            padding: 14px;
            border-radius: 14px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s ease;
            box-shadow: 0 4px 16px rgba(0, 194, 203, 0.35);
        }
        .btn-copy:active {
            transform: scale(0.98);
        }
        .btn-copy.copied {
            background: #10B981;
            color: #fff;
        }

        .btn-download-app {
            background: #1E293B;
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: #FFFFFF;
            font-weight: 700;
            font-size: 14px;
            padding: 14px;
            border-radius: 14px;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s ease;
        }
        .btn-download-app:hover {
            background: #334155;
            border-color: rgba(255, 255, 255, 0.25);
        }

        /* Toast notification */
        .toast {
            position: fixed;
            bottom: 30px;
            background: #10B981;
            color: #FFFFFF;
            padding: 12px 24px;
            border-radius: 30px;
            font-weight: 700;
            font-size: 13.5px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
            display: none;
            align-items: center;
            gap: 8px;
            z-index: 999;
            animation: fadeIn 0.3s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .footer {
            text-align: center;
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 10px;
        }
        .footer a {
            color: var(--primary);
            text-decoration: none;
        }
    </style>
</head>
<body>

    <div class="container">
        <!-- Brand Header -->
        <header class="brand-header">
            <a href="/" class="brand-logo">
                <div class="brand-badge">P</div>
                <div>
                    <div class="brand-title">PROCUT</div>
                    <div class="brand-sub">AI Video & Photo Editor</div>
                </div>
            </a>
            <a href="<?= htmlspecialchars($playStoreUrl) ?>" class="btn-download-app" style="padding: 6px 14px; font-size: 12px; border-radius: 20px;">
                Get App ⚡
            </a>
        </header>

        <!-- Main Prompt Showcase Card -->
        <div class="prompt-card">
            <!-- Hero Image -->
            <div class="hero-media-wrapper">
                <img src="<?= htmlspecialchars($imageUrl) ?>" alt="<?= htmlspecialchars($title) ?>" class="hero-img" onerror="this.src='/media/templates/tmpl-golden-hour.jpg';">
                <div class="hero-gradient-overlay"></div>
                <div class="hero-badge-floating">
                    <span>✨</span> <?= htmlspecialchars($category) ?>
                </div>
            </div>

            <!-- Card Content -->
            <div class="card-content">
                <div class="title-row">
                    <h1><?= htmlspecialchars($title) ?></h1>
                    <div class="category-label">Category: <?= htmlspecialchars($category) ?></div>
                </div>

                <!-- Tags -->
                <div class="tags-row">
                    <?php foreach ($tags as $tag): ?>
                        <span class="tag-pill">#<?= htmlspecialchars(trim($tag)) ?></span>
                    <?php endforeach; ?>
                </div>

                <!-- Pro Specs -->
                <div class="specs-grid">
                    <div class="spec-item">
                        <span class="spec-label">Recommended AI</span>
                        <span class="spec-value"><?= htmlspecialchars($modelName) ?></span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Lighting Style</span>
                        <span class="spec-value"><?= htmlspecialchars($lighting) ?></span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Camera & Lens</span>
                        <span class="spec-value"><?= htmlspecialchars($camera) ?></span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Aspect Ratio</span>
                        <span class="spec-value">3:4 Portrait / 9:16</span>
                    </div>
                </div>

                <!-- Generation Prompt Box -->
                <div class="prompt-box-container">
                    <div class="prompt-box-header">
                        <div class="prompt-box-title">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#00C2CB" stroke-width="2"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                            Masterpiece Generation Prompt
                        </div>
                    </div>
                    <div class="prompt-box" id="promptText"><?= htmlspecialchars($prompt) ?></div>
                </div>

                <!-- Actions -->
                <div class="action-buttons-group">
                    <button class="btn-copy" id="btnCopyPrompt" onclick="copyFullPrompt()">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                        <span>Copy Full 8K Prompt</span>
                    </button>

                    <a href="<?= htmlspecialchars($playStoreUrl) ?>" class="btn-download-app">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#00C2CB" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        Download ProCut App for Free
                    </a>
                </div>
            </div>
        </div>

        <div class="footer">
            Powered by <a href="/">ProCut Video & AI Studio</a> • Pro Multi-Track Mobile Editing
        </div>
    </div>

    <div class="toast" id="toastMessage">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"></polyline></svg>
        Prompt Copied to Clipboard!
    </div>

    <script>
        function copyFullPrompt() {
            const text = document.getElementById('promptText').innerText.trim();
            navigator.clipboard.writeText(text).then(() => {
                const btn = document.getElementById('btnCopyPrompt');
                btn.classList.add('copied');
                btn.querySelector('span').innerText = 'Copied to Clipboard! ✨';
                
                const toast = document.getElementById('toastMessage');
                toast.style.display = 'flex';

                setTimeout(() => {
                    btn.classList.remove('copied');
                    btn.querySelector('span').innerText = 'Copy Full 8K Prompt';
                    toast.style.display = 'none';
                }, 3000);
            }).catch(err => {
                alert('Could not copy automatically. Please select text manually.');
            });
        }
    </script>
</body>
</html>
