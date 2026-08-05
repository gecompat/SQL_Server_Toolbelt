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
text=text.replace(old,new,1)

count_tuple_old="""for path in ('README.md','Modules/README.md','Tests/README.md','.ai/BACKLOG.md','.ai/ROADMAP.md','.ai/PROJECT_CONTEXT.md','Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md'):
"""
count_tuple_new="""for path in ('README.md','Modules/README.md','Tests/README.md','CHANGELOG.md','.ai/BACKLOG.md','.ai/ROADMAP.md','.ai/PROJECT_CONTEXT.md','Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md'):
"""
if text.count(count_tuple_old)!=1:
    raise SystemExit(f'Erwartete Modulzahl-Dateiliste wurde {text.count(count_tuple_old)}-mal gefunden.')
text=text.replace(count_tuple_old,count_tuple_new,1)
path.write_text(text,encoding='utf-8',newline='\n')

static_path=Path('Modules/toolbelt.core.second-session/Tests/Static/validate_contract.py')
static=static_path.read_text(encoding='utf-8')
marker='    "HAS_PERMS_BY_NAME",\n'
addition='    "COLLATE DATABASE_DEFAULT",\n'
if addition not in static:
    if static.count(marker)!=1:
        raise SystemExit('Second-Session-Static-Marker ist nicht eindeutig.')
    static=static.replace(marker,marker+addition,1)
static_path.write_text(static,encoding='utf-8',newline='\n')
