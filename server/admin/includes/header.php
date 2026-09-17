<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($pageTitle ?? 'Admin Console') ?> — ProCut Studio</title>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5.3 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --procut-primary: #0D6EFD;
            --procut-primary-dark: #084298;
            --procut-accent: #0284C7;
            --procut-gold: #FFB800;
            --procut-sidebar-bg: #0F172A;
            --procut-sidebar-hover: #1E293B;
            --procut-card-bg: #FFFFFF;
            --procut-body-bg: #F8FAFC;
        }

        html, body {
            width: 100%;
            max-width: 100vw;
            overflow-x: hidden;
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        *, *::before, *::after {
            box-sizing: border-box;
        }

        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--procut-body-bg);
            color: #1E293B;
            min-height: 100vh;
        }

        h1, h2, h3, h4, h5, h6, .brand-font {
            font-family: 'Space Grotesk', sans-serif;
        }

        .admin-layout-root {
            display: flex;
            width: 100%;
            max-width: 100vw;
            min-height: 100vh;
            overflow-x: hidden;
            position: relative;
        }

        /* Sidebar Styling */
        .sidebar {
            width: 260px;
            background: var(--procut-sidebar-bg);
            color: #94A3B8;
            height: 100vh;
            position: fixed;
            top: 0;
            left: 0;
            bottom: 0;
            z-index: 1040;
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 4px 0 24px rgba(0, 0, 0, 0.12);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .sidebar-brand {
            padding: 20px 22px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            align-items: center;
            gap: 12px;
            flex-shrink: 0;
        }

        .sidebar-brand-badge {
            background: linear-gradient(135deg, #FFB800, #FF8A00);
            color: #000;
            font-size: 10px;
            font-weight: 800;
            padding: 2px 7px;
            border-radius: 6px;
            letter-spacing: 0.5px;
        }

        .sidebar-menu {
            padding: 16px 12px;
            flex-grow: 1;
            overflow-y: auto;
        }

        .sidebar-section-title {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #64748B;
            padding: 12px 14px 6px 14px;
        }

        .sidebar-nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            color: #94A3B8;
            text-decoration: none;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 500;
            transition: all 0.2s ease;
            margin-bottom: 2px;
        }

        .sidebar-nav-link i {
            font-size: 18px;
            width: 22px;
            text-align: center;
        }

        .sidebar-nav-link:hover {
            color: #FFFFFF;
            background: var(--procut-sidebar-hover);
        }

        .sidebar-nav-link.active {
            color: #FFFFFF;
            background: linear-gradient(135deg, var(--procut-primary-dark), var(--procut-primary));
            box-shadow: 0 4px 12px rgba(13, 110, 253, 0.35);
            font-weight: 600;
        }

        /* Main Content Layout - Strictly Fitted to Screen */
        .main-wrapper {
            margin-left: 260px;
            width: calc(100% - 260px);
            max-width: calc(100% - 260px);
            min-width: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            box-sizing: border-box;
            flex-grow: 1;
            overflow-x: hidden;
            transition: margin-left 0.3s ease, width 0.3s ease;
        }

        .top-navbar {
            background: #FFFFFF;
            border-bottom: 1px solid #E2E8F0;
            padding: 14px 28px;
            position: sticky;
            top: 0;
            z-index: 1030;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.02);
            width: 100%;
            max-width: 100%;
            box-sizing: border-box;
        }

        .page-content {
            padding: 24px 28px;
            flex-grow: 1;
            width: 100%;
            max-width: 100%;
            box-sizing: border-box;
            overflow-x: hidden;
        }

        footer {
            width: 100%;
            max-width: 100%;
            box-sizing: border-box;
        }

        /* Cards & Metrics */
        .pro-card {
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
            transition: all 0.2s ease;
            max-width: 100%;
            box-sizing: border-box;
        }

        .pro-card:hover {
            box-shadow: 0 6px 24px rgba(0, 0, 0, 0.06);
        }

        .metric-icon-box {
            width: 52px;
            height: 52px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            flex-shrink: 0;
        }

        .table-responsive {
            width: 100%;
            max-width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        .table > :not(caption) > * > * {
            padding: 14px 16px;
            vertical-align: middle;
        }

        .table thead th {
            background: #F8FAFC;
            color: #475569;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #E2E8F0;
            white-space: nowrap;
        }

        .badge-soft-primary { background: rgba(13, 110, 253, 0.12); color: #0D6EFD; }
        .badge-soft-success { background: rgba(16, 185, 129, 0.12); color: #10B981; }
        .badge-soft-warning { background: rgba(245, 158, 11, 0.12); color: #D97706; }
        .badge-soft-danger  { background: rgba(239, 68, 68, 0.12); color: #EF4444; }
        .badge-soft-info    { background: rgba(6, 182, 212, 0.12); color: #06B6D4; }

        @media (max-width: 992px) {
            .sidebar { 
                transform: translateX(-100%); 
            }
            .sidebar.show { 
                transform: translateX(0); 
            }
            .main-wrapper { 
                margin-left: 0 !important; 
                width: 100% !important; 
                max-width: 100% !important; 
            }
            .top-navbar, .page-content {
                padding-left: 16px;
                padding-right: 16px;
            }
        }
    </style>
</head>
<body>
<div class="admin-layout-root">
