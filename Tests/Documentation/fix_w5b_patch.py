#!/usr/bin/env python3
from pathlib import Path

path=Path('Tests/Documentation/patch_w5b_repository.py')
text=path.read_text(encoding='utf-8')
old="""if phase.strip() not in roadmap:
    marker='### Phase 2.12 – Second Session\\n'
    pos=roadmap.find(marker)
    if pos<0: raise RuntimeError('Roadmap Second-Session-Phase fehlt.')
    next_pos=roadmap.find('\\n### ',pos+5)
    if next_pos<0: roadmap=roadmap+'\\n'+phase
    else: roadmap=roadmap[:next_pos+1]+phase+roadmap[next_pos+1:]
"""
new="""if phase.strip() not in roadmap:
    marker='### Phase 2.6 – Portable File Content\\n'
    if roadmap.count(marker)!=1: raise RuntimeError('Roadmap-Portable-File-Content-Marker fehlt oder ist mehrfach vorhanden.')
    roadmap=roadmap.replace(marker,phase+marker,1)
"""
if text.count(old)!=1:
    raise SystemExit(f'Erwarteter Roadmap-Patchblock wurde {text.count(old)}-mal gefunden.')
path.write_text(text.replace(old,new,1),encoding='utf-8',newline='\n')

static_path=Path('Modules/toolbelt.core.second-session/Tests/Static/validate_contract.py')
static=static_path.read_text(encoding='utf-8')
marker='    "HAS_PERMS_BY_NAME",\n'
addition='    "COLLATE DATABASE_DEFAULT",\n'
if addition not in static:
    if static.count(marker)!=1:
        raise SystemExit('Second-Session-Static-Marker ist nicht eindeutig.')
    static=static.replace(marker,marker+addition,1)
static_path.write_text(static,encoding='utf-8',newline='\n')
