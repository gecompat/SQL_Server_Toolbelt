"""Erzeugt den eigentlichen DTSX-Funktionssatz ohne SQLCMD oder Installationsmarker."""
import argparse
import hashlib
import json
from pathlib import Path
import re

MODULE = Path(__file__).resolve().parents[1]
REPO = MODULE.parents[1]
NAMES = {
    "Microsoft.SqlServer.TransactSql.ScriptDom": "tlblt.Microsoft.SqlServer.TransactSql.ScriptDom",
    "tlblt_Tsql_SsisDebug": "tlblt_Tsql_SsisDebug",
}


def sha(data, algorithm="sha256"):
    return hashlib.new(algorithm, data).hexdigest().upper()


def literal(text):
    return "N'" + text.replace("'", "''") + "'"


def definition(source):
    text = source.read_text(encoding="utf-8-sig")
    match = re.search(r"(?m)^CREATE OR ALTER PROCEDURE\b", text)
    if not match:
        raise ValueError("SIMPLE_INSTALL_PROCEDURE_SOURCE_REQUIRED")
    text = re.sub(r"(?im)\nGO\s*\Z", "", text[match.start():]).strip()
    if re.search(r"(?im)^\s*(?:GO\s*$|:\w)", text):
        raise ValueError("SIMPLE_INSTALL_SINGLE_DEFINITION_REQUIRED")
    return text.replace("CREATE OR ALTER PROCEDURE", "CREATE PROCEDURE", 1)


def render(ssis_release, scriptdom, mode="auto"):
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

    header = """USE [ContosoSsisDebug];
/*
DTSX-Debug: schlanker Funktionsinstaller aus dem aktuellen Quellbuild.
Nur USE anpassen und die gesamte Datei in normalem SSMS ausfuehren.
Keine SQLCMD-Direktiven, Extended Properties, Log-/Versionstabellen,
pauschale Rechtepruefung, Rechtevergabe oder automatische Konfigurationsaenderung.
Die Datenbank muss existieren; CLR/Strict Security und benoetigte Engine-
Berechtigungen sind vorhanden. Fehlende Rechte meldet das eigentliche CREATE.

@TrustMethod: auto waehlt bei bereits TRUSTWORTHY ON den Weg trustworthy,
sonst hash. hash prueft Binaries und registriert nur die exakten Hashes;
die Engine verlangt dafuer entsprechende Serverrechte. trustworthy-checked
prueft Hashes ohne Registryeintrag; trustworthy verwendet vorhandenen DB-Trust
ohne Toolbelt-Hashpruefung. Beide trustworthy-Wege setzen bereits ON und
einen entsprechend berechtigten DB-Owner voraus; dieses Skript aktiviert ON
nicht selbst. Kein automatischer Fallback nach einem Fehler.

Vorhandene Objekte werden nicht geloescht/ersetzt. Die geprueften Wege weisen
abweichende vorhandene Assemblybytes ab. trustworthy ist keine Upgradepruefung.
Bei einem Fehler stoppt die Folgeinstallation; zuvor erstellte Objekte und
Hashfreigaben bleiben gegebenenfalls bestehen. Keine Gesamttransaktion.
Enthalten: zwei Assemblies und drei Prozeduren; keine SQL-Parser-TVFs notwendig.

Aufruf danach:
EXEC toolbelt_tsql.USP_ExplainSsisDataFlow @PackageXml=N'<vollstaendiges DTSX>';
Optional @StartValues=N'{"User::SourceFloor":5}'. CatalogMode=package erzeugt
einen als ungeprueft markierten Debugentwurf ohne Quellkatalogzugriff.
CatalogMode=catalog waehlt die strengere Abnahme mit deren Metadatenrechten.
Keine automatische Paket-/SQL-Ausfuehrung. Keine erhoehte Sicherheit aus dem
SQL-Assemblynamenspraefix ableiten; CLR-Koexistenz ist separat nachzuweisen.
*/
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @TrustMethod varchar(24)='@MODE@';
IF @TrustMethod='auto'
    SET @TrustMethod=CASE WHEN (SELECT is_trustworthy_on FROM sys.databases WHERE database_id=DB_ID())=1 THEN 'trustworthy' ELSE 'hash' END;
BEGIN TRY
IF @TrustMethod IN('trustworthy','trustworthy-checked') AND NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND is_trustworthy_on=1)
 THROW 51000,N'Der gewaehlte Trustweg verlangt bereits TRUSTWORTHY ON; es wird nicht aktiviert.',1;
""".replace("@MODE@", mode)
    parts = [header]
    for name in [REPO / "LICENSE.md", MODULE / "InstallPackages/ThirdParty/ScriptDom-180.117.0/LICENSE"]:
        license_text = name.read_text(encoding="utf-8-sig")
        if "*/" in license_text:
            raise ValueError("SIMPLE_INSTALL_LICENSE_COMMENT")
        parts.append("/* Original-Lizenz: " + name.name + "\n" + license_text + "\n*/\n")
    parts.append("IF SCHEMA_ID(N'toolbelt_core') IS NULL EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_core];';\nIF SCHEMA_ID(N'toolbelt_tsql') IS NULL EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_tsql];';\n")
    for sql_name, data in [(NAMES["Microsoft.SqlServer.TransactSql.ScriptDom"], dom), (NAMES["tlblt_Tsql_SsisDebug"], provider)]:
        digest = sha(data, "sha512")
        variable = "@bits" + ("Dom" if data is dom else "Ssis")
        parts.append("DECLARE " + variable + " varbinary(max)=0x" + data.hex().upper() + ";\n")
        parts.append("IF @TrustMethod IN('hash','trustworthy-checked')\nBEGIN\n IF HASHBYTES('SHA2_512'," + variable + ")<>0x" + digest + " THROW 51000,N'Assemblybinary ist abweichend.',1;\n IF EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'" + sql_name + "' AND HASHBYTES('SHA2_512',f.content)<>0x" + digest + ") THROW 51000,N'Vorhandene Assembly ist abweichend; kein automatisches Upgrade.',1;\nEND;\n")
        trust_sql = "IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=0x" + digest + ") EXEC master.sys.sp_add_trusted_assembly @hash=0x" + digest + ",@description=N'Toolbelt " + sql_name + "';"
        parts.append("IF @TrustMethod='hash'\n EXEC sys.sp_executesql " + literal(trust_sql) + ";\n")
        parts.append("IF NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'" + sql_name + "')\nBEGIN\n DECLARE @ddl" + variable[1:] + " nvarchar(max)=N'CREATE ASSEMBLY [" + sql_name + "] FROM '+CONVERT(nvarchar(max)," + variable + ",1)+N' WITH PERMISSION_SET=UNSAFE;';\n EXEC sys.sp_executesql @ddl" + variable[1:] + ";\nEND;\n")
    for schema, name, source in [
        ("toolbelt_core", "USP_PrepareResultTable", REPO / "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"),
        ("toolbelt_tsql", "USP_ExplainSsisDataFlowInternal", MODULE / "Source/USP_ExplainSsisDataFlowInternal.sql"),
        ("toolbelt_tsql", "USP_ExplainSsisDataFlow", MODULE / "Source/USP_ExplainSsisDataFlow.sql"),
    ]:
        sql = definition(source)
        for old, new in NAMES.items():
            sql = sql.replace("[" + old + "]", "[" + new + "]")
        parts.append("IF OBJECT_ID(N'" + schema + "." + name + "') IS NULL\n EXEC sys.sp_executesql " + literal(sql) + ";\n")
    parts.append("END TRY\nBEGIN CATCH\n THROW;\nEND CATCH;\n")
    result = "\n".join(parts)
    if re.search(r"(?im)^\s*(?:GO\s*$|:\w|GRANT\b|REVOKE\b|DENY\b|RECONFIGURE\b|ALTER DATABASE\b)", result) or "extended_properties" in result:
        raise ValueError("SIMPLE_INSTALL_FORBIDDEN_CONTROL")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ssis-release", type=Path, required=True)
    parser.add_argument("--scriptdom", type=Path, required=True)
    parser.add_argument("--trust-mode", choices=["auto", "hash", "trustworthy-checked", "trustworthy"], default="auto")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    text = render(args.ssis_release, args.scriptdom, args.trust_mode)
    if args.output.exists():
        raise ValueError("SIMPLE_INSTALL_OUTPUT_EXISTS")
    args.output.write_text(text, encoding="utf-8-sig", newline="\n")
    print("SSIS_SIMPLE_INSTALL_CREATED no SQL executed")


if __name__ == "__main__":
    main()
