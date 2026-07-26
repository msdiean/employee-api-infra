import zipfile
import os
import hashlib

os.makedirs('lambda_build', exist_ok=True)

# Create index.js with a simple handler
with open('lambda_build/index.js', 'w') as f:
    f.write('exports.handler = async (event) => { return { statusCode: 200, body: JSON.stringify({message: "OK"}) }; };')

# Create zip file with fixed timestamp for reproducibility
with zipfile.ZipFile('employee-api.zip', 'w', zipfile.ZIP_DEFLATED) as zf:
    zinfo = zipfile.ZipInfo('index.js', date_time=(2024, 1, 1, 0, 0, 0))
    with open('lambda_build/index.js', 'rb') as f:
        zf.writestr(zinfo, f.read())

import shutil
shutil.rmtree('lambda_build')

# Verify
size = os.path.getsize('employee-api.zip')
with open('employee-api.zip', 'rb') as f:
    sha256 = hashlib.sha256(f.read()).hexdigest()
print(f'✓ Created employee-api.zip ({size} bytes, SHA256: {sha256[:16]}...)')
