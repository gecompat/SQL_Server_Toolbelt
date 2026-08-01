#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[2]
required = [
 'Source/TVF_CurrentExecutionContext.sql', 'Source/SVF_CurrentExecutionId.sql',
 'Source/USP_BeginExecution.sql', 'Source/USP_SetExecutionContext.sql',
 'Source/USP_EndExecution.sql', 'Deployment/Deploy.sql', 'Deployment/Uninstall.sql',
 'README.md', 'Documentation/EXECUTION_CONTEXT_OBJECTS.md',
 'Tests/Runtime/ExecutionContext.Contract.sql', 'Tests/Runtime/MultiSession.Contract.sql',
 'Tests/Runtime/Lifecycle.Contract.sql', 'Tests/Runtime/Central.Contract.sql',
 'Tests/EXECUTION_CONTEXT_CONTRACT_TEST_MATRIX.md', 'module.yaml'
]
missing=[p for p in required if not (root/p).is_file()]
if missing: raise SystemExit('Fehlende Artefakte: '+', '.join(missing))
all_source='\n'.join((root/p).read_text('utf-8') for p in required if p.startswith('Source/'))
for marker in ('SESSION_CONTEXT', 'sp_set_session_context',
 'TVF_CurrentExecutionContext', 'SVF_CurrentExecutionId',
 'USP_BeginExecution', 'USP_SetExecutionContext', 'USP_EndExecution',
 'toolbelt.execution.id', 'toolbelt.execution.depth'):
 if marker not in all_source: raise SystemExit('Vertragsmarker fehlt: '+marker)
print('Execution Context statische Vertragsprüfung: erfolgreich')
