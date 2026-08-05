#!/usr/bin/env python3
from __future__ import annotations

import os
import re
from pathlib import Path

ROOT=Path.cwd()
EVIDENCE_URL=os.environ.get('EVIDENCE_URL','')
DATE='2026-08-05'


def read(path:str)->str: return (ROOT/path).read_text(encoding='utf-8')
def write(path:str,text:str)->None: (ROOT/path).write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')

def insert_after(path:str,marker:str,addition:str)->None:
    text=read(path)
    if addition.strip() in text: return
    if text.count(marker)!=1: raise RuntimeError(f'{path}: Marker nicht eindeutig: {marker!r}')
    write(path,text.replace(marker,marker+addition,1))

def replace_once(path:str,old:str,new:str)->None:
    text=read(path)
    if text.count(old)!=1: raise RuntimeError(f'{path}: Treffer {text.count(old)} für {old!r}')
    write(path,text.replace(old,new,1))

# Globale Modulzahlen.
for path in ('README.md','Modules/README.md','Tests/README.md','.ai/BACKLOG.md','.ai/ROADMAP.md','.ai/PROJECT_CONTEXT.md','Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md'):
    text=read(path)
    replacements={
      '23 Module sind implementiert':'24 Module sind implementiert',
      '23 Module sind\nimplementiert':'24 Module sind\nimplementiert',
      '23 implementierte Module':'24 implementierte Module',
      '22 sind `partially validated`':'23 sind `partially validated`',
      '22 teilweise validierte Module':'23 teilweise validierte Module',
      '23 Module implementiert':'24 Module implementiert',
      '22 teilweise validiert':'23 teilweise validiert',
      'twenty_three_modules_implemented':'twenty_four_modules_implemented',
    }
    for old,new in replacements.items(): text=text.replace(old,new)
    write(path,text)

# README: Capability sichtbar machen.
readme=read('README.md')
paragraph=f'''\n[`toolbelt.core.event-log`](./Modules/toolbelt.core.event-log/README.md)\npersistiert strukturierte Events synchron in einer zweiten Session. Erfolgreiche\nWrites überleben Caller-Rollback und uncommittable Caller-Transaktionen; Linked\nServer und Login-Mappings bleiben administrativ außerhalb des Moduls.\n'''
marker='führt registrierte Work-Types synchron über einen administrativ vorbereiteten\nLoopback-Linked-Server in einer getrennten SQL-Server-Session aus.\n'
if paragraph.strip() not in readme:
    if readme.count(marker)!=1: raise RuntimeError('README Second-Session-Marker fehlt.')
    readme=readme.replace(marker,marker+paragraph,1)
write('README.md',readme)

# Registry und Change-Impact.
repo_map=read('.ai/repo_map.yaml')
repo_map=repo_map.replace('status: twenty_three_modules_implemented','status: twenty_four_modules_implemented')
registry_marker='    - Modules/toolbelt.core.second-session/module.yaml\n'
if 'Modules/toolbelt.core.event-log/module.yaml' not in repo_map:
    if repo_map.count(registry_marker)!=1: raise RuntimeError('Registry-Marker fehlt.')
    repo_map=repo_map.replace(registry_marker,registry_marker+'    - Modules/toolbelt.core.event-log/module.yaml\n',1)
package='''    event_log_contract:
      paths:
        - Modules/toolbelt.core.event-log/**
        - Modules/toolbelt.core.second-session/**
        - Documentation/Architecture/EVENT_LOG_MODULE_DESIGN.md
        - Tests/CI/run-w5b-event-log-linux.sh
        - .github/workflows/w5b-event-log-runtime.yml
      checks:
        - markdown_links
'''
if '    event_log_contract:' not in repo_map:
    marker='    file_content_contract:\n'
    if repo_map.count(marker)!=1: raise RuntimeError('Change-Impact-Marker fehlt.')
    repo_map=repo_map.replace(marker,package+marker,1)
write('.ai/repo_map.yaml',repo_map)

# Kandidat TC-2026-014.
candidate_path='Backlog/TOOLBELT_CANDIDATES.md'
candidates=read(candidate_path)
match=re.search(r'(^## TC-2026-014:.*?)(?=^## TC-|\Z)',candidates,flags=re.MULTILINE|re.DOTALL)
if match is None: raise RuntimeError('TC-2026-014 fehlt.')
section=match.group(1)
fields={
 'Mögliche Technologie':'Implementiert als `toolbelt.core.event-log` über den synchronen Loopback-RPC-Provider aus `toolbelt.core.second-session` Version 1.1.0. `USP_WriteEvent` nutzt einen registrierten JSON-Work-Type und unterdrückt das lokale Infrastruktur-Resultset. Service Broker und SQL CLR External Access bleiben für Version 1 ausgeschlossen.',
 'Dependencies':'`toolbelt.core.second-session` 1.1.0, `toolbelt.core.work-type` 1.1.0 und `toolbelt.core.execution-context` 1.0.0.',
 'Status':'`implemented`; Runtime `partially validated`',
 'Prüfdatum':DATE,
 'Nächster Schritt':'Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Blockierungs- und Berechtigungsprofile des administrierten Loopback-Providers betriebsbezogen prüfen.',
}
for field,value in fields.items():
    section,count=re.subn(rf'^\| \*\*{re.escape(field)}\*\* \|.*$',f'| **{field}** | {value} |',section,count=1,flags=re.MULTILINE)
    if count!=1: raise RuntimeError(f'TC-2026-014 Feld fehlt: {field}')
write(candidate_path,candidates[:match.start()]+section+candidates[match.end():])

# Implementierungsplan: W5 und implementierte Module.
plan_path='Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md'
plan=read(plan_path)
plan=plan.replace(
 '| `W5` | `active` | Session- und Ausführungsprovider | `046`, `014` | `017`, `019`, `022`; Provider- und Security-Entscheidung | `toolbelt.core.second-session` ist als synchroner Loopback-RPC-Provider implementiert und auf SQL Server 2025 Linux teilweise validiert. Rollback-unabhängiges Event Logging bleibt W5b. |',
 '| `W5` | `completed` | Session- und Ausführungsprovider | `046`, `014` | `017`, `019`, `022`; Provider- und Security-Entscheidung | `toolbelt.core.second-session` und `toolbelt.core.event-log` sind implementiert und auf SQL Server 2025 Linux teilweise validiert. |'
)
implemented_row=f"| `TC-2026-014` | `toolbelt.core.event-log` | `toolbelt_core.USP_WriteEvent`, `VW_Events`, `USP_DeleteEventsBefore` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; betriebliche Loopback-Blockierungsprofile. |\n"
if implemented_row.strip() not in plan:
    marker='| `TC-2026-016` | `toolbelt.core.console-message`'
    idx=plan.find(marker)
    if idx<0: raise RuntimeError('Implementierte-Modul-Tabelle-Marker fehlt.')
    plan=plan[:idx]+implemented_row+plan[idx:]
write(plan_path,plan)

# Kanonischer Backlog: abgeschlossenes AP.
backlog_path='.ai/BACKLOG.md'
backlog=read(backlog_path)
entry=f'''### AP-2026-029: TC-2026-014 Rollback-independent Event Log

| Feld | Wert |
|---|---|
| ID | `AP-2026-029` |
| Ziel | Strukturierte Events synchron in einer zweiten Session persistieren, sodass sie Caller-Rollback und uncommittable Caller überleben. |
| Scope | `toolbelt.core.event-log` Version `1.0.0`, EventLog-Tabelle, View, Writer, Retention, interner Work Type sowie Second Session `@SuppressResult`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | SQL Server 2025 Linux CL150/160/170; Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall. |
| Evidenz | {EVIDENCE_URL} |
| Nächster Schritt | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |

'''
if entry.strip() not in backlog:
    marker='## Abgeschlossene Arbeitspakete\n\n'
    if backlog.count(marker)!=1: raise RuntimeError('BACKLOG-Abschlussmarker fehlt.')
    backlog=backlog.replace(marker,marker+entry,1)
write(backlog_path,backlog)

# Roadmap, Changelog und Tests-Inventar.
roadmap_path='.ai/ROADMAP.md'
roadmap=read(roadmap_path)
phase=f'''### Phase 2.13 – Rollback-independent Event Log

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.event-log` persistiert strukturierte Events über die synchrone zweite Session. Caller-Rollback und uncommittable Caller sind auf SQL Server 2025 Linux CL150/160/170 nachgewiesen. Evidence: {EVIDENCE_URL}.

'''
if phase.strip() not in roadmap:
    marker='### Phase 2.12 – Second Session\n'
    pos=roadmap.find(marker)
    if pos<0: raise RuntimeError('Roadmap Second-Session-Phase fehlt.')
    next_pos=roadmap.find('\n### ',pos+5)
    if next_pos<0: roadmap=roadmap+'\n'+phase
    else: roadmap=roadmap[:next_pos+1]+phase+roadmap[next_pos+1:]
write(roadmap_path,roadmap)

changelog=read('CHANGELOG.md')
change=f'''## {DATE} – W5b Event Log

- `toolbelt.core.second-session` auf Version `1.1.0` mit `@SuppressResult` erweitert.
- `toolbelt.core.event-log` Version `1.0.0` implementiert: rollback-unabhängiger Writer, Event-View, begrenzte Retention und sauberer Work-Type-Lifecycle.
- SQL Server 2025 Linux CL150/160/170 einschließlich Rollback, uncommittable Caller, Concurrency, Central und Uninstall erfolgreich.

'''
if change.strip() not in changelog:
    marker='# CHANGELOG\n\n'
    if changelog.count(marker)!=1: raise RuntimeError('CHANGELOG-Marker fehlt.')
    changelog=changelog.replace(marker,marker+change,1)
write('CHANGELOG.md',changelog)

tests=read('Tests/README.md')
row=f"| `toolbelt.core.event-log` | [EVENT_LOG_CONTRACT_TEST_MATRIX.md](../Modules/toolbelt.core.event-log/Tests/EVENT_LOG_CONTRACT_TEST_MATRIX.md) | `partially validated`; Rollback-/uncommittable-/Context-/Retention-/Concurrency-/Central-Verträge auf SQL Server 2025 Linux CL150/160/170, Evidenz {EVIDENCE_URL} |\n"
if row.strip() not in tests:
    marker='| `toolbelt.core.error-envelope` |'
    idx=tests.find(marker)
    if idx<0: raise RuntimeError('Tests-Inventar-Marker fehlt.')
    tests=tests[:idx]+row+tests[idx:]
write('Tests/README.md',tests)

# Research-Priorität und Projektkontext nur statusbezogen.
for path in ('Backlog/TOOLBELT_RESEARCH_PRIORITIES.md','.ai/PROJECT_CONTEXT.md'):
    text=read(path)
    text=text.replace('23 Module','24 Module').replace('22 sind `partially validated`','23 sind `partially validated`')
    write(path,text)

print('W5b-Repositorykopplung: erfolgreich')
