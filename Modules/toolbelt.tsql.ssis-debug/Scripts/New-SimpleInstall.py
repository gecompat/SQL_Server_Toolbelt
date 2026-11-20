"""DTSX-Funktionssatz über denselben markerfreien Kern wie alle Module bauen."""
import argparse
import hashlib
import json
from pathlib import Path

MODULE=Path(__file__).resolve().parents[1]
REPO=MODULE.parents[1]


def sha(data,algorithm='sha256'):
    return hashlib.new(algorithm,data).hexdigest().upper()


def validate_inputs(ssis_release, scriptdom, mode="auto"):
    if mode not in {"auto", "hash", "trustworthy-checked", "trustworthy"}:
        raise ValueError("SIMPLE_INSTALL_TRUST_MODE")
    manifest = json.loads((ssis_release / "Toolbelt.Tsql.SsisDebug.trust-manifest.json").read_text(encoding="utf-8-sig"))
    provider = (ssis_release / "Toolbelt.Tsql.SsisDebug.dll").read_bytes()
    dom = scriptdom.read_bytes()
    if manifest.get("moduleId") != "toolbelt.tsql.ssis-debug" or manifest.get("permissionSet") != "UNSAFE" or not manifest.get("reproducedBuild") or sha(provider, "sha512") != manifest["sha512"] or sha(dom, "sha512") != manifest["scriptDomSha512"]:
        raise ValueError("SIMPLE_INSTALL_BINARY_BINDING")
    inventory = {p.resolve() for p in (MODULE / "Clr").rglob("*") if p.suffix in {".cs", ".csproj"} and not {"bin", "obj", ".runtime"}.intersection(p.relative_to(MODULE / "Clr").parts)}
    inventory.update(p.resolve() for p in (MODULE / "Exchange/Core").glob("*.cs"))
    inventory.add((MODULE.parent / "toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs").resolve())
    declared = {(MODULE / e.rsplit(":", 1)[0]).resolve() for e in manifest["sourceFiles"]}
    if inventory != declared:
        raise ValueError("SIMPLE_INSTALL_COMPILED_SOURCE_INVENTORY")
    for entry in manifest["sourceFiles"]:
        name, expected = entry.rsplit(":", 1)
        path = (MODULE / name).resolve()
        if not path.is_relative_to(REPO.resolve()) or path.suffix not in {".cs", ".csproj"} or sha(path.read_bytes()) != expected:
            raise ValueError("SIMPLE_INSTALL_COMPILED_SOURCE_DRIFT")
    if sha("\n".join(manifest["sourceFiles"]).encode()) != manifest["sourceFingerprintSha256"]:
        raise ValueError("SIMPLE_INSTALL_SOURCE_MANIFEST")
    deployment = dict(e.rsplit(":", 1) for e in manifest["deploymentFiles"])
    for name in ("USP_ExplainSsisDataFlow.sql", "USP_ExplainSsisDataFlowInternal.sql"):
        if deployment.get("Source/" + name) != sha((MODULE / "Source" / name).read_bytes()):
            raise ValueError("SIMPLE_INSTALL_FACADE_SOURCE_DRIFT")

    return {'provider':provider,'scriptdom':dom,'manifest':manifest}


def build(ssis_release,scriptdom,output,mode='auto',deployment_mode='local'):
    # Same current kernel as the common and other module installers.
    import importlib.util
    import shutil
    import sys
    import uuid
    validated=validate_inputs(ssis_release,scriptdom,mode)
    sys.path.insert(0,str(REPO/'Scripts/Install'))
    spec=importlib.util.spec_from_file_location('common_install',REPO/'Scripts/Install/New-SimpleCommonInstall.py')
    common=importlib.util.module_from_spec(spec);spec.loader.exec_module(common)
    work=REPO/'.runtime'/('ssis-simple-'+uuid.uuid4().hex)
    inputs=work/'inputs'
    (inputs/'ssis').mkdir(parents=True)
    (inputs/'parser').mkdir()
    for name in ('Toolbelt.Tsql.SsisDebug.dll','Toolbelt.Tsql.SsisDebug.trust-manifest.json'):
        shutil.copyfile(ssis_release/name,inputs/'ssis'/name)
    (inputs/'parser/tlblt.Microsoft.SqlServer.TransactSql.ScriptDom.dll').write_bytes(validated['scriptdom'])
    return common.build(inputs,work/'parse',output.resolve(),'Windows',deployment_mode,mode,
                        ['toolbelt.tsql.ssis-debug'])


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ssis-release',type=Path,required=True)
    parser.add_argument('--scriptdom',type=Path,required=True)
    parser.add_argument('--trust-mode',choices=['auto','hash','trustworthy-checked','trustworthy'],default='auto')
    parser.add_argument('--mode',choices=['local','central'],default='local')
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    build(args.ssis_release,args.scriptdom,args.output,args.trust_mode,args.mode)
    print('SSIS_SIMPLE_INSTALL_CREATED common kernel; no SQL executed')


if __name__=='__main__':main()
