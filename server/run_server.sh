#!/usr/bin/env bash
# ProCut Backend Server Launcher
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=== Starting ProCut Backend Server ==="

# Check if PyMySQL is installed for MySQL database support
if ! python3 -c "import pymysql" 2>/dev/null; then
    echo "[INFO] Installing PyMySQL library for MySQL database connection..."
    python3 -m pip install --quiet pymysql || true
fi

# Launch the server
exec python3 server.py
