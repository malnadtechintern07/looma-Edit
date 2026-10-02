<?php
$pageTitle = 'Privacy Policy & Terms Manager';
require_once __DIR__ . '/includes/auth_check.php';

$error   = '';
$success = '';

$defaultPrivacyPolicy = "PROCut PRIVACY COMMITMENT\n\nYour media belongs to you. ProCut is engineered with a strict offline-first architecture: your source videos, voiceovers, photos, and project timelines are processed directly on your device and never uploaded to public clouds without your explicit direction.\n\n1. OFFLINE-FIRST PROCESSING & MEDIA STORAGE\nAll video trimming, timeline slicing, multi-track layering, filter rendering, and audio ducking take place strictly within your mobile device's native hardware. ProCut does not transmit your source video clips, photos, or voiceover recordings to our servers for processing.\n\n2. DEVICE PERMISSIONS & PURPOSE\n• Photos, Media & Storage: Required solely to import video clips into your editing timeline and export rendered MP4 videos into your camera roll (DCIM/Movies).\n• Microphone: Requested only when you intentionally record a custom voiceover track in the audio timeline.\n• Camera: Used only if you choose to record new footage directly inside the media picker.\n• Notifications: Used to notify you when background video rendering or cloud backup is completed.\nWe never access, index, or scan any files, photos, or audio recordings outside of what you explicitly select for your project.\n\n3. OPTIONAL CLOUD SYNC & ACCOUNT DATA\nIf you register for a ProCut Cloud account, we store your account email, securely hashed password, and project metadata. When you choose to back up a project, your project JSON draft is transmitted over TLS 1.3 encryption and stored in a private storage vault accessible only by your authenticated session.\n\n4. CACHE & TEMPORARY VIDEO FRAGMENTS\nDuring video playback, preview thumbnails and audio waveform caches are saved in your app temporary sandbox for stutter-free performance. You can purge this cache anytime in the app settings under \"Clear Temporary Cache\" without losing any saved project drafts.\n\n5. ZERO ADVERTISING & NO THIRD-PARTY DATA SELLING\nProCut contains no advertising tracking SDKs, no behavioral trackers, and no third-party data brokers. We never sell, rent, or monetize your creative media, exported clips, email addresses, or personal information under any circumstance.\n\n6. USER RIGHTS & COMPLETE DATA DELETION\nYou retain full ownership of your content. You have the right to export your data, clear all cloud backups, or delete your ProCut account and associated data entirely at any time. Deleting a cloud project immediately purges its files from our cloud storage servers.\n\n7. POLICY UPDATES & CONTACT\nWe may occasionally update this Privacy Policy to reflect app enhancements or legal requirements. Any modifications will be updated directly in this app.\nFor questions, data requests, or privacy inquiries, please contact our support team at support@procut.app.";

$defaultTermsConditions = "TERMS & CONDITIONS\n\n1. ACCEPTANCE OF TERMS\nBy downloading, installing, or using ProCut (\"the App\"), you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the App.\n\n2. LICENSE & USAGE RIGHTS\nProCut grants you a personal, non-exclusive, non-transferable, revocable license to use the App for personal or commercial video editing and creation in accordance with these Terms.\n\n3. USER CONTENT & OWNERSHIP\nYou retain 100% intellectual property ownership of all videos, audio files, images, and projects created or edited within ProCut. You are solely responsible for ensuring you have the legal right to use any third-party copyrighted music, audio, or footage in your projects.\n\n4. SUBSCRIPTIONS & IN-APP PURCHASES\nProCut offers optional Pro features, including watermark removal, 4K 60FPS export, and premium AI tools. Subscriptions and one-time purchases are processed securely through Google Play Billing and are subject to Google Play store refund policies.\n\n5. PROHIBITED USES\nYou agree not to reverse engineer, decompile, or tamper with the App's binary code, circumvent DRM or licensing protections, or use the App to produce or distribute unlawful, harmful, or infringing content.\n\n6. DISCLAIMER OF WARRANTIES & LIMITATION OF LIABILITY\nProCut is provided on an \"as-is\" and \"as-available\" basis. While we strive for seamless multi-track performance, we are not liable for any lost data, corrupt project files, or hardware rendering failures. Always maintain backups of your vital media.\n\n7. TERMINATION & MODIFICATIONS\nWe reserve the right to modify these Terms at any time. Continued use of the App following updates constitutes your acceptance of the updated Terms.\n\n8. CONTACT US\nFor questions or support regarding these Terms, contact us at support@procut.app.";

// POST: save
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $csrf = $_POST['csrf_token'] ?? '';
    if (!Auth::validateCsrfToken($csrf)) {
        $error = 'Invalid security token. Please refresh and try again.';
    } else {
        $privacyContent = $_POST['privacy_policy_content'] ?? '';
        $termsContent   = $_POST['terms_conditions_content'] ?? '';

        // Upsert privacy_policy_content
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('privacy_policy_content', ?, 'legal', 'Official App Privacy Policy plain text') 
             ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
            [$privacyContent]
        );

        // Upsert terms_conditions_content
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('terms_conditions_content', ?, 'legal', 'Official App Terms & Conditions plain text') 
             ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
            [$termsContent]
        );

        Auth::logActivity('admin', (string)$currentAdmin['id'], $currentAdmin['name'],
            'legal_content_updated', 'Updated Privacy Policy and Terms & Conditions');

        $success = 'Privacy Policy and Terms & Conditions saved and are now live in the app!';
    }
}

// Fetch current values
$settingsRows = Database::fetchAll(
    "SELECT setting_key, setting_value FROM app_settings WHERE setting_key IN ('privacy_policy_content','terms_conditions_content','about_company_name','support_email','about_copyright_text')"
);
$s = [];
foreach ($settingsRows as $row) {
    $s[$row['setting_key']] = $row['setting_value'];
}

$companyName   = $s['about_company_name']  ?? 'ProCut Studio';
$supportEmail  = $s['support_email']       ?? 'support@procut.app';
$copyrightText = $s['about_copyright_text'] ?? '© ' . date('Y') . ' ' . $companyName;

// Auto-seed legal settings if empty in DB (fail-safe)
try {
    if (empty($s['privacy_policy_content'])) {
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('privacy_policy_content', ?, 'legal', 'Official App Privacy Policy plain text') 
             ON DUPLICATE KEY UPDATE setting_value = IF(setting_value = '' OR setting_value IS NULL, VALUES(setting_value), setting_value)",
            [$defaultPrivacyPolicy]
        );
        $s['privacy_policy_content'] = $defaultPrivacyPolicy;
    }
    if (empty($s['terms_conditions_content'])) {
        Database::query(
            "INSERT INTO app_settings (setting_key, setting_value, setting_group, description) 
             VALUES ('terms_conditions_content', ?, 'legal', 'Official App Terms & Conditions plain text') 
             ON DUPLICATE KEY UPDATE setting_value = IF(setting_value = '' OR setting_value IS NULL, VALUES(setting_value), setting_value)",
            [$defaultTermsConditions]
        );
        $s['terms_conditions_content'] = $defaultTermsConditions;
    }
} catch (\Throwable $e) {
    if (empty($s['privacy_policy_content'])) $s['privacy_policy_content'] = $defaultPrivacyPolicy;
    if (empty($s['terms_conditions_content'])) $s['terms_conditions_content'] = $defaultTermsConditions;
}

$privacyLen    = strlen($s['privacy_policy_content'] ?? '');
$termsLen      = strlen($s['terms_conditions_content'] ?? '');

require_once __DIR__ . '/includes/header.php';
require_once __DIR__ . '/includes/sidebar.php';
require_once __DIR__ . '/includes/navbar.php';
?>

<style>
.legal-status-pill {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 700;
}
.legal-status-pill.filled   { background: #d1fae5; color: #065f46; border: 1px solid #6ee7b7; }
.legal-status-pill.empty    { background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }
.legal-preview-box {
    background: #f8f9fe;
    border: 1.5px solid #e5e7eb;
    border-radius: 14px;
    padding: 18px;
    min-height: 120px;
    max-height: 320px;
    overflow-y: auto;
    font-size: 13px;
    line-height: 1.75;
    white-space: pre-wrap;
    word-break: break-word;
    color: #374151;
    font-family: inherit;
}
.tab-pill { cursor: pointer; border: 2px solid transparent; border-radius: 10px; padding: 8px 20px; background: #fff; transition: all .2s; font-weight: 600; font-size: 13px; }
.tab-pill:hover  { border-color: #0D6EFD22; background: #f0f5ff; }
.tab-pill.active { border-color: #0D6EFD; background: linear-gradient(135deg,#0D6EFD11,#00C2CB11); color: #0D6EFD; }
.char-danger { color: #ef4444 !important; font-weight: 700; }
</style>

<!-- Page header -->
<div class="d-flex flex-wrap justify-content-between align-items-center mb-4 gap-3">
    <div>
        <h3 class="fw-bold mb-1 brand-font">
            <i class="bi bi-shield-lock-fill me-2 text-primary"></i>Privacy Policy &amp; Terms Manager
        </h3>
        <p class="text-muted small mb-0">
            Write your Privacy Policy and Terms &amp; Conditions here.
            They are delivered <strong>live to the app</strong> — no APK rebuild needed.
        </p>
    </div>
    <div class="d-flex align-items-center gap-2">
        <span class="legal-status-pill <?= $privacyLen > 0 ? 'filled' : 'empty' ?>">
            <i class="bi bi-shield-<?= $privacyLen > 0 ? 'check' : 'exclamation' ?>"></i>
            Privacy <?= $privacyLen > 0 ? 'Set (' . number_format($privacyLen) . ' chars)' : 'Empty' ?>
        </span>
        <span class="legal-status-pill <?= $termsLen > 0 ? 'filled' : 'empty' ?>">
            <i class="bi bi-file-<?= $termsLen > 0 ? 'check' : 'earmark-x' ?>"></i>
            T&amp;C <?= $termsLen > 0 ? 'Set (' . number_format($termsLen) . ' chars)' : 'Empty' ?>
        </span>
    </div>
</div>

<?php if ($error): ?>
    <div class="alert alert-danger py-2 px-3 small mb-3"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
    <div class="alert alert-success py-2 px-3 small mb-3">
        <i class="bi bi-check-circle-fill me-2"></i><?= htmlspecialchars($success) ?>
    </div>
<?php endif; ?>

<!-- How it works info banner -->
<div class="alert alert-primary d-flex gap-3 align-items-start mb-4 py-3 px-4" style="border-radius:14px; border:1.5px solid #bfdbfe;">
    <i class="bi bi-info-circle-fill fs-5 mt-1 text-primary flex-shrink-0"></i>
    <div class="small">
        <strong>How it works:</strong> Content saved here flows through
        <code>/api/app/config → legal.privacyPolicyContent</code> directly into the app.
        Users see your latest text instantly every time they open Privacy Policy or Terms &amp; Conditions
        — <strong>no app update required</strong>.
        Use a <strong>blank line</strong> between sections — it becomes a paragraph break in the app.
    </div>
</div>

<!-- Tabs -->
<div class="d-flex gap-2 mb-4" id="legalTabs">
    <button class="tab-pill active" onclick="switchLegalTab('privacy')">
        <i class="bi bi-shield-lock me-1"></i> Privacy Policy
    </button>
    <button class="tab-pill" onclick="switchLegalTab('terms')">
        <i class="bi bi-file-text me-1"></i> Terms &amp; Conditions
    </button>
</div>

<form method="POST">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($csrfToken) ?>">

    <!-- ══════════════ PRIVACY POLICY PANEL ══════════════ -->
    <div id="panel-privacy">
        <div class="row g-4">
            <!-- Editor -->
            <div class="col-lg-7">
                <div class="pro-card p-4">
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <h5 class="fw-bold mb-0">
                            <i class="bi bi-shield-lock me-2 text-primary"></i>Privacy Policy Content
                        </h5>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-sm btn-outline-primary" onclick="loadDefaultPrivacyPolicy()" style="font-size:12px; padding:3px 10px;">
                                <i class="bi bi-magic me-1"></i>Insert Standard ProCut Policy
                            </button>
                            <span class="badge bg-success-subtle text-success border border-success-subtle">
                                <i class="bi bi-phone me-1"></i>Live in App
                            </span>
                        </div>
                    </div>

                    <div class="alert alert-light border py-2 px-3 small mb-3" style="border-radius:10px;">
                        <i class="bi bi-lightbulb-fill text-warning me-1"></i>
                        <strong>Formatting tips:</strong> Leave a <strong>blank line</strong> between sections — it becomes a paragraph break in the app.
                        Use numbered headings like <code>1. Data We Collect</code> or ALL CAPS for section titles.
                    </div>

                    <textarea
                        name="privacy_policy_content"
                        id="privacyTextarea"
                        class="form-control font-monospace"
                        rows="22"
                        placeholder="PRIVACY POLICY

1. Information We Collect
We collect only the information necessary to provide our services...

2. How We Use Your Information
Your information is used solely to improve your experience...

3. Data Security
All data is stored securely and never shared with third parties..."
                        oninput="legalCounter('privacyTextarea','privacyCount','privacyPreview')"
                    ><?= htmlspecialchars($s['privacy_policy_content'] ?? '') ?></textarea>

                    <div class="d-flex justify-content-between align-items-center mt-2">
                        <small class="text-muted">Plain text · blank line = new paragraph in app</small>
                        <small id="privacyCount" class="text-muted font-monospace"><?= number_format($privacyLen) ?> chars</small>
                    </div>
                </div>
            </div>

            <!-- Live Preview -->
            <div class="col-lg-5">
                <div class="pro-card p-4 h-100">
                    <h5 class="fw-bold mb-3">
                        <i class="bi bi-phone me-2 text-success"></i>App Preview
                    </h5>

                    <!-- App-like header mockup -->
                    <div class="rounded-3 mb-3 p-3 text-white d-flex align-items-center gap-3"
                         style="background:linear-gradient(135deg,#084298,#0D6EFD);">
                        <div class="rounded-circle d-flex align-items-center justify-content-center"
                             style="width:40px;height:40px;background:rgba(255,255,255,0.18);flex-shrink:0;">
                            <i class="bi bi-verified"></i>
                        </div>
                        <div>
                            <div class="fw-bold" style="font-size:13px;"><?= htmlspecialchars($companyName) ?> Privacy Policy</div>
                            <div style="font-size:11px;opacity:.7;">Managed live from Admin Panel</div>
                        </div>
                    </div>

                    <div class="legal-preview-box" id="privacyPreview"><?php
                        $ppContent = $s['privacy_policy_content'] ?? '';
                        echo $ppContent
                            ? htmlspecialchars($ppContent)
                            : '<span style="color:#9ca3af;font-style:italic;">Start typing on the left to see how it looks in the app…</span>';
                    ?></div>

                    <?php if ($supportEmail): ?>
                    <div class="mt-3 p-3 rounded-3 d-flex align-items-center gap-3"
                         style="background:#f0f5ff;border:1px solid #bfdbfe;">
                        <i class="bi bi-mail-lock text-primary fs-5"></i>
                        <div>
                            <div class="small fw-semibold text-muted">Privacy Inquiries</div>
                            <div class="fw-bold text-primary small"><?= htmlspecialchars($supportEmail) ?></div>
                        </div>
                    </div>
                    <?php endif; ?>

                    <div class="text-center text-muted mt-3" style="font-size:11px;">
                        <?= htmlspecialchars($copyrightText) ?>
                    </div>
                </div>
            </div>
        </div>
        <div class="d-flex justify-content-end mt-4">
            <button type="submit" class="btn btn-primary px-5 py-2 fw-semibold">
                <i class="bi bi-cloud-check me-2"></i>Save Privacy Policy to App
            </button>
        </div>
    </div>

    <!-- ══════════════ TERMS & CONDITIONS PANEL ══════════════ -->
    <div id="panel-terms" style="display:none;">
        <div class="row g-4">
            <div class="col-lg-7">
                <div class="pro-card p-4">
                    <div class="d-flex align-items-center justify-content-between mb-3">
                        <h5 class="fw-bold mb-0">
                            <i class="bi bi-file-text me-2 text-primary"></i>Terms &amp; Conditions Content
                        </h5>
                        <div class="d-flex align-items-center gap-2">
                            <button type="button" class="btn btn-sm btn-outline-primary" onclick="loadDefaultTermsConditions()" style="font-size:12px; padding:3px 10px;">
                                <i class="bi bi-magic me-1"></i>Insert Standard Terms
                            </button>
                            <span class="badge bg-success-subtle text-success border border-success-subtle">
                                <i class="bi bi-phone me-1"></i>Live in App
                            </span>
                        </div>
                    </div>

                    <div class="alert alert-light border py-2 px-3 small mb-3" style="border-radius:10px;">
                        <i class="bi bi-lightbulb-fill text-warning me-1"></i>
                        Same formatting rules as Privacy Policy — blank line between sections = paragraph break in app.
                    </div>

                    <textarea
                        name="terms_conditions_content"
                        id="termsTextarea"
                        class="form-control font-monospace"
                        rows="22"
                        placeholder="TERMS & CONDITIONS

1. Acceptance of Terms
By downloading or using ProCut, you agree to these terms...

2. License
We grant you a limited, non-exclusive license to use the app...

3. User Content
You retain ownership of all content you create with ProCut..."
                        oninput="legalCounter('termsTextarea','termsCount','termsPreview')"
                    ><?= htmlspecialchars($s['terms_conditions_content'] ?? '') ?></textarea>

                    <div class="d-flex justify-content-between align-items-center mt-2">
                        <small class="text-muted">Plain text · blank line = new paragraph in app</small>
                        <small id="termsCount" class="text-muted font-monospace"><?= number_format($termsLen) ?> chars</small>
                    </div>
                </div>
            </div>

            <div class="col-lg-5">
                <div class="pro-card p-4 h-100">
                    <h5 class="fw-bold mb-3">
                        <i class="bi bi-phone me-2 text-success"></i>App Preview
                    </h5>
                    <div class="rounded-3 mb-3 p-3 text-white d-flex align-items-center gap-3"
                         style="background:linear-gradient(135deg,#065f46,#059669);">
                        <div class="rounded-circle d-flex align-items-center justify-content-center"
                             style="width:40px;height:40px;background:rgba(255,255,255,0.18);flex-shrink:0;">
                            <i class="bi bi-file-earmark-check-fill"></i>
                        </div>
                        <div>
                            <div class="fw-bold" style="font-size:13px;">Terms &amp; Conditions</div>
                            <div style="font-size:11px;opacity:.7;"><?= htmlspecialchars($companyName) ?></div>
                        </div>
                    </div>

                    <div class="legal-preview-box" id="termsPreview"><?php
                        $tcContent = $s['terms_conditions_content'] ?? '';
                        echo $tcContent
                            ? htmlspecialchars($tcContent)
                            : '<span style="color:#9ca3af;font-style:italic;">Start typing on the left to see how it looks in the app…</span>';
                    ?></div>

                    <div class="text-center text-muted mt-3" style="font-size:11px;">
                        <?= htmlspecialchars($copyrightText) ?>
                    </div>
                </div>
            </div>
        </div>
        <div class="d-flex justify-content-end mt-4">
            <button type="submit" class="btn btn-success px-5 py-2 fw-semibold">
                <i class="bi bi-cloud-check me-2"></i>Save Terms &amp; Conditions to App
            </button>
        </div>
    </div>

</form>

<script>
const defaultPrivacyPolicyText = <?= json_encode($defaultPrivacyPolicy) ?>;
const defaultTermsConditionsText = <?= json_encode($defaultTermsConditions) ?>;

function loadDefaultPrivacyPolicy() {
    const ta = document.getElementById('privacyTextarea');
    if (!ta) return;
    ta.value = defaultPrivacyPolicyText;
    legalCounter('privacyTextarea', 'privacyCount', 'privacyPreview');
}

function loadDefaultTermsConditions() {
    const ta = document.getElementById('termsTextarea');
    if (!ta) return;
    ta.value = defaultTermsConditionsText;
    legalCounter('termsTextarea', 'termsCount', 'termsPreview');
}

function switchLegalTab(tab) {
    document.getElementById('panel-privacy').style.display = tab === 'privacy' ? '' : 'none';
    document.getElementById('panel-terms').style.display   = tab === 'terms'   ? '' : 'none';
    document.querySelectorAll('.tab-pill').forEach((b, i) => {
        b.classList.toggle('active', (tab === 'privacy' && i === 0) || (tab === 'terms' && i === 1));
    });
}

function legalCounter(textareaId, countId, previewId) {
    const ta      = document.getElementById(textareaId);
    const counter = document.getElementById(countId);
    const preview = document.getElementById(previewId);
    if (!ta || !counter || !preview) return;
    const len     = ta.value.length;

    counter.textContent = len.toLocaleString() + ' chars';
    counter.className   = 'font-monospace small ' + (len > 4000 ? 'char-danger' : 'text-muted');

    preview.innerHTML = ta.value.trim()
        ? ta.value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        : '<span style="color:#9ca3af;font-style:italic;">Start typing on the left to see how it looks in the app…</span>';
}

// Init on load
document.addEventListener('DOMContentLoaded', () => {
    legalCounter('privacyTextarea', 'privacyCount', 'privacyPreview');
    legalCounter('termsTextarea',   'termsCount',   'termsPreview');
});
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
