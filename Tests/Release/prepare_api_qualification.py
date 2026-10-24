#!/usr/bin/env python3
"""Private, gebundene APIinputs; keine SQL-Verbindung und kein Produktbuild."""
from __future__ import annotations
import argparse, hashlib, io, json, re, sys, tarfile, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import prepare_release as release
import prepare_ssis_functional_fixture as ssis


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def xlsx_fixture(source: bytes, repeated: bool = False) -> bytes:
    """Die kanonischen synthetischen Parts übernehmen, nicht Providerlogik kopieren."""
    text = source.decode('utf-8-sig')
    block = text.split('public static Dictionary<string,string> Parts() {', 1)[1].split('public static Dictionary<string,string> RepeatedParts()', 1)[0]
    constants = dict(N='http://schemas.openxmlformats.org/spreadsheetml/2006/main',
                     R='http://schemas.openxmlformats.org/officeDocument/2006/relationships',
                     P='http://schemas.openxmlformats.org/package/2006/relationships')
    parts = {}
    for name, expression in re.findall(r'\{"([^"]+)",(.*?)\}\s*[,\r\n]', block):
        tokens = re.findall(r'"(?:\\.|[^"\\])*"|\b[NRP]\b', expression)
        value = ''.join(json.loads(t) if t.startswith('"') else constants[t] for t in tokens)
        # JSON/C# geben UTF16-Surrogatpaare an; ZIP/XML wird strict UTF8.
        parts[name] = value.encode('utf-16-le', 'surrogatepass').decode('utf-16-le')
    release.require(len(parts) == 6, 'XLSX_PARTS_SOURCE_CHANGED')
    if repeated:
        parts['xl/sharedStrings.xml'] = '<sst xmlns="'+constants['N']+'"><si><t>'+('x'*500000)+'</t></si></sst>'
        parts['xl/worksheets/sheet1.xml'] = '<worksheet xmlns="'+constants['N']+'"><sheetData>'+''.join(
            f'<row r="{i}"><c r="A{i}" t="s"><v>0</v></c></row>' for i in range(1,101))+'</sheetData></worksheet>'
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, 'w', compression=zipfile.ZIP_STORED if repeated else zipfile.ZIP_DEFLATED) as z:
        for name, value in parts.items():
            info = zipfile.ZipInfo(name, date_time=(2026,1,1,0,0,0))
            info.compress_type = zipfile.ZIP_STORED if repeated else zipfile.ZIP_DEFLATED
            z.writestr(info, value.encode('utf-8'))
    return stream.getvalue()


def prepare(source_zip: Path, complete_input: Path, output: Path) -> None:
    release.require(output.resolve().is_relative_to(release.runtime_root().resolve()) and not output.exists(),
                    'NEW_PRIVATE_API_DIRECTORY_REQUIRED')
    release.verify(source_zip)
    prefix = release.NAME+'/'
    source = {p[len(prefix):]: b for p,b in release.read_zip(source_zip.read_bytes()).items()}
    spec = json.loads((ROOT/'Tests/Release/api-qualification-spec.json').read_bytes())
    release.require(spec['publication_authorized'] is False and len(spec['tests']) == len({t['id'] for t in spec['tests']}), 'API_SPEC_INVALID')
    qualification = json.loads(source['Releases/1.0.0/complete-qualification.json'])
    complete_prefix = 'Toolbelt-Complete-Qualification/'
    complete = {p[len(complete_prefix):]: b for p,b in release.read_zip(complete_input.read_bytes()).items()}
    for path, expected in qualification['sql_payload_sha256'].items():
        release.require(sha(complete[path]) == expected, 'QUALIFIED_COMPLETE_PAYLOAD_DRIFT')
    metadata = json.loads(complete['CLR-PACKAGE.json'])
    nested = release.read_zip(source[release.CLR_PACKAGE])
    delivered = json.loads(nested['SQL-Server-Toolbelt-1.0.0-CLR-Install/CLR-PACKAGE.json'])
    release.require(metadata['artifacts'] == delivered['artifacts'], 'QUALIFIED_BINARY_METADATA_DRIFT')
    # Aktuelle Produkt-/Fixturesquellen müssen der ausgelieferten Quelle entsprechen.
    # Ein Git-Prozess statt eines Prozesses je Datei; kanonische Bytes, keine EOL-Drift.
    with tarfile.open(fileobj=io.BytesIO(release.git('archive','HEAD','Modules','Deployment','Workers'))) as archive:
        canonical = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    for p,b in canonical.items():
        release.require(source.get(p) == b, 'CURRENT_PRODUCT_SOURCE_DRIFT')
    for t in spec['tests']:
        path = t['source']
        if path not in source:
            release.require(path.startswith('Tests/Release/Runtime/'), 'UNQUALIFIED_MODULE_FIXTURE')
            source[path] = (ROOT/path).read_bytes()
        if t['kind'] == 'sql':
            text = source[path].decode('utf-8-sig')
            release.require(set(re.findall(r'\$\(([^)]+)\)',text)) <= {'ToolbeltDatabase','CentralDb','CompatibilityLevel','XlsxFixture','XlsxRepeatedFixture'}, 'API_UNBOUND_SQLCMD')
            release.require(re.search(r'(?im)^\s*(GRANT|DENY|REVOKE|CREATE\s+(LOGIN|USER)|ALTER\s+SERVER|KILL)\b',text) is None, 'API_EXTERNAL_SECURITY_MUTATION')
    output.mkdir()
    sources = output/'Source'
    for p,b in source.items():
        dest = sources/p
        release.require(dest.resolve().is_relative_to(sources.resolve()) and '.git' not in dest.parts, 'API_SOURCE_PATH')
        dest.parent.mkdir(parents=True,exist_ok=True); dest.write_bytes(b)
    for label,repeated in [('standard',False),('repeated',True)]:
        (output/('fixture-'+label+'.xlsx')).write_bytes(xlsx_fixture(source['Spikes/XlsxMemory/Test-Framework.ps1'],repeated))
    ssis_root = output/'SsisFunctional'
    ssis_derivation = ssis.prepare(sources, ssis_root)
    (output/'spec.json').write_bytes(release.encoded(spec))
    (output/'input.json').write_bytes(release.encoded({'schema_version':'1.0','source_zip_sha256':sha(source_zip.read_bytes()),
        'complete_input_sha256':sha(complete_input.read_bytes()),'product_commit':qualification['product_commit'],
        'complete_input':str(complete_input.resolve()),'source_root':str(sources.resolve()),'spec':str((output/'spec.json').resolve()),
        'ssis_functional_root':str(ssis_root.resolve()),'ssis_derivation':ssis_derivation,
        'native_execution':'NOT_EXECUTED','publication_authorized':False}))
    print('PASS API_INPUTS canonical fixture sources, unchanged qualified SQL/DLL payloads; no SQL connection')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(__doc__)
    parser.add_argument('--source-zip',type=Path,required=True)
    parser.add_argument('--complete-input',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    prepare(args.source_zip,args.complete_input,args.output)
