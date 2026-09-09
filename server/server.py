#!/usr/bin/env python3
"""
ProCut Dedicated Backend Server & MySQL Database Service
Provides RESTful endpoints for user authentication and multi-device cloud project synchronization.
"""

import json
import os
import sys
import sqlite3
import hashlib
import base64
import secrets
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime

# Load configuration
CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'config.json')
CONFIG = {
    'port': 5050,
    'host': '0.0.0.0',
    'use_mysql': True,
    'mysql': {
        'host': 'localhost',
        'port': 3306,
        'user': 'root',
        'password': '',
        'database': 'procut_db'
    },
    'sqlite_fallback_file': os.path.join(os.path.dirname(__file__), 'procut_local.db')
}

if os.path.exists(CONFIG_PATH):
    try:
        with open(CONFIG_PATH, 'r') as f:
            CONFIG.update(json.load(f))
    except Exception as e:
        print(f"[WARN] Failed to load config.json: {e}")

# Database Manager
class DatabaseManager:
    def __init__(self):
        self.driver = 'sqlite'
        self.mysql_conn = None
        self._init_db()

    def _init_db(self):
        if CONFIG.get('use_mysql', True):
            try:
                import pymysql
                m = CONFIG['mysql']
                print(f"[INFO] Connecting to MySQL at {m['host']}:{m['port']} (database: {m['database']})...")
                # Connect without db first to create database if not exists
                init_conn = pymysql.connect(
                    host=m['host'],
                    port=int(m['port']),
                    user=m['user'],
                    password=m['password'],
                    charset='utf8mb4'
                )
                with init_conn.cursor() as cur:
                    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{m['database']}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
                init_conn.close()

                # Connect to the database
                self.mysql_conn = pymysql.connect(
                    host=m['host'],
                    port=int(m['port']),
                    user=m['user'],
                    password=m['password'],
                    database=m['database'],
                    charset='utf8mb4',
                    autocommit=True,
                    cursorclass=pymysql.cursors.DictCursor
                )
                self.driver = 'mysql'
                print("[SUCCESS] Connected to MySQL database!")
                self._migrate_mysql()
                return
            except Exception as e:
                print(f"[NOTICE] Could not connect to MySQL ({e}).")
                print(f"[INFO] Falling back to high-performance local SQLite database for instant operation.")

        self.driver = 'sqlite'
        self._migrate_sqlite()
        print(f"[SUCCESS] Running with local SQLite database at: {CONFIG['sqlite_fallback_file']}")

    def _get_conn(self):
        if self.driver == 'mysql':
            try:
                self.mysql_conn.ping()
                return self.mysql_conn
            except Exception:
                self._init_db()
                return self.mysql_conn
        else:
            db_path = CONFIG['sqlite_fallback_file']
            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            return conn

    def _migrate_mysql(self):
        conn = self._get_conn()
        with conn.cursor() as cur:
            cur.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id VARCHAR(64) PRIMARY KEY,
                email VARCHAR(255) NOT NULL UNIQUE,
                display_name VARCHAR(255) NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                salt VARCHAR(255) NOT NULL,
                is_pro BOOLEAN DEFAULT TRUE,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_login_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_email (email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """)
            cur.execute("""
            CREATE TABLE IF NOT EXISTS projects (
                id VARCHAR(64) PRIMARY KEY,
                user_id VARCHAR(64) NOT NULL,
                user_email VARCHAR(255) NOT NULL,
                title VARCHAR(255) NOT NULL,
                aspect_ratio VARCHAR(32) DEFAULT 'ratio9_16',
                duration_ms INT DEFAULT 0,
                fps INT DEFAULT 30,
                project_json LONGTEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_user_id (user_id),
                INDEX idx_user_email (user_email)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """)
        print("[INFO] MySQL schema migration verified.")

    def _migrate_sqlite(self):
        conn = self._get_conn()
        cur = conn.cursor()
        cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            is_pro INTEGER DEFAULT 1,
            created_at TEXT,
            last_login_at TEXT
        );
        """)
        cur.execute("""
        CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            user_email TEXT NOT NULL,
            title TEXT NOT NULL,
            aspect_ratio TEXT DEFAULT 'ratio9_16',
            duration_ms INTEGER DEFAULT 0,
            fps INTEGER DEFAULT 30,
            project_json TEXT NOT NULL,
            created_at TEXT,
            updated_at TEXT
        );
        """)
        conn.commit()
        conn.close()

    # User operations
    def get_user_by_email(self, email):
        clean = email.strip().lower()
        if not clean:
            return None
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM users WHERE LOWER(email) = %s LIMIT 1", (clean,))
                row = cur.fetchone()
                return dict(row) if row else None
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("SELECT * FROM users WHERE LOWER(email) = ? LIMIT 1", (clean,))
            row = cur.fetchone()
            res = dict(row) if row else None
            conn.close()
            return res

    def get_user_by_id(self, user_id):
        clean = user_id.strip()
        if not clean:
            return None
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM users WHERE id = %s LIMIT 1", (clean,))
                row = cur.fetchone()
                return dict(row) if row else None
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("SELECT * FROM users WHERE id = ? LIMIT 1", (clean,))
            row = cur.fetchone()
            res = dict(row) if row else None
            conn.close()
            return res

    def save_user(self, user_dict):
        now_str = datetime.utcnow().isoformat()
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("""
                INSERT INTO users (id, email, display_name, password_hash, salt, is_pro, created_at, last_login_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    display_name = VALUES(display_name),
                    password_hash = VALUES(password_hash),
                    salt = VALUES(salt),
                    is_pro = VALUES(is_pro),
                    last_login_at = VALUES(last_login_at);
                """, (
                    user_dict['id'],
                    user_dict['email'].strip().lower(),
                    user_dict.get('displayName') or user_dict.get('display_name', 'ProCut Creator'),
                    user_dict['passwordHash'],
                    user_dict['salt'],
                    1 if user_dict.get('isPro', True) else 0,
                    user_dict.get('createdAt', now_str),
                    user_dict.get('lastLoginAt', now_str),
                ))
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("""
            INSERT OR REPLACE INTO users (id, email, display_name, password_hash, salt, is_pro, created_at, last_login_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                user_dict['id'],
                user_dict['email'].strip().lower(),
                user_dict.get('displayName') or user_dict.get('display_name', 'ProCut Creator'),
                user_dict['passwordHash'],
                user_dict['salt'],
                1 if user_dict.get('isPro', True) else 0,
                user_dict.get('createdAt', now_str),
                user_dict.get('lastLoginAt', now_str),
            ))
            conn.commit()
            conn.close()

    def update_password(self, email, new_hash, new_salt):
        clean = email.strip().lower()
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("UPDATE users SET password_hash = %s, salt = %s WHERE LOWER(email) = %s", (new_hash, new_salt, clean))
                return cur.rowcount > 0
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("UPDATE users SET password_hash = ?, salt = ? WHERE LOWER(email) = ?", (new_hash, new_salt, clean))
            rows = cur.rowcount
            conn.commit()
            conn.close()
            return rows > 0

    # Project operations
    def get_projects_for_user(self, user_id=None, user_email=None):
        clean_id = (user_id or '').strip()
        clean_email = (user_email or '').strip().lower()

        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("""
                SELECT project_json FROM projects
                WHERE user_id = %s OR LOWER(user_email) = %s
                ORDER BY updated_at DESC
                """, (clean_id, clean_email))
                rows = cur.fetchall()
                results = []
                for r in rows:
                    try:
                        results.append(json.loads(r['project_json']))
                    except Exception:
                        pass
                return results
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("""
            SELECT project_json FROM projects
            WHERE user_id = ? OR LOWER(user_email) = ?
            ORDER BY updated_at DESC
            """, (clean_id, clean_email))
            rows = cur.fetchall()
            results = []
            for r in rows:
                try:
                    results.append(json.loads(r['project_json']))
                except Exception:
                    pass
            conn.close()
            return results

    def save_project(self, project_dict):
        pid = project_dict['id']
        uid = project_dict.get('userId') or project_dict.get('user_id') or ''
        uemail = (project_dict.get('userEmail') or project_dict.get('user_email') or '').strip().lower()
        title = project_dict.get('title', 'Untitled Project')
        aspect = project_dict.get('aspectRatio', 'ratio9_16')
        dur = int(project_dict.get('durationMs', 0))
        fps = int(project_dict.get('fps', 30))
        json_str = json.dumps(project_dict)
        now_str = datetime.utcnow().isoformat()

        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("""
                INSERT INTO projects (id, user_id, user_email, title, aspect_ratio, duration_ms, fps, project_json, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    user_id = VALUES(user_id),
                    user_email = VALUES(user_email),
                    title = VALUES(title),
                    aspect_ratio = VALUES(aspect_ratio),
                    duration_ms = VALUES(duration_ms),
                    fps = VALUES(fps),
                    project_json = VALUES(project_json),
                    updated_at = VALUES(updated_at);
                """, (
                    pid, uid, uemail, title, aspect, dur, fps, json_str,
                    project_dict.get('createdAt', now_str),
                    project_dict.get('updatedAt', now_str),
                ))
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("""
            INSERT OR REPLACE INTO projects (id, user_id, user_email, title, aspect_ratio, duration_ms, fps, project_json, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                pid, uid, uemail, title, aspect, dur, fps, json_str,
                project_dict.get('createdAt', now_str),
                project_dict.get('updatedAt', now_str),
            ))
            conn.commit()
            conn.close()

    def delete_project(self, project_id):
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("DELETE FROM projects WHERE id = %s", (project_id,))
                return cur.rowcount > 0
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("DELETE FROM projects WHERE id = ?", (project_id,))
            rows = cur.rowcount
            conn.commit()
            conn.close()
            return rows > 0

    def stats(self):
        if self.driver == 'mysql':
            conn = self._get_conn()
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) AS count FROM users")
                uc = cur.fetchone()['count']
                cur.execute("SELECT COUNT(*) AS count FROM projects")
                pc = cur.fetchone()['count']
                return {'driver': 'MySQL', 'users_count': uc, 'projects_count': pc}
        else:
            conn = self._get_conn()
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM users")
            uc = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM projects")
            pc = cur.fetchone()[0]
            conn.close()
            return {'driver': 'SQLite (local fallback)', 'users_count': uc, 'projects_count': pc}


# Password Hashing Helper matching Dart implementation
def hash_password(password: str, salt: str) -> str:
    current = f"{password}::{salt}".encode('utf-8')
    for _ in range(1000):
        current = hashlib.sha256(current).digest()
    return base64.urlsafe_b64encode(current).decode('utf-8')

def generate_salt() -> str:
    return base64.urlsafe_b64encode(secrets.token_bytes(16)).decode('utf-8')

def verify_password(password: str, salt: str, expected_hash: str) -> bool:
    calc = hash_password(password, salt)
    return secrets.compare_digest(calc, expected_hash)


DB = DatabaseManager()


# HTTP Request Handler
class RequestHandler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors()
        self.end_headers()

    def _send_json(self, status_code, data):
        self.send_response(status_code)
        self._send_cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def _read_json(self):
        content_len = int(self.headers.get('Content-Length', 0))
        if content_len == 0:
            return {}
        body = self.rfile.read(content_len).decode('utf-8')
        return json.loads(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        qs = parse_qs(parsed.query)

        # Health Check
        if path == '/api/health' or path == '/':
            stats = DB.stats()
            self._send_json(200, {
                'status': 'ok',
                'service': 'ProCut Backend Server',
                'version': '1.0.0',
                'database': stats['driver'],
                'users': stats['users_count'],
                'projects': stats['projects_count'],
                'timestamp': datetime.utcnow().isoformat()
            })
            return

        # Get Account By Email
        if path == '/api/auth/account':
            email = qs.get('email', [''])[0].strip().lower()
            if not email:
                self._send_json(400, {'error': 'Email parameter is required'})
                return
            user = DB.get_user_by_email(email)
            if not user:
                self._send_json(404, {'error': 'User not found'})
                return
            self._send_json(200, {
                'id': user['id'],
                'email': user['email'],
                'displayName': user.get('display_name') or user.get('displayName'),
                'isPro': bool(user.get('is_pro', 1)),
                'passwordHash': user['password_hash'],
                'salt': user['salt'],
                'createdAt': str(user.get('created_at')),
                'lastLoginAt': str(user.get('last_login_at'))
            })
            return

        # Get Projects for User
        if path == '/api/projects':
            user_id = qs.get('userId', [''])[0].strip()
            user_email = qs.get('userEmail', [''])[0].strip().lower()
            if not user_id and not user_email:
                self._send_json(400, {'error': 'userId or userEmail parameter is required'})
                return
            projects = DB.get_projects_for_user(user_id=user_id, user_email=user_email)
            self._send_json(200, {'projects': projects})
            return

        self._send_json(404, {'error': 'Endpoint not found'})

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        try:
            payload = self._read_json()
        except Exception as e:
            self._send_json(400, {'error': f'Invalid JSON payload: {e}'})
            return

        # Register User
        if path == '/api/auth/register':
            email = (payload.get('email') or '').strip().lower()
            password = payload.get('password') or ''
            name = (payload.get('displayName') or payload.get('name') or 'ProCut Creator').strip()

            if not email or not password:
                self._send_json(400, {'error': 'Email and password are required'})
                return

            existing = DB.get_user_by_email(email)
            if existing:
                # If password matches, automatically sign in!
                if verify_password(password, existing['salt'], existing['password_hash']):
                    self._send_json(200, {
                        'id': existing['id'],
                        'email': existing['email'],
                        'displayName': existing.get('display_name') or existing.get('displayName'),
                        'isPro': bool(existing.get('is_pro', 1)),
                        'passwordHash': existing['password_hash'],
                        'salt': existing['salt']
                    })
                    return
                else:
                    self._send_json(409, {'error': 'An account with this email already exists. Please log in or tap Forgot Password.'})
                    return

            # Create new user
            salt = generate_salt()
            p_hash = hash_password(password, salt)
            email_hash = hashlib.sha256(email.encode('utf-8')).hexdigest()
            user_id = f"usr_{email_hash[:16]}"

            user_record = {
                'id': user_id,
                'email': email,
                'displayName': name,
                'passwordHash': p_hash,
                'salt': salt,
                'isPro': True,
                'createdAt': datetime.utcnow().isoformat(),
                'lastLoginAt': datetime.utcnow().isoformat()
            }
            DB.save_user(user_record)
            self._send_json(201, user_record)
            return

        # Login User
        if path == '/api/auth/login':
            email = (payload.get('email') or '').strip().lower()
            password = payload.get('password') or ''

            if not email or not password:
                self._send_json(400, {'error': 'Email and password are required'})
                return

            existing = DB.get_user_by_email(email)
            if not existing:
                self._send_json(404, {'error': 'No account found with this email. Please create an account.'})
                return

            if not verify_password(password, existing['salt'], existing['password_hash']):
                self._send_json(401, {'error': 'Incorrect password. Please try again or tap Forgot password to reset.'})
                return

            # Update last login
            existing_record = {
                'id': existing['id'],
                'email': existing['email'],
                'displayName': existing.get('display_name') or existing.get('displayName'),
                'passwordHash': existing['password_hash'],
                'salt': existing['salt'],
                'isPro': bool(existing.get('is_pro', 1)),
                'lastLoginAt': datetime.utcnow().isoformat()
            }
            DB.save_user(existing_record)
            self._send_json(200, existing_record)
            return

        # Forgot Password
        if path == '/api/auth/forgot-password':
            email = (payload.get('email') or '').strip().lower()
            new_pass = payload.get('newPassword') or payload.get('password') or ''

            if not email or not new_pass:
                self._send_json(400, {'error': 'Email and new password are required'})
                return

            existing = DB.get_user_by_email(email)
            if not existing:
                self._send_json(404, {'error': 'No account found with this email address.'})
                return

            new_salt = generate_salt()
            new_hash = hash_password(new_pass, new_salt)
            DB.update_password(email, new_hash, new_salt)
            self._send_json(200, {'success': True, 'message': 'Password reset successfully'})
            return

        # Backup / Upsert Project
        if path == '/api/projects/backup':
            project = payload.get('project') or payload
            pid = project.get('id')
            if not pid:
                self._send_json(400, {'error': 'Project ID is required in payload'})
                return

            DB.save_project(project)
            self._send_json(200, {
                'success': True,
                'projectId': pid,
                'savedAt': datetime.utcnow().isoformat()
            })
            return

        self._send_json(404, {'error': 'Endpoint not found'})

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path.startswith('/api/projects/'):
            pid = path[len('/api/projects/'):].strip()
            if pid:
                DB.delete_project(pid)
                self._send_json(200, {'success': True, 'deleted': pid})
                return

        self._send_json(404, {'error': 'Endpoint not found'})

    def log_message(self, format, *args):
        print(f"[{datetime.now().strftime('%H:%M:%S')}] {args[0]} {args[1]} -> {args[2]}")


def run_server():
    host = CONFIG.get('host', '0.0.0.0')
    port = int(CONFIG.get('port', 5050))
    server = HTTPServer((host, port), RequestHandler)
    print("=" * 60)
    print(f"🚀 ProCut Backend Server running on http://{host}:{port}")
    print(f"📊 Connected Database: {DB.driver.upper()}")
    print("=" * 60)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[INFO] Server stopped.")
        server.server_close()


if __name__ == '__main__':
    run_server()
