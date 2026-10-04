"""Source coupling guard; does not execute SQL or qualify native behavior."""
from pathlib import Path
import re

module = Path(__file__).resolve().parents[2]
source = (module / 'Source/USP_CompareTextPairs.sql').read_text(encoding='utf-8')
deploy = (module / 'Deployment/Deploy.sql').read_text(encoding='utf-8')
uninstall = (module / 'Deployment/Uninstall.sql').read_text(encoding='utf-8')

assert re.findall(r'CREATE OR ALTER PROCEDURE\s+([\w.]+)', source) == ['toolbelt_string.USP_CompareTextPairs']
signature = source.split('AS\nBEGIN', 1)[0]
assert re.findall(r'@(\w+)\s+(?:sysname|nvarchar\(max\)|int|bigint|bit|tinyint)\s*=', signature) == [
    'PairsTable', 'Algorithm', 'MaxDistance', 'Profile', 'MaxPairs', 'MaxTotalTextBytes',
    'MaxTotalWork', 'ResultTable', 'KeepData', 'Debug', 'Hilfe']
assert source.index('IF @Hilfe = 1') < source.index('IF XACT_STATE() = -1') < source.index('CREATE TABLE #tbx_')
assert source.index('IF @AdmissionRejected IS NULL') < source.index('CREATE TABLE #tbx_TextPairs_Input')
assert '@NextBytes>@ByteLimit-@Bytes' in source
assert source.index('IF @Charge>@MaxTotalWork-@TotalWork') < source.index('OUTER APPLY')
assert re.findall(r'OUTER APPLY\s+(toolbelt_string\.\w+)', source) == [
    'toolbelt_string.TVF_LevenshteinDistance', 'toolbelt_string.TVF_OsaDistance', 'toolbelt_string.TVF_JaroWinklerSimilarity']
# Dynamic strings must never select a provider; catalog dependencies remain static.
for literal in re.findall(r"N'((?:[^']|'')*)'", source):
    assert not re.search(r'\b(?:FROM|APPLY)\s+toolbelt_string\.TVF_', literal, re.I)
code = re.sub(r"N?'(?:[^']|'')*'", "''", source)
code = re.sub(r'--[^\n]*|/\*.*?\*/', '', code, flags=re.S)
assert not re.search(r'\bINSERT\b[^;]*\bEXEC(?:UTE)?\b', code, re.I)
publication = source[source.index('DECLARE @OwnTransaction'):]
assert publication.index('SAVE TRANSACTION @Savepoint') < publication.index('EXEC toolbelt_core.USP_PrepareResultTable') < publication.index('EXEC sys.sp_executesql @Sql') < publication.index('COMMIT TRANSACTION')
assert 'ELSE IF @OwnTransaction=0 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint' in publication
assert not re.search(r'SET\s+(?:XACT_ABORT|TRANSACTION ISOLATION)', source, re.I)
for text in (deploy, uninstall):
    assert text.index('IF @@TRANCOUNT>0') < text.index('SET XACT_ABORT ON')
    assert 'WHILE @Pass<=2' in text and 'sp_getapplock' in text
    assert text.index("N'VIEW DEFINITION'") > text.index('WHILE @Pass<=2')
    assert not re.search(r'\b(?:GRANT|RECONFIGURE|CREATE ASSEMBLY|ALTER ASSEMBLY)\b|sp_add_trusted_assembly|EXECUTE AS', text)
    assert "CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))" in text
assert "HASHBYTES(N'SHA2_512',f.content)=@ExpectedHash" in deploy
assert "DECLARE @AssemblyId int" in deploy and "m.assembly_method" in deploy
assert "DROP PROCEDURE toolbelt_string.USP_CompareTextPairs" in uninstall
assert 'DROP SCHEMA' not in uninstall and 'DROP FUNCTION' not in uninstall
# Exact T-SQL procedure ownership: a CLR PC with copied release markers must
# remain foreign. These source fixtures test classifier coupling, not native SQL.
exact_p = "NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id=@ObjectId AND type=N'P')"
for lifecycle in (deploy, uninstall):
    assert lifecycle.count(exact_p) == 1
    assert 'OBJECTPROPERTYEX' not in lifecycle
for sql in module.rglob('*.sql'):
    assert '\ufffd' not in sql.read_text(encoding='utf-8')
print('PASS text-pairs static coupling; native NOT_EXECUTED')
