#!/usr/bin/env python3
"""Generate only the public iOS callback setting. Never prints client values."""
import json,pathlib,re,sys
root=pathlib.Path(__file__).resolve().parents[1]
file=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else root/'config/release.public.json')
try:
    values=json.loads(file.read_text())
    client=values.get('GOOGLE_IOS_CLIENT_ID','')
    required=['FIREBASE_PROJECT_ID','FIREBASE_MESSAGING_SENDER_ID','FIREBASE_IOS_API_KEY','FIREBASE_IOS_APP_ID','GOOGLE_WEB_CLIENT_ID']
    if not re.fullmatch(r'[0-9]+-[A-Za-z0-9-]+\.apps\.googleusercontent\.com',client):
        raise ValueError('GOOGLE_IOS_CLIENT_ID')
    missing=[key for key in required if not isinstance(values.get(key),str) or not values[key].strip()]
    if missing: raise ValueError(', '.join(missing))
    for key in values:
        if any(word in key.upper() for word in ['SECRET','PRIVATE','PASSWORD','TOKEN']): raise ValueError('secret-like field rejected')
    scheme='.'.join(reversed(client.split('.')))
    (root/'ios/Flutter/Auth.generated.xcconfig').write_text('// Generated public OAuth callback; no secrets.\nGOOGLE_REVERSED_CLIENT_ID = '+scheme+'\n')
except (OSError,ValueError,TypeError) as error:
    print('AUTH NOT READY: missing/invalid public configuration; '+str(error) if isinstance(error,ValueError) else 'AUTH NOT READY: could not read public configuration.')
    sys.exit(1)
print('Public iOS callback generated. Build with the SAME config file using --dart-define-from-file; verify real provider dashboards and callback on a device.')
