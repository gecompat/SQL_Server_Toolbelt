#!/usr/bin/env python3
"""Manuell gestartete, begrenzte Pointer-Lastprobe auf eigenem SQL-Container."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys
import tempfile
import time


SIZES = (65536, 1048576, 4194304, 16777216)
VERSIONS = {"2019": 150, "2022": 160, "2025": 170}
DEPTHS = (1, 2, 4, 8, 16, 32, 64, 128)
WORK_SECONDS = 240
CLEANUP_SECONDS = 60


class ProbeError(Exception):
    pass


class ProbeTimeout(ProbeError):
    pass


def invoke(args: list[str], deadline: float, cap: float) -> subprocess.CompletedProcess[str]:
    # Prozessausgaben bleiben privat; SQL-Fehler und Kennwörter erscheinen nie im CI-Log.
    remaining = min(cap, deadline - time.monotonic())
    if remaining <= 0:
        raise ProbeTimeout("Zeitbudget erschöpft")
    try:
        return subprocess.run(
            args, text=True, errors="replace", capture_output=True,
            timeout=remaining, check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise ProbeTimeout("Prozesswatchdog ausgelöst") from error


def checked(args: list[str], deadline: float, cap: float, label: str) -> str:
    result = invoke(args, deadline, cap)
    if result.returncode != 0:
        raise ProbeError(f"{label} fehlgeschlagen")
    return result.stdout


def sql_args(cid: str, sqlcmd: str, password: str, database: str, statement: str) -> list[str]:
    return [
        "docker", "exec", cid, sqlcmd, "-S", "localhost", "-U", "sa",
        "-P", password, "-C", "-b", "-l", "10", "-t", "180",
        "-d", database, "-h", "-1", "-W", "-Q", statement,
    ]


def oracle_query(stage_bytes: int, shape: str, depth: int) -> str:
    units = stage_bytes // 2
    if shape == "root":
        overhead, document, pointer = 2, "N'\"' + @Payload + N'\"'", "N''"
    elif shape == "object":
        overhead = 8
        document, pointer = "N'{\"k\":\"' + @Payload + N'\"}'", "N'/k'"
    elif shape == "array":
        # ["..."] hat genau vier strukturelle UTF-16-Einheiten; /0 wählt den Wert.
        overhead, document, pointer = 4, "N'[\"' + @Payload + N'\"]'", "N'/0'"
    else:
        overhead = 6 * depth + 2
        document = (f"REPLICATE(CONVERT(nvarchar(max),N'{{\"k\":'),{depth})"
                    f" + N'\"' + @Payload + N'\"'"
                    f" + REPLICATE(CONVERT(nvarchar(max),N'}}'),{depth})")
        pointer = f"REPLICATE(CONVERT(nvarchar(max),N'/k'),{depth})"
    return f"""
SET NOCOUNT ON;
DECLARE @Payload nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),{units - overhead});
DECLARE @Json nvarchar(max)={document};
IF DATALENGTH(@Json)<>{stage_bytes} THROW 55592,N'Synthetic input length',1;
DECLARE @Rows int=0,@Status varchar(16)=NULL,@Type varchar(8)=NULL,
        @Value nvarchar(max)=NULL,@ErrorCode varchar(32)=NULL;
SELECT @Rows=@Rows+1,@Status=Status,@Type=JsonType,@Value=Value,@ErrorCode=ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(@Json,{pointer},DEFAULT,DEFAULT);
-- Der Eingabe-Payload ist das erwartete Wertorakel; eine zweite Kopie
-- würde bei Maximalgröße nur zusätzliche Testressourcen verbrauchen.
IF @Rows<>1 OR ISNULL(@Status,'')<>'FOUND' OR ISNULL(@Type,'')<>'STRING'
 OR @ErrorCode IS NOT NULL OR @Value IS NULL
 OR DATALENGTH(@Value)<>DATALENGTH(@Payload)
 OR HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Value))
    <>HASHBYTES('SHA2_256',CONVERT(varbinary(max),@Payload))
 THROW 55592,N'Pointer synthetic oracle mismatch',2;
SELECT N'ORACLE_PASS';
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sql-version", choices=VERSIONS, required=True)
    parser.add_argument("--stage-bytes", type=int, choices=SIZES, required=True)
    parser.add_argument("--shape", choices=("root", "object", "array", "nested"), required=True)
    parser.add_argument("--depth", type=int, choices=DEPTHS, default=1)
    options = parser.parse_args()
    if options.shape != "nested" and options.depth != 1:
        parser.error("Tiefe ist nur bei nested verwendbar")
    if os.environ.get("TBX_SQL_TARGET", "runner") != "runner":
        parser.error("Nur eigene flüchtige Runner-Container sind zulässig")

    root = Path(__file__).resolve().parents[4]
    deployment = root / "Modules/toolbelt.json.pointer/Deployment/Deploy.sql"
    if not deployment.is_file() or shutil.which("docker") is None:
        raise ProbeError("Deployment oder Docker fehlt")

    started = time.monotonic()
    work_deadline = started + WORK_SECONDS
    owner = secrets.token_hex(12)
    name = f"tbx-pointer-max-{owner}"
    password = f"Tbx!{secrets.token_hex(16)}Aa1"
    private = Path(tempfile.mkdtemp(prefix="tbx-pointer-max-"))
    cid_file = private / "cid"
    result = "FAILED"
    detail = ""
    cleanup_ok = True
    try:
        image = f"mcr.microsoft.com/mssql/server:{options.sql_version}-latest"
        container_args = [
            "docker", "run", "--detach", "--cidfile", str(cid_file),
            "--name", name, "--label", f"tbx.pointer.max.owner={owner}",
            "--env", "ACCEPT_EULA=Y",
            "--env", "MSSQL_PID=Developer", "--env", f"MSSQL_SA_PASSWORD={password}",
            # Einheitliche Testobergrenze für alle Formen; kein gemessener Heapwert.
            "--memory", "3g", "--memory-swap", "3g",
            "--volume", f"{deployment.parent}:/workspace/Deployment:ro",
        ]
        container_args.append(image)
        checked(container_args, work_deadline, 90, "Containerstart")
        cid = cid_file.read_text(encoding="ascii").strip()
        if len(cid) != 64 or any(c not in "0123456789abcdef" for c in cid):
            raise ProbeError("Containeridentität fehlt")
        sqlcmd = ""
        for candidate in ("/opt/mssql-tools18/bin/sqlcmd", "/opt/mssql-tools/bin/sqlcmd"):
            probe = invoke(["docker", "exec", cid, "test", "-x", candidate], work_deadline, 10)
            if probe.returncode == 0:
                sqlcmd = candidate
                break
        if not sqlcmd:
            raise ProbeError("SQL-Client fehlt")

        ready_deadline = min(work_deadline, time.monotonic() + 120)
        while time.monotonic() < ready_deadline:
            try:
                probe = invoke(sql_args(cid, sqlcmd, password, "master", "SELECT 1;"), ready_deadline, 10)
            except ProbeTimeout:
                probe = None
            if probe is not None and probe.returncode == 0:
                break
            time.sleep(min(2, max(0, ready_deadline - time.monotonic())))
        else:
            raise ProbeTimeout("SQL-Bereitschaft nicht erreicht")

        checked(sql_args(cid, sqlcmd, password, "master", "CREATE DATABASE tbx_json_pointer_max;"),
                work_deadline, 30, "Testdatenbank")
        level = VERSIONS[options.sql_version]
        checked(sql_args(cid, sqlcmd, password, "master",
                         f"ALTER DATABASE tbx_json_pointer_max SET COMPATIBILITY_LEVEL={level};"),
                work_deadline, 30, "Kompatibilitätsstufe")
        deploy_args = [
            "docker", "exec", "--workdir", "/workspace/Deployment",
            cid, sqlcmd, "-S", "localhost", "-U", "sa", "-P", password,
            "-C", "-b", "-l", "10", "-t", "180", "-d", "tbx_json_pointer_max",
            "-i", "Deploy.sql", "-v", "DeploymentMode=local",
        ]
        checked(deploy_args, work_deadline, 120, "Pointer-Deployment")
        output = checked(sql_args(cid, sqlcmd, password, "tbx_json_pointer_max",
                                  oracle_query(options.stage_bytes, options.shape, options.depth)),
                         work_deadline, 180, "Lastorakel")
        if output.strip() != "ORACLE_PASS":
            raise ProbeError("Lastorakel ohne exakten Erfolgsmarker")
        result = "PASS"
    except ProbeTimeout as error:
        result, detail = "INCONCLUSIVE", str(error)
    except (ProbeError, OSError, UnicodeError) as error:
        result, detail = "FAILED", str(error)
    finally:
        # Nur den eindeutig eigenen Container entfernen; fremde Namen/CIDs bleiben unangetastet.
        cleanup_deadline = min(started + WORK_SECONDS + CLEANUP_SECONDS,
                               time.monotonic() + CLEANUP_SECONDS)
        try:
            identity = invoke([
                "docker", "container", "inspect", "--format",
                "{{index .Config.Labels \"tbx.pointer.max.owner\"}}", name,
            ], cleanup_deadline, 10)
            if identity.returncode == 0:
                if identity.stdout.strip() != owner:
                    cleanup_ok = False
                else:
                    checked(["docker", "rm", "-f", name], cleanup_deadline, 45, "Container-Cleanup")
            if cleanup_ok:
                # Ein erfolgreiches Listing belegt Abwesenheit; ein fehlgeschlagenes
                # inspect könnte auch nur einen unerreichbaren Docker-Daemon bedeuten.
                listing = checked([
                    "docker", "container", "ls", "--all", "--filter", f"name=^{name}$",
                    "--format", "{{.ID}}",
                ], cleanup_deadline, 10, "Cleanup-Audit")
                cleanup_ok = not listing.strip()
        except (ProbeError, ProbeTimeout, OSError):
            cleanup_ok = False
        shutil.rmtree(private, ignore_errors=True)

    if not cleanup_ok:
        print("INCONCLUSIVE: owned-container cleanup unconfirmed", file=sys.stderr)
        return 3
    if result != "PASS":
        print(f"{result}: {detail}", file=sys.stderr)
        return 2 if result == "INCONCLUSIVE" else 1
    print(f"PASS: JSON Pointer {options.sql_version} Linux; {options.shape}; depth {options.depth}; {options.stage_bytes} synthetic input bytes")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ProbeError as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
