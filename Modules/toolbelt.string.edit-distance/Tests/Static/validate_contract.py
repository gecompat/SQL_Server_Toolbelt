"""Statische Kopplung; kein nativer SQL- oder Laufzeitnachweis."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[4]
module=root/'Modules/toolbelt.string.edit-distance'
source=(module/'Source/EditDistance.sql').read_text(encoding='utf-8')
assert re.findall(r'CREATE FUNCTION toolbelt_string\.(\w+)',source)==['TVF_LevenshteinDistanceCore','TVF_LevenshteinDistance','TVF_OsaDistanceCore','TVF_OsaDistance']
assert source.count('RETURNS TABLE (Distance int, ExceedsMaxDistance bit, ErrorCode int)')==2
assert source.count('@MaxDistance int = NULL')==2
assert 'GO--' not in source
assert source.count("@Profile nvarchar(max) = N'standard'")==2
kernel=(module/'Clr/DistanceKernel.cs').read_text(encoding='utf-8')
provider=(module/'Clr/DistanceProvider.cs').read_text(encoding='utf-8')
assert 'PlannedCells' in kernel and 'older[j-2]+1' in kernel
assert 'Int32.MaxValue' not in kernel and 'threshold.Value+1' not in kernel
assert provider.index('if (left.IsNull || right.IsNull)')<provider.index('profile.Length')<provider.index('left.Length > units')<provider.index('DistanceKernel.Evaluate(Copy(left)')
for text in (kernel,provider):
 assert not re.search(r'\b(File|Directory|Process|Thread|Task|Registry|HttpClient|WebClient|SqlConnection|SqlCommand)\b',text)
 assert '\ufffd' not in text
for name in ('Deploy.sql','Uninstall.sql'):
 text=(module/'Deployment'/name).read_text(encoding='utf-8')
 assert text.index('IF @@TRANCOUNT <> 0')<text.index('SET NOCOUNT ON')
 assert 'WHILE @Pass <= 2' in text and 'sp_getapplock' in text
 assert text.index("N'VIEW DEFINITION'") > text.index('WHILE @Pass <= 2')
 assert 'p.user_type_id<>p.system_type_id' in text and 'c.user_type_id<>c.system_type_id' in text
 assert 'ExpectedInstalledAssemblyHash' in text and 'HASHBYTES(N\'SHA2_512\', f.content)' in text
 assert "N'1.1.0'" not in text and "N'1.3.0'" not in text
 for n in ('TVF_LevenshteinDistance','TVF_OsaDistance','TVF_LevenshteinDistanceCore','TVF_OsaDistanceCore'):
  assert n in text
 assert 'GRANT ' not in text and 'RECONFIGURE' not in text and 'sp_add_trusted_assembly' not in text
 assert 'Toolbelt.SchemaCategory' in text and 'Source/Regex' not in text
for path in module.rglob('*'):
 if path.is_file() and path.suffix in ('.cs','.sql','.md','.py','.ps1','.yaml') and not any(x in path.parts for x in ('obj','bin','__pycache__')):
  text=path.read_text(encoding='utf-8');assert '\ufffd' not in text,str(path)
print('PASS edit-distance static')