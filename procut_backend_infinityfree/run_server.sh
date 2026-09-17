#!/usr/bin/env bash
# ProCut Dedicated Backend & Admin Panel Runner
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=5050
HOST="0.0.0.0"

PHP_BIN=$(which php || echo "/Applications/XAMPP/xamppfiles/bin/php")

echo "============================================================"
echo "🚀 Starting ProCut PHP Backend & Admin Panel"
echo "🌐 Listening on: http://${HOST}:${PORT}"
echo "🛡️ Admin Console: http://localhost:${PORT}/admin/login.php"
echo "📡 REST API:      http://localhost:${PORT}/api/health"
echo "============================================================"

exec "$PHP_BIN" -S "${HOST}:${PORT}" -t "$DIR" "$DIR/router.php"
