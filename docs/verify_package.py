#!/usr/bin/env python3
from pathlib import Path
import csv,json,hashlib,sys
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text())
errors=[]
for e in manifest['files']:
 p=root/e['path']
 if not p.is_file():errors.append('missing '+e['path']);continue
 if hashlib.sha256(p.read_bytes()).hexdigest()!=e['sha256']:errors.append('checksum '+e['path'])
idx=list(csv.DictReader((root/'storyboard/SCREEN_INDEX.csv').open()))
for r in idx:
 for field in ('spec_md','reference_png'):
  if not r[field] or not (root/r[field]).exists():errors.append('screen '+r['id']+' missing '+field)
 if Path(r['spec_md']).stem!=Path(r['reference_png']).stem: errors.append('mismatch '+r['id'])
if len(idx)!=40:errors.append('expected 40 screens')
print(json.dumps({'manifest_files':len(manifest['files']),'screens':len(idx),'errors':errors},indent=2))
sys.exit(1 if errors else 0)
