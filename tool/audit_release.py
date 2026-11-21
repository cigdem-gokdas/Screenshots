#!/usr/bin/env python3
"""Scoped source inventory/secret-pattern checks. Never prints candidate secrets."""
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SKIP = {'.git', '.dart_tool', 'build', 'ephemeral', '.symlinks', '.idea', '.gradle', 'xcuserdata'}
PATTERNS = [r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
            r'AKIA[0-9A-Z]{16}', r'AIza[0-9A-Za-z_-]{35}',
            r'gh[pousr]_[A-Za-z0-9]{30,}', r'sk-(?:proj-)?[A-Za-z0-9_-]{30,}']
issues = []
notes = []
count = 0
def source_files():
    # Prune generated trees before walking them. Filtering rglob results still
    # enumerates SDK/build caches, which can block on cloud placeholders.
    for parent, directories, filenames in os.walk(ROOT, followlinks=False):
        directories[:] = sorted(name for name in directories
                                if name not in SKIP and not name.startswith('.ephemeral-preserved-')
                                and not (Path(parent)/name).is_symlink())
        for name in sorted(filenames):
            yield Path(parent)/name

Path = pathlib.Path
for file in source_files():
    relative = file.relative_to(ROOT)
    if any(part.startswith('.ephemeral-preserved-') for part in relative.parts): continue
    if not file.is_file() or file.is_symlink() or set(relative.parts) & SKIP:
        continue
    if file.suffix in {'.p8', '.p12', '.pfx', '.mobileprovision', '.keystore', '.jks'} or file.name in {'.env', 'key.properties', 'signing.properties'}:
        issues.append({'file': str(relative), 'reason': 'credential file'})
    if file.suffix.lower() not in {'.dart','.swift','.kt','.kts','.plist','.xcprivacy','.json','.yaml','.yml','.xml','.properties','.xcconfig','.sh','.md','.html','.cpp','.cc','.py'}:
        continue
    count += 1
    try:
        data = file.read_text(errors='replace')
    except OSError:
        issues.append({'file':str(relative),'reason':'unreadable source; audit incomplete'})
        continue
    if str(relative) == 'config/release.public.json':
        try:
            public_config = json.loads(data)
            for key in ['FIREBASE_IOS_API_KEY','FIREBASE_ANDROID_API_KEY']:
                if re.fullmatch(r'AIza[0-9A-Za-z_-]{35}',str(public_config.get(key,''))):
                    public_config[key] = '[expected public Firebase client key]'
            data = json.dumps(public_config)
        except (ValueError, AttributeError):
            issues.append({'file':str(relative),'reason':'invalid public configuration'})

    if any(re.search(pattern, data) for pattern in PATTERNS):
        issues.append({'file': str(relative), 'reason': 'recognized secret pattern; value withheld'})
    if relative.parts[0] in {'lib','ios','android'} and not file.name.endswith('.g.dart'):
        for label, pattern in [('TODO/FIXME',r'\b(?:TODO|FIXME)\b'), ('development endpoint',r'https?://(?:localhost|127\.0\.0\.1)(?:[:/]|$)'), ('logging call',r'\b(?:print|debugPrint|NSLog|Log\.[dviwe])\s*\(')]:
            if re.search(pattern, data): notes.append({'file':str(relative),'finding':label})
print(json.dumps({'source_files_scanned':count,'secret_findings':issues,'review_notes':notes,'git_history_available':(ROOT/'.git').exists()},indent=2))
sys.exit(1 if issues else 0)
