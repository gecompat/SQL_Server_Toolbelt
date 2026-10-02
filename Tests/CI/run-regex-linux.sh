#!/usr/bin/env bash
set -euo pipefail

sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
compatibility_level="${TBX_COMPATIBILITY_LEVEL:?TBX_COMPATIBILITY_LEVEL fehlt}"
assembly_root_input="${TBX_ASSEMBLY_ROOT:?TBX_ASSEMBLY_ROOT fehlt}"

case "${compatibility_level}" in 150|160|170) ;; *) exit 64 ;; esac

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
assembly_root_host="$(realpath "${assembly_root_input}")"
assembly_relative="$(realpath --relative-to="${workspace}" "${assembly_root_host}")"
case "${assembly_relative}" in ../*|..) echo "Assembly-Artefakte müssen im Workspace liegen." >&2; exit 1 ;; esac

assembly_root_container="/workspace/${assembly_relative}"
assembly_file_host="${assembly_root_host}/Toolbelt.String.Regex.dll"
manifest_file_host="${assembly_root_host}/Toolbelt.String.Regex.trust-manifest.json"
deploy_file_host="${assembly_root_host}/Deploy.WithAssembly.sql"
for required_file in "${assembly_file_host}" "${manifest_file_host}" "${deploy_file_host}"; do
  [[ -f "${required_file}" ]] || { echo "Regex-Releaseartefakt fehlt." >&2; exit 1; }
done

python3 - "${assembly_file_host}" "${manifest_file_host}" "${deploy_file_host}" <<'PY'
from hashlib import sha512
import json
from pathlib import Path
import sys

assembly_path, manifest_path, deploy_path = map(Path, sys.argv[1:])
assembly = assembly_path.read_bytes()
manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
deploy = deploy_path.read_text(encoding="utf-8-sig")
actual_hash = sha512(assembly).hexdigest().upper()
assert actual_hash == manifest["sha512"]
assert manifest["sqlServerHexLiteral"] == "0x" + actual_hash
assert manifest["moduleId"] == "toolbelt.string.regex"
assert manifest["moduleVersion"] == "1.3.0"
assert manifest["assemblySqlName"] == "Toolbelt_String_Regex"
assert manifest["permissionSet"] == "SAFE"
assert manifest["directFrameworkReferences"] == ["System", "System.Data"]
assert deploy.count("0x" + assembly.hex().upper()) == 1
assert "$(AssemblyBits)" not in deploy
PY

readarray -t manifest_values < <(python3 - "${manifest_file_host}" <<'PY'
import json
from pathlib import Path
import sys
manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
print(manifest["sqlServerHexLiteral"])
print(manifest["description"])
PY
)
assembly_hash="${manifest_values[0]}"
assembly_description="${manifest_values[1]}"

container_name="tbx-regex-${sql_version}-${compatibility_level}-${GITHUB_RUN_ID:-local}"
collision_log=""
r2a_hash=""
r2a_trust_before=""
sa_password="Tbx!$(openssl rand -hex 20)Aa1"
echo "::add-mask::${sa_password}"
cleanup() {
  # Nur der genaue zusätzliche Vorgängerhash und nur bei eigener Registrierung.
  if [[ "${r2a_trust_before}" == "0" && -n "${r2a_hash}" ]]; then
    run_query master "IF EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=CONVERT(varbinary(64),N'${r2a_hash}',1)) EXEC sys.sp_drop_trusted_assembly @hash=CONVERT(varbinary(64),N'${r2a_hash}',1);" >/dev/null 2>&1 || true
  fi
  docker rm -f "${container_name}" >/dev/null 2>&1 || true
  [[ -z "${collision_log}" ]] || rm -f "${collision_log}"
}
trap cleanup EXIT

docker run --detach --name "${container_name}" \
  --env ACCEPT_EULA=Y --env MSSQL_PID=Developer \
  --env MSSQL_SA_PASSWORD="${sa_password}" \
  --volume "${workspace}:/workspace:ro" "${sql_image}" >/dev/null

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
  if docker exec "${container_name}" test -x "${candidate}"; then sqlcmd_path="${candidate}"; break; fi
done
[[ -n "${sqlcmd_path}" ]] || { echo "sqlcmd fehlt." >&2; exit 1; }
for attempt in $(seq 1 60); do
  if docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -Q "SELECT 1;" >/dev/null 2>&1; then break; fi
  [[ "${attempt}" -eq 60 ]] && { echo "SQL Server nicht bereit." >&2; exit 1; }
  sleep 2
done

run_file() {
  local database="$1" workdir="$2" file="$3"; shift 3
  if [[ "${file}" == "Lifecycle.Contract.sql" ]]; then set -- "$@" -v "ExpectedInstalledAssemblyHash=${assembly_hash}"; fi
  docker exec --workdir "${workdir}" "${container_name}" "${sqlcmd_path}" \
    -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" -i "${file}" "$@"
}
run_query() {
  local database="$1" query="$2"; shift 2
  docker exec "${container_name}" "${sqlcmd_path}" -S localhost -U sa -P "${sa_password}" -C -b -d "${database}" "$@" -Q "${query}"
}
deploy_regex() {
  run_file "$1" /workspace/Modules/toolbelt.string.regex/Deployment \
    "${assembly_root_container}/Deploy.WithAssembly.sql" -v "DeploymentMode=$2" "ExpectedInstalledAssemblyHash=${3:?Expliziter installierter Hash fehlt}"
}

run_query master "EXEC sys.sp_configure N'clr enabled', 1; RECONFIGURE;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 52090,N'clr strict security muss aktiviert bleiben.',1;"
run_file master /workspace/Modules/toolbelt.string.regex/Deployment Add-TrustedAssembly.sql \
  -v "AssemblyHash=${assembly_hash}" "AssemblyDescription=${assembly_description}"

local_database="tbx_regex"
central_database="tbx_regex_central"
consumer_database="tbx_regex_consumer"
collision_database="tbx_regex_collision"
run_query master "CREATE DATABASE [${local_database}] COLLATE Latin1_General_100_CS_AS;
CREATE DATABASE [${central_database}] COLLATE Latin1_General_100_BIN2;
CREATE DATABASE [${consumer_database}] COLLATE Latin1_General_100_CI_AS;
CREATE DATABASE [${collision_database}] COLLATE Latin1_General_100_CI_AS;"

deploy_regex "${local_database}" local 0x
run_query "${local_database}" "ALTER DATABASE [${local_database}] SET COMPATIBILITY_LEVEL=${compatibility_level};"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Regex.Contract.sql
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Transformations.Contract.sql
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Relations.Contract.sql -v "ToolbeltDatabase=${local_database}"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Captures.Contract.sql -v "ToolbeltDatabase=${local_database}"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Relations.Rights.sql
deploy_regex "${local_database}" local "${assembly_hash}"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql

deploy_regex "${central_database}" central 0x
run_file "${central_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Relations.Rights.sql
run_file "${consumer_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Central.Contract.sql \
  -v "ToolbeltDatabase=${central_database}"
run_file "${consumer_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Relations.Contract.sql -v "ToolbeltDatabase=${central_database}"
run_file "${consumer_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Captures.Central.sql -v "ToolbeltDatabase=${central_database}"
if [[ "${TBX_SQL_TARGET:-}" == "lab" ]]; then
  metadata_script="${workspace}/Modules/toolbelt.string.regex/Tests/Runtime/Relations.Metadata.ps1"
  if command -v cygpath >/dev/null 2>&1; then metadata_script="$(cygpath -w "${metadata_script}")"; fi
  pwsh -NoProfile -File "${metadata_script}" -Database "${local_database}_${TBX_TEST_DB_SUFFIX}"
  pwsh -NoProfile -File "${metadata_script}" -Database "${consumer_database}_${TBX_TEST_DB_SUFFIX}" -ToolbeltDatabase "${central_database}_${TBX_TEST_DB_SUFFIX}"
fi

# Echter 1.1-Vorgänger neben unveränderter 1.0-Fixture; kein Markerfake.
r2a_container="${assembly_root_container}/legacy-r2a"
r2a_hash="$(python3 - "${assembly_root_host}/legacy-r2a/Toolbelt.String.Regex.trust-manifest.json" "${assembly_root_host}/legacy-r2a/Toolbelt.String.Regex.dll" <<'PY'
import json,sys,hashlib
from pathlib import Path
m=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
assert m['moduleVersion']=='1.1.0' and m['sha512']==hashlib.sha512(Path(sys.argv[2]).read_bytes()).hexdigest().upper()
assert m['sqlServerHexLiteral']=='0x'+m['sha512']
print(m['sqlServerHexLiteral'])
PY
)"
r2a_trust_before="$(run_query master "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash=CONVERT(varbinary(64),N'${r2a_hash}',1);" -h -1 -W | tr -d '[:space:]')"
[[ "${r2a_trust_before}" == "0" || "${r2a_trust_before}" == "1" ]] || { echo "R2a-Testtrust-Voraussetzung unklar." >&2; exit 1; }
run_file master /workspace/Modules/toolbelt.string.regex/Deployment Add-TrustedAssembly.sql -v "AssemblyHash=${r2a_hash}" "AssemblyDescription=Toolbelt Regex R2a upgrade test"
r2b_upgrade_database="tbx_regex_r2b_upgrade"
run_query master "CREATE DATABASE [${r2b_upgrade_database}] COLLATE Latin1_General_100_CI_AS;"
run_file "${r2b_upgrade_database}" "${r2a_container}" "${r2a_container}/Deploy.WithAssembly.sql" -v DeploymentMode=local
for relation_name in TVF_RegexMatches TVF_RegexSplit TVF_RegexMatchesCore TVF_RegexSplitCore; do
  run_query "${r2b_upgrade_database}" "EXEC(N'CREATE FUNCTION toolbelt_string.${relation_name}() RETURNS TABLE AS RETURN SELECT CONVERT(int,7) AS ForeignValue;'); EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.string.regex',@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'FUNCTION',@level1name=N'${relation_name}';"
  collision_log="$(mktemp)"
  set +e
  deploy_regex "${r2b_upgrade_database}" local "${r2a_hash}" >"${collision_log}" 2>&1
  relation_collision_status=$?
  set -e
  [[ "${relation_collision_status}" -ne 0 ]] && grep -q "Msg 52033" "${collision_log}" || { echo "R2b-Kollision nicht geschützt." >&2; exit 1; }
  run_query "${r2b_upgrade_database}" "IF NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_String_Regex' AND HASHBYTES('SHA2_512',f.content)=CONVERT(varbinary(64),N'${r2a_hash}',1)) THROW 52095,N'R2b-Kollision mutierte Originalassembly.',6;"
  run_file "${r2b_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${r2a_hash}"
  run_query "${r2b_upgrade_database}" "IF OBJECT_ID(N'toolbelt_string.${relation_name}',N'IF') IS NULL THROW 52095,N'Vorgänger-Uninstall löschte fremde TVF.',7; DROP FUNCTION toolbelt_string.${relation_name};"
  rm -f "${collision_log}";collision_log=""
  run_file "${r2b_upgrade_database}" "${r2a_container}" "${r2a_container}/Deploy.WithAssembly.sql" -v DeploymentMode=local
done
deploy_regex "${r2b_upgrade_database}" local "${r2a_hash}"
run_file "${r2b_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql
run_file "${r2b_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Relations.Contract.sql -v "ToolbeltDatabase=${r2b_upgrade_database}"
run_query "${r2b_upgrade_database}" "EXEC(N'CREATE VIEW dbo.RegexRelationDependency AS SELECT * FROM toolbelt_string.TVF_RegexMatches(N''x'',N''x'',DEFAULT,DEFAULT,DEFAULT,DEFAULT);');"
collision_log="$(mktemp)"
set +e
run_file "${r2b_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}" >"${collision_log}" 2>&1
relation_dependency_status=$?
set -e
[[ "${relation_dependency_status}" -ne 0 ]] && grep -q "Msg 52038" "${collision_log}" || { echo "R2b-Dependency-Uninstall nicht geschützt." >&2; exit 1; }
run_query "${r2b_upgrade_database}" "IF OBJECT_ID(N'toolbelt_string.TVF_RegexMatches',N'IF') IS NULL THROW 52095,N'Dependency-Schutz mutierte R2b.',8; DROP VIEW dbo.RegexRelationDependency;"
rm -f "${collision_log}";collision_log=""
run_file "${r2b_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}"

# Gepinnte echte 1.2-Assembly: neue Captureplätze sind vor Upgrade fremd.
r2b_container="${assembly_root_container}/legacy-r2b"
r2b_hash="$(python3 - "${assembly_root_host}/legacy-r2b/Toolbelt.String.Regex.trust-manifest.json" "${assembly_root_host}/legacy-r2b/Toolbelt.String.Regex.dll" <<'PY'
import json,sys,hashlib
from pathlib import Path
m=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
assert m['moduleVersion']=='1.2.0' and m['sha512']==hashlib.sha512(Path(sys.argv[2]).read_bytes()).hexdigest().upper()
assert m['sqlServerHexLiteral']=='0x'+m['sha512']
print(m['sqlServerHexLiteral'])
PY
)"
run_file master /workspace/Modules/toolbelt.string.regex/Deployment Add-TrustedAssembly.sql -v "AssemblyHash=${r2b_hash}" "AssemblyDescription=Toolbelt Regex Capture upgrade test"
capture_upgrade_database="tbx_regex_capture_upgrade"
run_query master "CREATE DATABASE [${capture_upgrade_database}] COLLATE Latin1_General_100_CS_AS;"
run_file "${capture_upgrade_database}" "${r2b_container}" "${r2b_container}/Deploy.WithAssembly.sql" -v DeploymentMode=local
run_file "${capture_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.CollisionFixture.sql -v FaultCase=ImitatedNewSlot
collision_log="$(mktemp)"
set +e
deploy_regex "${capture_upgrade_database}" local "${r2b_hash}" >"${collision_log}" 2>&1
capture_collision_status=$?
set -e
[[ "${capture_collision_status}" -ne 0 ]] && grep -q "Msg 52033" "${collision_log}" || { echo "Capture-Upgrade-Kollision nicht geschützt." >&2; exit 1; }
run_file "${capture_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${r2b_hash}"
run_query "${capture_upgrade_database}" "IF toolbelt_string.SVF_RegexReplaceGroups()<>73 THROW 52095,N'Historischer Uninstall entfernte fremden Captureplatz.',9; DROP FUNCTION toolbelt_string.SVF_RegexReplaceGroups; DROP SCHEMA toolbelt_string;"
rm -f "${collision_log}"; collision_log=""
run_file "${capture_upgrade_database}" "${r2b_container}" "${r2b_container}/Deploy.WithAssembly.sql" -v DeploymentMode=local
deploy_regex "${capture_upgrade_database}" local "${r2b_hash}"
run_file "${capture_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql
run_file "${capture_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Captures.Contract.sql -v "ToolbeltDatabase=${capture_upgrade_database}"
run_file "${capture_upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}"

# Echtes Upgrade aus dem gepinnten R1b-Binary. Legacy-Trust wird im Labadapter
# separat erfasst und nur bei eigener Neuerzeugung nach dem Lauf entfernt.
legacy_root="${assembly_root_host}/legacy"
legacy_container="${assembly_root_container}/legacy"
legacy_hash="$(python3 - "${legacy_root}/Toolbelt.String.Regex.trust-manifest.json" "${legacy_root}/Toolbelt.String.Regex.dll" <<'PY'
import json, sys
from pathlib import Path
from hashlib import sha512
m = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
assert m["moduleVersion"] == "1.0.0"
assert m["sha512"] == sha512(Path(sys.argv[2]).read_bytes()).hexdigest().upper()
assert m["sqlServerHexLiteral"] == "0x" + m["sha512"]
print(m["sqlServerHexLiteral"])
PY
)"
run_file master /workspace/Modules/toolbelt.string.regex/Deployment Add-TrustedAssembly.sql \
  -v "AssemblyHash=${legacy_hash}" "AssemblyDescription=Toolbelt Regex R1b upgrade test"
upgrade_database="tbx_regex_upgrade"
run_query master "CREATE DATABASE [${upgrade_database}] COLLATE Latin1_General_100_CI_AS;"
run_file "${upgrade_database}" "${legacy_container}" "${legacy_container}/Deploy.WithAssembly.sql" -v DeploymentMode=local
run_query "${upgrade_database}" "IF toolbelt_string.SVF_RegexIsMatch(N'a1',N'\\d',N'c')<>1 THROW 52095,N'Legacy-Voraussetzung fehlt.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') THROW 52095,N'Legacy-Marker fehlt.',2;"
run_query "${upgrade_database}" "EXEC(N'CREATE FUNCTION toolbelt_string.SVF_RegexReplace(@Input nvarchar(max)) RETURNS nvarchar(max) AS BEGIN RETURN N''foreign''; END');"
collision_log="$(mktemp)"
set +e
deploy_regex "${upgrade_database}" local "${legacy_hash}" >"${collision_log}" 2>&1
upgrade_collision_status=$?
set -e
[[ "${upgrade_collision_status}" -ne 0 ]] && grep -q "Msg 52033" "${collision_log}" || { echo "R2a-Upgrade-Kollision nicht korrekt zurückgewiesen." >&2; exit 1; }
run_query "${upgrade_database}" "IF toolbelt_string.SVF_RegexReplace(N'x')<>N'foreign' OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') THROW 52095,N'Upgrade-Kollision hat mutiert.',3; DROP FUNCTION toolbelt_string.SVF_RegexReplace;"
rm -f "${collision_log}"
collision_log=""
deploy_regex "${upgrade_database}" local "${legacy_hash}"
run_file "${upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Lifecycle.Contract.sql
run_file "${upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Regex.Contract.sql
run_file "${upgrade_database}" /workspace/Modules/toolbelt.string.regex/Tests/Runtime Transformations.Contract.sql

# Vier echte Sessions verwenden synthetische LOBs; nur der gemeinsame
# Pass/Fail-Nachweis wird ausgegeben, keine Zeiten/Ergebnisse persistiert.
lob_pids=()
for worker in 1 2 3 4; do
  run_query "${local_database}" "DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),2097152);
IF ISNULL(DATALENGTH(toolbelt_string.SVF_RegexReplace(@Value,N'Z',N'',1,0,N'c',N'large')),-1)<>4194304 THROW 52095,N'Concurrent Large-LOB-Vertrag falsch.',4;" >/dev/null &
  lob_pids+=("$!")
done
lob_failed=0
for pid in "${lob_pids[@]}"; do wait "${pid}" || lob_failed=1; done
[[ "${lob_failed}" -eq 0 ]] || exit 1

run_query "${upgrade_database}" "EXEC(N'CREATE VIEW dbo.RegexDependency AS SELECT toolbelt_string.SVF_RegexSubstring(N''x'',N''x'',1,1,N''c'',N''standard'') AS Value;');"
collision_log="$(mktemp)"
set +e
run_file "${upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}" >"${collision_log}" 2>&1
dependency_status=$?
set -e
[[ "${dependency_status}" -ne 0 ]] && grep -q "Msg 52038" "${collision_log}" || { echo "R2a-Uninstall-Dependency nicht geschützt." >&2; exit 1; }
run_query "${upgrade_database}" "IF OBJECT_ID(N'toolbelt_string.SVF_RegexSubstring') IS NULL THROW 52095,N'Dependency-Schutz hat mutiert.',5; DROP VIEW dbo.RegexDependency;"
rm -f "${collision_log}"
collision_log=""
run_file "${upgrade_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}"

run_query "${collision_database}" "EXEC(N'CREATE SCHEMA toolbelt_string');
EXEC(N'CREATE FUNCTION toolbelt_string.SVF_RegexCount(@Input nvarchar(max),@Pattern nvarchar(max),@Start int,@Flags nvarchar(4)) RETURNS int AS BEGIN RETURN 0; END');"
set +e
collision_log="$(mktemp)"
deploy_regex "${collision_database}" local 0x >"${collision_log}" 2>&1
collision_status=$?
set -e
[[ "${collision_status}" -ne 0 ]] || { echo "Kollisionspreflight wurde nicht ausgelöst." >&2; exit 1; }
grep -q "Msg 52033" "${collision_log}" || { echo "Unerwarteter Kollisionsfehler." >&2; exit 1; }
run_query "${collision_database}" "
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.string.regex.Version')
   OR EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_Regex')
   OR toolbelt_string.SVF_RegexCount(N'a',N'a',1,N'c') <> 0
    THROW 52093,N'Der Kollisionspreflight hat das Ziel mutiert.',1;"

run_file "${central_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=1 "ExpectedInstalledAssemblyHash=${assembly_hash}"
run_file "${local_database}" /workspace/Modules/toolbelt.string.regex/Deployment Uninstall.sql -v ConfirmNoExternalConsumers=0 "ExpectedInstalledAssemblyHash=${assembly_hash}"
run_query "${local_database}" "IF OBJECT_ID(N'toolbelt_string.SVF_RegexIsMatch') IS NOT NULL OR EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_String_Regex') THROW 52091,N'Uninstall unvollständig.',1;"
run_query master "IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=CONVERT(varbinary(64),N'${assembly_hash}',1)) THROW 52092,N'Trust wurde unerwartet entfernt.',1;"

echo "Regex SQL Server ${sql_version} / Compatibility ${compatibility_level}: erfolgreich"
