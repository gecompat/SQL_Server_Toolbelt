"""Deterministische Source-/Lifecyclekopplung; kein Runtime-Nachweis."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MOD = ROOT / 'Modules/toolbelt.metadata.table-clone'
public = (MOD / 'Source/USP_ScriptTableClone.sql').read_text(encoding='utf-8')
core = (MOD / 'Source/USP_ScriptTableCloneInternal.sql').read_text(encoding='utf-8')
deploy = (MOD / 'Deployment/Deploy.sql').read_text(encoding='utf-8')
uninstall = (MOD / 'Deployment/Uninstall.sql').read_text(encoding='utf-8')
params = [('SourceSchema','nvarchar(max)','NULL'),('SourceTable','nvarchar(max)','NULL'),
          ('TargetSchema','nvarchar(max)','NULL'),('TargetTable','nvarchar(max)','NULL'),
          ('IncludeIdentity','bit','0'),('ResultTable','sysname','NULL'),('KeepData','bit','0'),
          ('Debug','tinyint','0'),('Hilfe','bit','0')]
signature = public.split('AS\nBEGIN',1)[0]
actual = re.findall(r'@(\w+)\s+(nvarchar\(max\)|sysname|bit|tinyint)\s*=\s*(NULL|0)',signature)
assert actual == params, 'signature/default contract'
assert public.index('IF @Hilfe=1') < public.index('OBJECT_ID(N\'tempdb..#tbx_TableClone_Plan') < public.index('EXEC toolbelt_metadata.USP_ScriptTableCloneInternal\n')
assert 'EXEC sys.sp_executesql @TableDdl' not in core and 'EXEC sys.sp_executesql @IndexDdl' not in core
assert 'INSERT ... EXEC' not in core
for name in ['USP_ScriptTableClone','USP_ScriptTableCloneInternal']:
    assert f':r ../Source/{name}.sql' in deploy
    assert f"N'{name}'" in uninstall
assert "'IF', 'TF'" in deploy and "'IF', 'TF'" in uninstall
assert 'NOT EXISTS' in uninstall and 'referencing_id NOT IN' not in uninstall
for lifecycle in (deploy,uninstall):
    assert lifecycle.index('IF @@TRANCOUNT>0') < lifecycle.index('SET XACT_ABORT ON;')
    assert 'TBX_TABLE_CLONE_CALLER_TRANSACTION:' in lifecycle and 'RAISERROR' in lifecycle
assert "HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION')" in core
assert "N'1.1.0'" not in deploy+uninstall
for token in ['is_computed','is_sparse','temporal_type','ledger_type','has_filter','is_ansi_padded',
              'VIEW DEFINITION','HASHBYTES','WITHIN GROUP','SAVE TRANSACTION','53904','53906']:
    assert token in core, token
for path in ['README.md','module.yaml','Tests/Runtime/TableClone.Contract.sql','Tests/Runtime/Lifecycle.Contract.sql',
             'Tests/Runtime/Central.Contract.sql','Tests/Runtime/MinimumRights.Contract.sql','Tests/Runtime/SelectMetadata.Contract.ps1',
             'Documentation/USP_ScriptTableClone.md','Documentation/USP_ScriptTableCloneInternal.md']:
    assert (MOD/path).is_file(), path
assert not re.search(r'\b(?:THEN|ELSE|WHEN)\d',public+core)
print('TableClone static source/contract/lifecycle coupling PASS (no runtime evidence).')
