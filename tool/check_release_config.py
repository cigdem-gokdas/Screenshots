#!/usr/bin/env python3
"""Validate PUBLIC release configuration shape, without printing its values."""
import ipaddress
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit

file = Path(sys.argv[1] if len(sys.argv) > 1 else 'config/release.public.json')
if not file.is_file():
    print('NOT READY: config/release.public.json is missing. Copy the public example and follow docs/MANUAL_RELEASE_TASKS.md.')
    sys.exit(1)
try:
    values = json.loads(file.read_text())
except (ValueError, OSError):
    print('NOT READY: public release configuration could not be read.')
    sys.exit(1)
allowed = {'REVENUECAT_APPLE_PUBLIC_KEY','REVENUECAT_GOOGLE_PUBLIC_KEY','REVENUECAT_OFFERING_ID','PRO_MONTHLY_PRODUCT_ID','PRO_YEARLY_PRODUCT_ID','PRIVACY_POLICY_URL','TERMS_OF_USE_URL'}
allowed |= {'FIREBASE_PROJECT_ID','FIREBASE_MESSAGING_SENDER_ID','FIREBASE_IOS_API_KEY','FIREBASE_IOS_APP_ID','FIREBASE_ANDROID_API_KEY','FIREBASE_ANDROID_APP_ID','GOOGLE_IOS_CLIENT_ID','GOOGLE_WEB_CLIENT_ID'}
errors = []
if not isinstance(values, dict) or set(values) - allowed:
    print('NOT READY: unexpected configuration fields. Never put private/server secrets in client dart-defines.')
    sys.exit(1)
if not str(values.get('REVENUECAT_APPLE_PUBLIC_KEY','')).startswith('appl_'):
    errors.append('REVENUECAT_APPLE_PUBLIC_KEY')
if values.get('REVENUECAT_GOOGLE_PUBLIC_KEY') and not str(values['REVENUECAT_GOOGLE_PUBLIC_KEY']).startswith('goog_'):
    errors.append('REVENUECAT_GOOGLE_PUBLIC_KEY')
for key in ['REVENUECAT_OFFERING_ID','PRO_MONTHLY_PRODUCT_ID','PRO_YEARLY_PRODUCT_ID']:
    if not re.fullmatch(r'[A-Za-z0-9_.-]{1,255}', str(values.get(key,''))): errors.append(key)
if values.get('PRO_MONTHLY_PRODUCT_ID') == values.get('PRO_YEARLY_PRODUCT_ID'):
    errors.append('distinct monthly/yearly product IDs')
for key in ['PRIVACY_POLICY_URL','TERMS_OF_USE_URL']:
    try:
        raw = values.get(key,''); uri = urlsplit(raw); host = uri.hostname or ''
        invalid = uri.scheme != 'https' or not host or '.' not in host or uri.username is not None or uri.password is not None or bool(re.search(r'\s',raw))
        invalid |= any(host == reserved or host.endswith('.'+reserved) for reserved in ['localhost','local','test','invalid','example.com','example.org','example.net'])
        try: ipaddress.ip_address(host); invalid = True
        except ValueError: pass
        if invalid: errors.append(key)
    except (TypeError, ValueError): errors.append(key)
if errors:
    print('NOT READY: review configuration fields: '+', '.join(errors))
    sys.exit(1)
print('Public configuration shape passed. Verify dashboard ownership/products, live URLs, signed archive and real sandbox transactions separately; values were not printed.')
