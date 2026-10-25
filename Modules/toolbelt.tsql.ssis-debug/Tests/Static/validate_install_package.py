"""Prüft das versionierte Installations-ZIP ohne Build, Assemblyladen oder SQL."""
from collections import Counter
import hashlib
import json
import posixpath
from pathlib import Path, PurePosixPath
import stat
import struct
import zipfile

MODULE = Path(__file__).resolve().parents[2]
NAME = "SSIS-Debug-1.0.0-Install-Windows"
ARCHIVE = MODULE / "InstallPackages" / (NAME + ".zip")


def require(condition, reason):
    if not condition:
        raise ValueError("SSIS_INSTALL_PACKAGE_INVALID: " + reason)


def sha(data, algorithm="sha256"):
    return hashlib.new(algorithm, data).hexdigest().upper()


def no_codeview(data):
    """PE-Debugverzeichnis prüfen; ein CodeView-Eintrag kann PDB-Pfade enthalten."""
    require(data[:2] == b"MZ", "PE header")
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    require(data[pe:pe + 4] == b"PE\0\0", "PE signature")
    section_count = struct.unpack_from("<H", data, pe + 6)[0]
    optional_size = struct.unpack_from("<H", data, pe + 20)[0]
    optional = pe + 24
    magic = struct.unpack_from("<H", data, optional)[0]
    require(magic in (0x10B, 0x20B), "PE optional header")
    directories = optional + (96 if magic == 0x10B else 112)
    rva, size = struct.unpack_from("<II", data, directories + 6 * 8)
    if not rva and not size:
        return
    require(size % 28 == 0, "PE debug size")
    sections = optional + optional_size
    offset = None
    for index in range(section_count):
        virtual_size, address, raw_size, raw = struct.unpack_from("<IIII", data, sections + index * 40 + 8)
        if address <= rva < address + max(virtual_size, raw_size):
            offset = raw + rva - address
            break
    require(offset is not None and offset + size <= len(data), "PE debug bounds")
    for position in range(offset, offset + size, 28):
        require(struct.unpack_from("<I", data, position + 12)[0] != 2, "Toolbelt CodeView/PDB data")


def main(archive_path=None):
    archive_path = ARCHIVE if archive_path is None else Path(archive_path)
    expected_zip_hash = archive_path.with_suffix(".zip.sha256").read_text(encoding="ascii").split()
    require(len(expected_zip_hash) == 2 and expected_zip_hash[1] == archive_path.name, "ZIP checksum name")
    require(sha(archive_path.read_bytes()) == expected_zip_hash[0], "ZIP checksum")
    with zipfile.ZipFile(archive_path) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        require(all(count == 1 for count in Counter(name.casefold() for name in names).values()), "duplicate paths")
        for entry in entries:
            path = PurePosixPath(entry.filename)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in entry.filename
                    and ":" not in entry.filename and path.parts[0] == NAME, "unsafe ZIP path")
            require(not stat.S_ISLNK(entry.external_attr >> 16), "ZIP symlink")
        require(archive.testzip() is None, "ZIP CRC")
        payload = {name[len(NAME) + 1:]: archive.read(name) for name in names if not name.endswith("/")}
    manifest = json.loads(payload["PACKAGE-MANIFEST.json"])
    require(manifest["schemaVersion"] == 1 and manifest["packageName"] == NAME, "package schema")
    listed = [item["path"] for item in manifest["files"]]
    require(len(set(listed)) == len(listed), "manifest duplicates")
    require(set(listed) | {"PACKAGE-MANIFEST.json", "SHA256SUMS.txt"} == set(payload), "complete manifest")
    for item in manifest["files"]:
        data = payload[item["path"]]
        require(len(data) == item["bytes"] and sha(data) == item["sha256"], "payload hash")
    sums = {}
    for line in payload["SHA256SUMS.txt"].decode("utf-8").splitlines():
        digest, name = line.split("  ", 1)
        require(name not in sums and name in payload and sha(payload[name]) == digest, "file checksum")
        sums[name] = digest
    require(set(sums) == set(payload) - {"SHA256SUMS.txt"}, "complete checksums")
    ssis = "Modules/toolbelt.tsql.ssis-debug/"
    parser = "Modules/toolbelt.tsql.script-parser/"
    pins = json.loads(payload[ssis + "Contracts/DependencyPins.json"])
    require(pins == json.loads((MODULE / "Contracts/DependencyPins.json").read_text(encoding="utf-8-sig")), "current dependency pins")
    parser_manifest = json.loads(payload[parser + "Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json"])
    ssis_manifest = json.loads(payload[ssis + "Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json"])
    release_pins = json.loads((MODULE / 'Contracts/InstallPackageInputs.json').read_bytes())
    require(json.loads(payload[ssis + 'Contracts/InstallPackageInputs.json']) == release_pins, 'canonical release manifest pins')
    require(sha(payload[parser + 'Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json']) == release_pins['parser_release_manifest_sha256'] and
            sha(payload[ssis + 'Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json']) == release_pins['ssis_release_manifest_sha256'],
            'original qualified release manifests')
    require(parser_manifest["moduleVersion"] == pins["parserVersion"] == ssis_manifest["parserVersion"] == "2.0.1", "parser version")
    require(ssis_manifest["moduleVersion"] == "1.0.0", "SSIS version")
    require(parser_manifest["sha512"] == ssis_manifest["parserSha512"] == pins["parserSha512"], "parser pin")
    require(parser_manifest["scriptDomSha512"] == ssis_manifest["scriptDomSha512"] == pins["scriptDomSha512"], "ScriptDom pin")
    for prefix, assembly, release in [
        (parser, "Toolbelt.Tsql.ScriptParser.dll", parser_manifest),
        (ssis, "Toolbelt.Tsql.SsisDebug.dll", ssis_manifest),
    ]:
        binary = payload[prefix + "Artifacts/" + assembly]
        require(sha(binary, "sha512") == release["sha512"], "assembly hash")
        no_codeview(binary)
        require(sha(payload[prefix + "Artifacts/Deploy.WithAssembly.sql"]) == release["deploymentArtifactSha256"], "deployment hash")
        root = manifest['buildSourceRoots'][release['moduleId']]
        require(root == (prefix.rstrip('/') if prefix == ssis else
                        'BuildSources/ScriptParser-2.0.1/' + prefix.rstrip('/')), 'exact build source root')
        for key in ('sourceFiles', 'deploymentFiles', 'deploymentSourceFiles'):
            for item in release.get(key, []):
                relative, expected = item.split(':', 1)
                path = posixpath.normpath(root + '/' + relative)
                require(path in payload and sha(payload[path]) == expected, 'qualified build source hash')
    allowed = {'Tests/Qualification/Identities.Windows2019-2025.20261025.json':1626,
               'Tests/Qualification/Iterations.Windows2019-2025.20261025.json':1590,
               'Tests/Qualification/Release.Windows.CL.20261025.json':3516}
    require(release_pins['qualification_evidence'] in allowed, 'explicit qualification contract')
    qualification_path = ssis + release_pins['qualification_evidence']
    require(manifest['nativeBinaryQualification'] == qualification_path, 'native qualification path')
    require(json.loads(payload[qualification_path]) == json.loads((MODULE / release_pins['qualification_evidence']).read_bytes()),
            'canonical native qualification')
    qualification = json.loads(payload[qualification_path])
    explicit_cl = release_pins['qualification_evidence'] == 'Tests/Qualification/Release.Windows.CL.20261025.json'
    if explicit_cl:
        require(ssis + 'InstallPackages/README.md' in payload, 'human package navigation missing')
    expected = {(v,cl,m) for v,levels in (('2019',(150,)),('2022',(150,160)),('2025',(150,160,170)))
                for cl in levels for m in ('local','central')} if explicit_cl else {
                    (v,m) for v in ('2019','2022','2025') for m in ('local','central')}
    actual = {(c['sql_version'],c['compatibility_level'],c['deployment_mode']) if explicit_cl else
              (c['sql_version'],c['deployment_mode']) for c in qualification['cases']}
    require(qualification['result'] == 'PASS' and len(qualification['cases']) == len(expected) and
            qualification['total_native_assertions'] == allowed[release_pins['qualification_evidence']] and
            actual == expected and
            all(c['result'] == 'PASS' for c in qualification['cases']) and
            sha(payload[ssis + 'Artifacts/Toolbelt.Tsql.SsisDebug.dll']).lower() == qualification['qualified_assembly_sha256'] and
            sha(payload[ssis + 'Artifacts/Deploy.WithAssembly.sql']).lower() == qualification['qualified_deploy_sql_sha256'],
            'exact native DLL and deployment qualification')
    require(sha(payload[parser + "Artifacts/Microsoft.SqlServer.TransactSql.ScriptDom.dll"], "sha512") == pins["scriptDomSha512"], "ScriptDom binary")
    for name in [
        "START-HERE.txt", "LICENSE.md", "ThirdParty/ScriptDom-180.117.0/LICENSE",
        "ThirdParty/ScriptDom-180.117.0/NOTICE.txt", "ThirdParty/ScriptDom-180.117.0/package.nuspec",
        "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
        "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
        "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
        parser + "Deployment/Add-TrustedAssembly.sql", ssis + "Deployment/Add-TrustedAssembly.sql",
        ssis + "Examples/Installation/Install-Local.ps1", ssis + "Examples/Installation/PrepareServer.sql",
        ssis + "Examples/Installation/VerifyInstallation.sql", ssis + "Examples/SsmsDebugWalkthrough.sql",
        ssis + "Tests/Fixtures/synthetic-8.dtsx",
    ]:
        require(name in payload and len(payload[name]) > 0, "required installation input")
    print(f"SSIS_INSTALL_PACKAGE_PASS files={len(payload)}; hashes, pins, PE debug directories; no SQL executed")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path)
    main(parser.parse_args().archive)
