import os
import struct
import subprocess

SRC = 'assets/icon/app_icon.png'
TARGET_DIRS = [
    'server',
    'server/admin',
    'server/assets/icon',
    'server/admin/assets/icon',
    'procut_backend_infinityfree',
    'procut_backend_infinityfree/admin',
    'procut_backend_infinityfree/assets/icon',
    'procut_backend_infinityfree/admin/assets/icon',
]

for d in TARGET_DIRS:
    os.makedirs(d, exist_ok=True)

# Generate individual PNG sizes
sizes = {
    'favicon-16x16.png': (16, 16),
    'favicon-32x32.png': (32, 32),
    'favicon-48x48.png': (48, 48),
    'favicon-64x64.png': (64, 64),
    'apple-touch-icon.png': (180, 180),
    'apple-touch-icon-precomposed.png': (180, 180),
    'android-chrome-192x192.png': (192, 192),
    'android-chrome-512x512.png': (512, 512),
}

temp_pngs = {}
for fname, (w, h) in sizes.items():
    temp_path = os.path.join('scratch', fname)
    subprocess.run(['sips', '-z', str(h), str(w), SRC, '--out', temp_path], check=True, stdout=subprocess.DEVNULL)
    temp_pngs[fname] = temp_path

# Generate multi-res favicon.ico (16, 32, 48, 64)
ico_sizes = [16, 32, 48, 64]
ico_data = []
for s in ico_sizes:
    p = temp_pngs[f'favicon-{s}x{s}.png']
    with open(p, 'rb') as f:
        ico_data.append((s, s, f.read()))

count = len(ico_data)
header = struct.pack('<HHH', 0, 1, count)
offset = 6 + 16 * count
entries = []
data_blobs = []

for w, h, d in ico_data:
    w_byte = 0 if w >= 256 else w
    h_byte = 0 if h >= 256 else h
    entry = struct.pack('<BBBBHHII', w_byte, h_byte, 0, 0, 1, 32, len(d), offset)
    entries.append(entry)
    data_blobs.append(d)
    offset += len(d)

temp_ico = 'scratch/favicon.ico'
with open(temp_ico, 'wb') as f:
    f.write(header)
    for e in entries:
        f.write(e)
    for d in data_blobs:
        f.write(d)

print("Created scratch/favicon.ico")

# Copy to target directories
import shutil
for base in ['server', 'procut_backend_infinityfree']:
    # Root level
    shutil.copyfile(temp_ico, os.path.join(base, 'favicon.ico'))
    for fname, p in temp_pngs.items():
        shutil.copyfile(p, os.path.join(base, fname))
    
    # Admin level
    shutil.copyfile(temp_ico, os.path.join(base, 'admin', 'favicon.ico'))
    shutil.copyfile(temp_pngs['favicon-32x32.png'], os.path.join(base, 'admin', 'favicon-32x32.png'))
    shutil.copyfile(temp_pngs['apple-touch-icon.png'], os.path.join(base, 'admin', 'apple-touch-icon.png'))
    
    # App icon png for direct img tags
    shutil.copyfile(SRC, os.path.join(base, 'assets', 'icon', 'app_icon.png'))
    shutil.copyfile(SRC, os.path.join(base, 'admin', 'assets', 'icon', 'app_icon.png'))

print("Copied all favicon and app_icon assets to server and procut_backend_infinityfree")
