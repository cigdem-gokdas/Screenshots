#!/usr/bin/env python3
"""Stdlib-only secret scan. Prints file:line and rule name only, never values.

Usage: scan_secrets.py [files...]   (default: all `git ls-files`, else tree walk)
"""
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
RULES = [
    ('google-api-key', r'AIza[0-9A-Za-z_-]{35}'),
    ('revenuecat-apple-key', r'appl_[A-Za-z0-9]{20,}'),
    ('revenuecat-google-key', r'goog_[A-Za-z0-9]{20,}'),
    ('stripe-key', r'sk_(?:live|test)_'),
    ('private-key', r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    ('github-token', r'ghp_'),
    ('slack-token', r'xox[baprs]-'),
]
COMPILED = [(n, re.compile(p)) for n, p in RULES]
BAD_NAMES = {'GoogleService-Info.plist', 'google-services.json', '.env'}
BAD_SUFFIXES = ('.p8', '.p12', '.jks')
SKIP_DIRS = {'.git', '.dart_tool', 'build', 'ephemeral', '.symlinks', '.idea',
             '.gradle', 'xcuserdata', 'Pods', 'node_modules', 'DerivedData'}
SELF = pathlib.Path(__file__).resolve()


def candidate_files(args):
    if args:
        return [pathlib.Path(a).resolve() for a in args]
    try:
        out = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, check=True,
                             capture_output=True).stdout.decode()
        files = [ROOT / p for p in out.split('\0') if p]
        if files:
            return files
    except (OSError, subprocess.CalledProcessError):
        pass
    files = []
    for parent, dirs, names in os.walk(ROOT, followlinks=False):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS
                   and not d.startswith('.ephemeral-preserved-')
                   and not (pathlib.Path(parent) / d).is_symlink()]
        for n in names:
            p = pathlib.Path(parent) / n
            if p.is_symlink() or n == '.DS_Store' or n.endswith('.log'):
                continue
            if n == 'release.public.json' or n == 'Auth.generated.xcconfig':
                continue  # gitignored owner-local files
            files.append(p)
    return files


def main():
    hits = 0
    for f in candidate_files(sys.argv[1:]):
        if f == SELF or not f.is_file() or f.is_symlink():
            continue
        try:
            rel = f.relative_to(ROOT)
        except ValueError:
            rel = f
        name = f.name
        if name in BAD_NAMES or name.startswith('.env.') and name != '.env.example' \
                or name.endswith(BAD_SUFFIXES):
            print(f'{rel}: forbidden-file-name'); hits += 1
            continue
        try:
            text = f.read_text(encoding='utf-8', errors='ignore')
        except OSError:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            for rule, rx in COMPILED:
                if rx.search(line):
                    print(f'{rel}:{i}: {rule}'); hits += 1
    print(f'scan_secrets: {hits} finding(s)')
    return 1 if hits else 0


if __name__ == '__main__':
    sys.exit(main())
