#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.string.regex."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


class ContractError(RuntimeError):
    pass


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise ContractError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def require(content: str, source: str, *markers: str) -> None:
    for marker in markers:
        if marker not in content:
            raise ContractError(f"{source}: Marker fehlt: {marker}")


def forbid(content: str, source: str, *markers: str) -> None:
    lowered = content.lower()
    for marker in markers:
        if marker.lower() in lowered:
            raise ContractError(f"{source}: unzulässiger Marker: {marker}")


def validate_project() -> None:
    project = ET.parse(ROOT / "Clr/Toolbelt.String.Regex.csproj").getroot()
    framework = project.findtext(".//m:TargetFrameworkVersion", namespaces=NS)
    if framework != "v4.8":
        raise ContractError("CLR-Projekt muss .NET Framework 4.8 verwenden.")
    references = {
        item.attrib.get("Include", "").split(",", 1)[0]
        for item in project.findall(".//m:Reference", NS)
    }
    if references != {"System", "System.Data"}:
        raise ContractError(f"Unerwartete direkte Referenzen: {sorted(references)}")


def main() -> int:
    required = (
        "Clr/Toolbelt.String.Regex.csproj",
        "Clr/Properties/AssemblyInfo.cs",
        "Clr/RegexProvider.cs",
        "Clr/RegexTransformations.cs",
        "Clr/RegexRelations.cs",
        "Clr/RegexCaptures.cs",
        "Source/RegexCaptures.sql",
        "Documentation/TVF_RegexCaptures.md",
        "Documentation/SVF_RegexReplaceGroups.md",
        "Tests/Runtime/Captures.Contract.sql",
        "Tests/Runtime/Captures.Metadata.ps1",
        "Tests/Runtime/Captures.Central.sql",
        "Tests/Runtime/Lifecycle.Snapshot.sql",
        "Tests/Runtime/Lifecycle.CollisionFixture.sql",
        "Source/RegexRelations.sql",
        "Documentation/TVF_RegexMatches.md",
        "Documentation/TVF_RegexSplit.md",
        "Tests/Runtime/Relations.Contract.sql",
        "Tests/Runtime/run-framework-relations.ps1",
        "Tests/Runtime/Relations.Metadata.ps1",
        "Tests/Runtime/Relations.Rights.sql",
        "Source/RegexFunctions.sql",
        "Deployment/Add-TrustedAssembly.sql",
        "Deployment/Deploy.sql",
        "Deployment/Uninstall.sql",
        "Scripts/New-ClrReleaseArtifacts.ps1",
        "Documentation/REGEX_FUNCTIONS.md",
        "Documentation/SVF_RegexReplace.md",
        "Documentation/SVF_RegexSubstring.md",
        "Examples/Regex.sql",
        "Tests/Runtime/Regex.Contract.sql",
        "Tests/Runtime/Transformations.Contract.sql",
        "Tests/Runtime/Lifecycle.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Tests/REGEX_CONTRACT_TEST_MATRIX.md",
        "Tests/README.md",
        "README.md",
        "module.yaml",
    )
    for relative in required:
        read(relative)
    validate_project()

    provider = read("Clr/RegexProvider.cs")
    require(
        provider,
        "CLR-Provider",
        "TimeSpan.FromMilliseconds(250)",
        "MaxInputCodeUnits = 1048576",
        "MaxPatternBytes = 8000",
        "MaxQuantifier = 1000",
        "TranslatePattern",
        "AppendCharacterClass",
        "AppendBoundedQuantifier",
        '"[0-9]"',
        '"[A-Za-z0-9_]"',
        '"\\\\p{L}"',
        "RegexOptions.CultureInvariant",
        "RegexMatchTimeoutException",
        "TBX_REGEX_INVALID_PATTERN",
        "TBX_REGEX_TIMEOUT",
    )
    forbid(
        provider,
        "CLR-Provider",
        "System.IO.",
        "System.Net.",
        "System.Diagnostics.Process",
        "Microsoft.Win32.Registry",
        "RegexOptions.Compiled",
        "DllImport",
    )

    source = read("Source/RegexFunctions.sql")
    require(
        source,
        "SQL-Funktionen",
        "SVF_RegexIsMatch",
        "SVF_RegexInstr",
        "SVF_RegexCount",
        "CALLED ON NULL INPUT",
        "[Toolbelt_String_Regex]",
        "[Toolbelt.String.Regex.RegexProvider]",
        "@Pattern nvarchar(max)",
        "@Flags   nvarchar(4) = N'c'",
    )

    deploy = read("Deployment/Deploy.sql")
    if deploy.count("$(AssemblyBits)") != 1:
        raise ContractError("Deploy.sql benötigt genau einen AssemblyBits-Platzhalter.")
    require(
        deploy,
        "Deployment",
        "HASHBYTES(N'SHA2_512', @AssemblyBits)",
        "sys.trusted_assemblies",
        "WITH PERMISSION_SET = SAFE",
        ":r ../Source/RegexFunctions.sql",
        "sp_getapplock",
        "Toolbelt.ModuleVersion",
    )
    forbid(deploy, "Deployment", "sp_configure", "TRUSTWORTHY ON", "UNSAFE", "EXTERNAL_ACCESS")

    trust = read("Deployment/Add-TrustedAssembly.sql")
    require(trust, "Trust", "sys.sp_add_trusted_assembly", "SHA2-512", "clr strict security")
    forbid(trust, "Trust", "sp_configure", "TRUSTWORTHY ON")

    uninstall = read("Deployment/Uninstall.sql")
    require(uninstall, "Uninstall", "DROP FUNCTION", "DROP ASSEMBLY", "ConfirmNoExternalConsumers")
    forbid(uninstall, "Uninstall", "sp_drop_trusted_assembly")
    forbid(read("Tests/Runtime/Lifecycle.Snapshot.sql"), "Optionsneutraler Snapshot",
           "SET NOCOUNT", "SET XACT_ABORT", "BEGIN TRAN", "COMMIT", "ROLLBACK")
    for label, lifecycle in (("Deploy", deploy), ("Uninstall", uninstall)):
        require(lifecycle, label + " exakte Binarybindung",
                "$(ExpectedInstalledAssemblyHash)", "DATALENGTH(@ExpectedInstalledAssemblyHashText) <> 260",
                "Latin1_General_100_BIN2 LIKE N'%[^0-9A-Fa-f]%'",
                "TRY_CONVERT(varbinary(max), @ExpectedInstalledAssemblyHashText, 1) IS NULL",
                "HASHBYTES(N'SHA2_512', f.content)", "f.file_id = 1", "THROW 52046", "THROW 52047",
                "@InstalledAssemblyHash <> @ExpectedInstalledAssemblyHash", "@ExpectedAbsence = 1")
        forbid(lifecycle, label + " keine Versionsinferenz", "LOWER(a.clr_name)", "@InstalledVersion + N'.0,'")
        comparison = lifecycle.index("@InstalledAssemblyHash <> @ExpectedInstalledAssemblyHash")
        if not lifecycle.index("WHILE @Pass <= 2") < comparison < lifecycle.index("SET @Pass += 1;"):
            raise ContractError(label + ": Hashprüfung fehlt im wiederholten Preflight.")
        if comparison > lifecycle.index("DROP FUNCTION"):
            raise ContractError(label + ": Hashprüfung muss vor destruktiver DDL liegen.")

    build = read("Scripts/New-ClrReleaseArtifacts.ps1")
    require(build, "Build", "Get-FileHash -Algorithm SHA512", "Deploy.WithAssembly.sql", "Toolbelt.String.Regex.trust-manifest.json", "@('System', 'System.Data')")

    manifest = read("module.yaml")
    require(manifest, "Manifest", 'version: "1.3.0"', 'permission_set: "SAFE"', "third_party_dependencies: []", 'workflow: "local: Tests/CI/run-lab-local.ps1"')

    relations = read("Clr/RegexRelations.cs")
    require(relations, "R2b-Kern", "TransformationContext", "context.Search", "maxRows.Value > 100000",
            "TBX_REGEX_TOO_MANY_ROWS", "TBX_REGEX_OUTPUT_TOO_LARGE", "tokenStart = match.Index + match.Length",
            "FillRelationRow", "return rows;", "DataAccessKind.None", "SystemDataAccessKind.None")
    forbid(relations, "R2b-Kern", "yield return", "new Regex(", "TranslatePattern(", "System.IO.", "System.Net.", "SqlConnection")
    relation_source = read("Source/RegexRelations.sql")
    require(relation_source, "R2b-Fassade", "TVF_RegexMatchesCore", "TVF_RegexSplitCore", "RETURNS TABLE\nAS RETURN",
            "@MaxRows int = 10000", "COLLATE DATABASE_DEFAULT")
    require(read("Tests/Runtime/Relations.Contract.sql"), "R2b-Oracles", "TBX_REGEX_TOO_MANY_ROWS", "ERROR_NUMBER()<>6522",
            "8388608", "100000", "DATALENGTH(Value)=0", "Zero separator lost input")
    require(deploy, "R2b-Lifecycle", ":r ../Source/RegexRelations.sql", "N'1.2.0'", "TVF_RegexMatchesCore", "TVF_RegexSplitCore")
    require(uninstall, "Versionsgebundener Uninstall", "@Release >= 12", "TVF_RegexMatchesCore", "TVF_RegexSplitCore")
    for label, lifecycle in (("Deploy", deploy), ("Uninstall", uninstall)):
        require(lifecycle, label, "@@TRANCOUNT", "RAISERROR", "RETURN", "@Pass", "sp_getapplock",
                "toolbelt.deploy.toolbelt.string.regex", "Toolbelt.Managed", "Toolbelt.ModuleId", "Toolbelt.ModuleVersion",
                "N'1.3.0'", "TVF_RegexCaptures", "SVF_RegexReplaceGroups")
        if lifecycle.index("@@TRANCOUNT") > lifecycle.index("SET XACT_ABORT"):
            raise ContractError(f"{label}: Caller-Transaktion muss vor Sessionoptionen geprüft werden.")
    captures = read("Clr/RegexCaptures.cs")
    require(captures, "Capture-Kern", "TransformationContext", "RegexCaptures", "RegexReplaceGroups",
            "TBX_REGEX_INVALID_REPLACEMENT", "TBX_REGEX_TOO_MANY_ROWS", "TBX_REGEX_OUTPUT_TOO_LARGE")
    forbid(captures, "Capture-Kern", "yield return", "new Regex(", "System.IO.", "System.Net.", "SqlConnection")
    require(provider, "Gemeinsamer Captureparser", "TranslatePattern")
    require(captures, "Capture-Historiengate", "TBX_REGEX_CAPTURE_HISTORY_LIMIT")
    require(read("Source/RegexCaptures.sql"), "Capture-Fassaden", "TVF_RegexCapturesCore", "SVF_RegexReplaceGroupsCore",
            "@MaxRows int = 10000", "COLLATE DATABASE_DEFAULT", "@Occurrence int = 0")

    transforms = read("Clr/RegexTransformations.cs")
    require(transforms, "R2a", "RegexReplace", "RegexSubstring", "R2PatternCodeUnits = 8000",
            "8388608", "500 : 2000", "Stopwatch.StartNew()", "Math.Min(250, Remaining())",
            "TBX_REGEX_OUTPUT_TOO_LARGE", "TBX_REGEX_PATTERN_TOO_COMPLEX", "context.Append",
            "regex.Match(input, cursor)", "regexTimeout > Remaining()", "Remaining() / 2")
    require(source, "R2a-Signaturen", "SVF_RegexReplace", "SVF_RegexSubstring",
            "@Profile nvarchar(max) = N'standard'", "@Flags nvarchar(max) = N'c'")
    require(read("Tests/Runtime/Transformations.Contract.sql"), "R2a-Runtime",
            "8388609", "8001", "TBX_REGEX_OUTPUT_TOO_LARGE", "TBX_REGEX_TIMEOUT", "N'$1\\x'")

    runtime = read("Tests/Runtime/Regex.Contract.sql")
    require(runtime, "Runtime", "TBX_REGEX_INVALID_PATTERN", "TBX_REGEX_TIMEOUT", "1048577", "4001", "N'^(a|aa)+$'")

    # Runner-Cleanup und vorhandenen Lab-No-op getrennt halten; produktive
    # Regex-/Trustverträge werden durch diese Adapterprüfung nicht qualifiziert.
    repo = ROOT.parents[1]
    ci = (repo / "Tests/CI/run-regex-linux.sh").read_text(encoding="utf-8-sig")
    require(ci, "CI-Ownership", "REGEX_CI_IDENTITY_INVALID", "REGEX_CI_OWNER_INVALID",
            "^tbx-regex-(2019|2022|2025)-(150|160|170)-[0-9]+-[0-9]+$",
            'container_options=(--label "tbx.regex.ci.owner=${container_owner}")',
            '"${container_options[@]}"')
    begin = ci.index("cleanup() {\n")
    end = ci.index("\n}\n", begin) + 2
    cleanup = ci[begin:end]
    require(cleanup, "CI-Cleanup", "local result=$?", "trap - EXIT",
            'if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then',
            "{{.Id}} {{ index .Config.Labels \"tbx.regex.ci.owner\" }}",
            '^([0-9a-f]{64})\\ ([0-9a-f]{32})$', 'docker rm -f "${container_id}"',
            'rm -rf -- "${private_dir}"', "REGEX_CI_CLEANUP_UNVERIFIED",
            "REGEX_CI_CLEANUP_VERIFIED", 'exit "${result}"')
    runner_cleanup = cleanup.split("  # Runnerzustand", 1)[1]
    forbid(runner_cleanup, "Runner-Cleanup", 'docker rm -f "${container_name}"', "run_query", "|| true")
    if runner_cleanup.count('docker container ls --all --filter "name=^/${container_name}$"') != 2:
        raise ContractError("Runner-Cleanup braucht initiale und frische abschließende Namensprüfung.")
    if not ci.index('echo "::add-mask::${sa_password}"') < ci.index('private_dir="$(mktemp -d)"') < begin < ci.index("trap cleanup EXIT") < ci.index("docker run --detach"):
        raise ContractError("Runner-Setup-/Trap-Reihenfolge ist nicht sicher gekoppelt.")
    mock = (repo / "Tests/CI/test_owned_container_cleanup.py").read_text(encoding="utf-8-sig")
    require(mock, "CI-Offlinekopplung", '"regex": ("run-regex-linux.sh", "REGEX_CI_CLEANUP_UNVERIFIED", "tbx.regex.ci.owner")')
    doc_workflow = (repo / ".github/workflows/documentation-consistency.yml").read_text(encoding="utf-8-sig")
    require(doc_workflow, "CI-Offlinegate", "Tests/CI/run-regex-linux.sh", "python3 Tests/CI/test_owned_container_cleanup.py")
    print("Regex statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"Regex statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
