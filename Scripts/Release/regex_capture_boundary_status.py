"""Vorhandene große Capture-Ausgabegrenzen quellgebunden wiederverwenden."""
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import prepare_release as release

ROOT=Path(__file__).resolve().parents[2]
REPORT='Releases/1.0.0/regex-timeout-qualification.json'
ACCEPTANCE='Releases/1.0.0/capture-release-acceptance.json'
METHOD='Tests/Release/Invoke-ApiQualificationLab.ps1'
FIXTURE='Modules/toolbelt.string.regex/Tests/Runtime/Captures.Metadata.ps1'
ID='toolbelt.string.regex:Captures.Metadata.ps1'


def normalized(data):return data.replace(b'\r\n',b'\n')
def digest(data):return hashlib.sha256(normalized(data)).hexdigest()
def require(condition,message):
    if not condition:raise ValueError('Capture boundary status: '+message)


@lru_cache(maxsize=1)
def recover(bundle,source_commit,product_commit):
    return release.recovered_snapshot(bundle,source_commit,product_commit)[1]


def original_product(report):
    # Derselbe bereits vorhandene Offline-Bundlereader wie im ursprünglichen
    # Releasegate; keine neuen Refs, kein Remote und keine Labverbindung.
    binding=json.loads((ROOT/'Releases/1.0.0/runtime-source-equivalence.json').read_bytes())
    binary=release.git('show',binding['public_baseline_commit']+':'+release.ARTIFACTS+release.NAME+'.zip')
    require(hashlib.sha256(binary).hexdigest()==binding['previous_source_zip_sha256'],'original source ZIP')
    files=release.read_zip(binary);prefix=release.NAME+'/'
    manifest=json.loads(files[prefix+'PACKAGE-MANIFEST.json'])
    require(manifest['product_commit']==report['product_commit'],'original product commit')
    return recover(files[prefix+'PREPARATION.bundle'],manifest['source_commit'],report['product_commit'])


def validate(report=None,acceptance=None):
    r=report if report is not None else json.loads((ROOT/REPORT).read_bytes())
    a=acceptance if acceptance is not None else json.loads((ROOT/ACCEPTANCE).read_bytes())
    definitions=[d for d in r['fixture_definitions'] if d['id']==ID]
    require(len(definitions)==1 and definitions[0]['kind']=='captures-metadata' and definitions[0]['large'] is True,'large fixture enabled')
    expected={(p,v,cl) for p in ('linux','windows') for v,levels in (('2019',(150,)),('2022',(150,160)),('2025',(150,160,170))) for cl in levels}
    cases=r['native_api_cases']
    require(len(cases)==12 and {(c['platform'],c['sql_version'],c['compatibility_level']) for c in cases}==expected,'complete original matrix')
    for c in cases:
        require(c['independent_cleanup_and_pins'] is True and all(ID+':'+mode in c['passed'] for mode in ('local','central')),'original metadata call/audit missing')
        require(not any(b['id']==ID for b in c['blocked']),'metadata call was blocked')
    require(cases[0]['result']=='PARTIAL' and cases[0]['blocked'],'historical partial must remain')
    require(a['historical_capture_timeout_gate']=='accepted for exact qualified binary' and a['historical_cause']=='unknown, not reproduced','acceptance limits')
    require(digest((ROOT/REPORT).read_bytes())==a['prior_evidence_sha256'][REPORT],'immutable native record binding')
    require(a['delivered_regex_binary_sha256']==r['delivered_regex_binary_sha256'],'qualified binary binding')
    original=original_product(r)
    for path in (METHOD,FIXTURE):
        require(digest(original[path])==r['source_sha256'][path],'original method/fixture')
    method=normalized(original[METHOD]).decode('utf-8')
    fixture=normalized(original[FIXTURE]).decode('utf-8')
    require("'captures-metadata' {$arguments.Database=$Database;" in method and '$arguments.IncludeLargeBoundary=$true;& $path @arguments' in method,'executed large opt-in')
    require("@{Name='large';Units=8388608}" in fixture and '$profileCase.Units - 128' in fixture and '$profileCase.Units - 127' in fixture and "'TBX_REGEX_OUTPUT_TOO_LARGE'" in fixture,'exact original UTF16 boundary oracles')
    package=release.read_zip((ROOT/release.CLR_PACKAGE).read_bytes())
    dll=package['SQL-Server-Toolbelt-1.0.0-CLR-Install/Binaries/Toolbelt.String.Regex.dll']
    require(hashlib.sha256(dll).hexdigest()==a['delivered_regex_binary_sha256'],'delivered exact binary')
    paths=[p for p in original if p.startswith('Modules/toolbelt.string.regex/Clr/') and p.endswith(('.cs','.csproj'))]
    paths.append('Modules/toolbelt.string.regex/Source/RegexCaptures.sql')
    binding=json.loads((ROOT/'Releases/1.0.0/runtime-source-equivalence.json').read_bytes())
    current=True
    for path in paths:
        if not (ROOT/path).is_file():current=False;continue
        now=(ROOT/path).read_bytes()
        if normalized(now)==normalized(original[path]):continue
        # Einzige bereits separat qualifizierte Abweichung dieses Scopes:
        # der präzise gebundene EXECUTE-Rechtekommentar der anderen SVF im
        # gemeinsamen SQL-File. Keine neue allgemeine Kommentar-/Hashausnahme.
        allowed=(path=='Modules/toolbelt.string.regex/Source/RegexCaptures.sql' and
          digest(original[path])==binding['previous_source_sha256'][path] and
          digest(now)==binding['current_source_sha256'][path] and
          binding['runtime_sql_change']=='exactly five known SQL header comments; every executable byte unchanged')
        current=current and allowed
    return dict(status='REUSED_ORIGINAL_NATIVE_CAPTURE_BOUNDARIES',routes=24,new_native_calls=0,
                large_exact_bytes=16777216,large_over_bytes=16777218,
                current_capture_product_source_match=current,historical_partial_preserved=True)


if __name__=='__main__':print(json.dumps(validate(),sort_keys=True))
