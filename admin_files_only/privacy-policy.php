<?php
$pageTitle = 'Privacy Policy & Terms Manager';
require_once __DIR__ . '/includes/auth_check.php';

$error   = '';
$success = '';

$defaultPrivacyPolicy = "Privacy Policy\nLast updated 28 September 2026\n\nThis policy explains what personal data PusherHub collects, why, and what you can do about it. It covers the hosted PusherHub service at this website — the website, the dashboard, the REST API and the SDKs. It doesn't cover copies of PusherHub that other people host on their own servers.\n\nPusherHub is operated by Harsha (\"we\", \"us\"), who is responsible for your personal data under India's Digital Personal Data Protection Act, 2023.\n\nThe app does use third-party services that may collect information used to identify you.\nLink to the privacy policy of third-party service providers used by the app:\n• Google Play Services\n• AdMob\n• Google Analytics for Firebase\n• Firebase Crashlytics\n• Facebook\n• PusherHub\n\nTwo kinds of data\nYour account data is about you, as a PusherHub customer. We decide how it's used, and this policy explains how.\nYour app users' data is about the people who use the apps you connect to PusherHub. You decide what's collected and why; we store and process it only to deliver your notifications and messages, on your instructions. If you're one of those app users, the app's own privacy policy applies, and the app's developer is the right person to contact first.\n\nWhat we collect about you\nAccount details — your name, email address and password. Passwords are stored only as a secure hash; we can't see them.\nGoogle sign-in — if you sign in with Google, we receive your name, email address, Google account ID and profile picture. We don't get your Google password or access to anything else in your Google account.\nSign-in records — when you last signed in, and the IP address used to ask for a sign-in or password-reset code. The codes themselves are stored only as a hash and deleted once they expire.\nPayments — the plan you bought, the amount, the date and status, and the Razorpay order and payment IDs. Your card, UPI or bank details go straight to Razorpay; we never receive or store them.\nWhat you set up in PusherHub — your apps, the Firebase service account you connect, API keys, notifications, templates, segments, topics, in-app messages and webhook addresses. Firebase service accounts and API secret keys are stored encrypted.\nServer logs — like most websites, our servers record requests (IP address, time, page and browser) for security and troubleshooting.\n\nWhat PusherHub stores about your app users\nWhen your app registers a device with PusherHub, through our SDK or API, we store:\nthe device's Firebase messaging token, platform, brand and model, app version, language and timezone;\nwhether the user has allowed notifications, and when the device was last active;\na user ID, only if your app sends one;\nan approximate location — country, state and city — worked out from the device's IP address. The IP address itself isn't stored with the device;\nwhat happened to each notification and in-app message: delivered, opened, clicked, shown or dismissed.\n\nHow we use data\nTo run the Service: sign you in, send your notifications and messages, and show your analytics.\nTo apply your plan's limits and features, and to process your payments.\nTo email you sign-in codes, password-reset codes, and important messages about your account or the Service.\nTo keep PusherHub secure: block abuse, limit repeated sign-in attempts and investigate problems.\nTo meet our legal, tax and accounting obligations.\nWe don't sell personal data, we don't show ads, and we don't use your app users' data for any purpose of our own.\n\nCookies\nWe only use the cookies the site needs to work:\na session cookie that keeps you signed in;\na security token (XSRF-TOKEN) that protects forms against cross-site request forgery;\na \"remember me\" cookie, only if you tick that box when you sign in.\nWe don't use analytics or advertising cookies. Some pages load services from other companies, which may set their own cookies or see your IP address: fonts from Google Fonts on our public pages, Google Sign-In on the sign-in page, and Razorpay Checkout when you pay.\n\nWho we share data with\nWe share personal data only with the service providers that help us run PusherHub, and only what they need:\nGoogle (Firebase Cloud Messaging) — to deliver push notifications, through the Firebase project you connect;\nGoogle (Sign-In) — if you choose to sign in with Google;\nRazorpay — to process payments;\nour hosting provider, which runs the servers PusherHub is on, and our email provider, which delivers sign-in and reset codes.\nWe may also disclose data where the law requires it — for example, a valid order from a court or government authority — or where it's needed to protect the rights, property or safety of our users or the public. Some providers, such as Google, may process data outside India under their own privacy and security commitments.\n\nHow long we keep data\nAccount data — for as long as you have an account. When you ask us to delete your account, we delete your account data together with the apps, devices and messages in it.\nPayment records — for as long as Indian tax and accounting law requires, even after your account is deleted.\nSign-in and reset codes — deleted once they expire.\nApp users' devices — removed after they've been inactive for the period set for each app, or when you delete the app.\nDelivery and engagement records — kept while your account exists, so your analytics keep working.\nServer logs — kept only as long as they're needed for security and troubleshooting.\n\nHow we protect data\nPasswords and sign-in codes are hashed. Firebase service accounts and API secret keys are encrypted. Each customer can see only their own apps and data, and sign-in attempts are rate-limited. No system is perfectly secure, but if a breach affects your personal data, we'll tell you and the authorities as the law requires.\n\nYour rights\nUnder India's Digital Personal Data Protection Act, 2023, you can:\nask for a summary of the personal data we hold about you and how we use it;\nask us to correct, complete or update it;\nask us to delete it, unless the law requires us to keep it;\nwithdraw your consent — which may mean closing your account;\nnominate someone to exercise these rights for you if you die or can't act yourself;\nraise a grievance with us and, if you're not satisfied with our answer, complain to the Data Protection Board of India.\nYou can change your password at any time with Forgot password? on the sign-in page. For anything else, contact our Grievance Officer below.\n\nChildren\nPusherHub is a service for businesses and developers, and isn't meant for anyone under 18. If you believe a child has created an account, contact us and we'll delete it.\n\nChanges to this policy\nWhen we change this policy, we update the date at the top. If a change is significant, we'll tell you by email or in the dashboard before it takes effect.\n\nContact and Grievance Officer\nFor questions, requests or complaints about your personal data:\nGrievance Officer: Harsha\nEmail: harsha.malnadtech@gmail.com\nWe'll acknowledge your request and respond within the time limits set by Indian law.";

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
                                <i class="bi bi-magic me-1"></i>Insert Default Policy
                            </button>
                            <span class="badge bg-success-subtle text-success border border-success-subtle">
                                <i class="bi bi-phone me-1"></i>Live in App
                            </span>
                        </div>
                    </div>

                    <textarea
                        name="privacy_policy_content"
                        id="privacyTextarea"
                        class="form-control font-monospace"
                        rows="22"
                        placeholder="Enter Privacy Policy text..."
                        oninput="legalCounter('privacyTextarea','privacyCount','privacyPreview')"
                    ><?= htmlspecialchars($s['privacy_policy_content'] ?? '') ?></textarea>

                    <div class="d-flex justify-content-between align-items-center mt-2">
                        <small class="text-muted">Plain text</small>
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

                    <textarea
                        name="terms_conditions_content"
                        id="termsTextarea"
                        class="form-control font-monospace"
                        rows="22"
                        placeholder="Enter Terms & Conditions text..."
                        oninput="legalCounter('termsTextarea','termsCount','termsPreview')"
                    ><?= htmlspecialchars($s['terms_conditions_content'] ?? '') ?></textarea>

                    <div class="d-flex justify-content-between align-items-center mt-2">
                        <small class="text-muted">Plain text</small>
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
    counter.className   = 'font-monospace small ' + (len > 12000 ? 'char-danger' : 'text-muted');

    if (!ta.value.trim()) {
        preview.innerHTML = '<span style="color:#9ca3af;font-style:italic;">Start typing on the left to see how it looks in the app…</span>';
        return;
    }

    let lines = ta.value.split('\n');
    let html = '';
    const sectionHeaders = [
        'two kinds of data', 'what we collect about you', 'what pusherhub stores about your app users',
        'how we use data', 'cookies', 'who we share data with', 'how long we keep data',
        'how we protect data', 'your rights', 'children', 'changes to this policy', 'contact and grievance officer'
    ];

    for (let l of lines) {
        let trimmed = l.trim();
        if (!trimmed) {
            html += '<div style="height:8px;"></div>';
            continue;
        }
        let lower = trimmed.toLowerCase();
        if (lower.startsWith('privacy policy')) {
            html += `<h6 class="fw-bold text-primary mb-1 mt-2">${escapeHtml(trimmed)}</h6>`;
        } else if (lower.startsWith('last updated')) {
            html += `<span class="badge bg-primary-subtle text-primary mb-2">${escapeHtml(trimmed)}</span>`;
        } else if (sectionHeaders.includes(lower) || /^\d+\.\s/.test(trimmed)) {
            html += `<div class="fw-bold text-dark border-bottom pb-1 mt-3 mb-2" style="font-size:13.5px;"><i class="bi bi-shield-check text-primary me-1"></i>${escapeHtml(trimmed)}</div>`;
        } else if (lower.startsWith('link to the privacy policy of third-party') || lower.startsWith('the app does use third-party')) {
            html += `<div class="fw-bold text-dark mt-2 mb-1" style="font-size:12.8px;"><i class="bi bi-link-45deg text-primary me-1"></i>${escapeHtml(trimmed)}</div>`;
        } else if (lower.startsWith('• google play')) {
            html += `<div class="ms-3 mb-1"><a href="https://policies.google.com/privacy" target="_blank" rel="noopener" class="text-primary text-decoration-none fw-semibold small"><i class="bi bi-box-arrow-up-right me-1"></i>Google Play Services</a></div>`;
        } else if (lower.startsWith('• admob')) {
            html += `<div class="ms-3 mb-1"><a href="https://support.google.com/admob/answer/6128543?hl=en" target="_blank" rel="noopener" class="text-primary text-decoration-none fw-semibold small"><i class="bi bi-box-arrow-up-right me-1"></i>AdMob</a></div>`;
        } else if (lower.startsWith('• google analytics')) {
            html += `<div class="ms-3 mb-1"><a href="https://firebase.google.com/policies/analytics" target="_blank" rel="noopener" class="text-primary text-decoration-none fw-semibold small"><i class="bi bi-box-arrow-up-right me-1"></i>Google Analytics for Firebase</a></div>`;
        } else if (lower.startsWith('• firebase crashlytics')) {
            html += `<div class="ms-3 mb-1"><a href="https://firebase.google.com/support/privacy" target="_blank" rel="noopener" class="text-primary text-decoration-none fw-semibold small"><i class="bi bi-box-arrow-up-right me-1"></i>Firebase Crashlytics</a></div>`;
        } else if (lower.startsWith('• facebook')) {
            html += `<div class="ms-3 mb-1"><a href="https://www.facebook.com/about/privacy/update/printable" target="_blank" rel="noopener" class="text-primary text-decoration-none fw-semibold small"><i class="bi bi-box-arrow-up-right me-1"></i>Facebook</a></div>`;
        } else if (lower.startsWith('• pusherhub')) {
            html += `<div class="ms-3 mb-1"><span class="badge bg-primary text-white"><i class="bi bi-shield-check me-1"></i>PusherHub Privacy Policy</span></div>`;
        } else if (trimmed.includes(' — ')) {
            let [pref, ...rest] = trimmed.split(' — ');
            html += `<div class="d-flex align-items-start gap-2 mb-1.5 ms-2"><span class="badge bg-primary rounded-circle p-1 mt-1.5" style="width:6px;height:6px;"></span><div><strong class="text-dark">${escapeHtml(pref)}</strong> — <span class="text-secondary">${escapeHtml(rest.join(' — '))}</span></div></div>`;
        } else if (lower.startsWith('grievance officer:') || lower.startsWith('email:')) {
            html += `<div class="p-2 my-1 rounded bg-light border border-primary-subtle small"><strong>${escapeHtml(trimmed)}</strong></div>`;
        } else {
            html += `<p class="mb-1.5 text-secondary" style="font-size:12.5px; line-height:1.55;">${escapeHtml(trimmed)}</p>`;
        }
    }
    preview.innerHTML = html;
}

function escapeHtml(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Init on load
document.addEventListener('DOMContentLoaded', () => {
    legalCounter('privacyTextarea', 'privacyCount', 'privacyPreview');
    legalCounter('termsTextarea',   'termsCount',   'termsPreview');
});
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
