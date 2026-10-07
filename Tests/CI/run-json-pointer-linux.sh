#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich flüchtige Runner-Container und synthetische Testdatenbanken.
# Der lokale SQL_Server_Lab-Vertrag bleibt beim separaten Labtreiber.
if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
    echo "JSON_POINTER_DEDICATED_LAB_DRIVER_REQUIRED" >&2
    exit 65
fi

sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
case "${sql_version}" in
    2019) compatibility_levels="150" ;;
    2022) compatibility_levels="150 160" ;;
    2025) compatibility_levels="150 160 170" ;;
    *) echo "JSON_POINTER_CI_UNSUPPORTED_SQL_VERSION" >&2; exit 65 ;;
esac
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
if [[ "${sql_image}" != "mcr.microsoft.com/mssql/server:${sql_version}-latest" ]]; then
    echo "JSON_POINTER_CI_IMAGE_MISMATCH" >&2
    exit 65
fi

container_name="tbx-json-pointer-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}-${sql_version}"
if [[ ! "${container_name}" =~ ^tbx-json-pointer-[0-9]+-[0-9]+-(2019|2022|2025)$ ]]; then
    echo "JSON_POINTER_CI_IDENTITY_INVALID" >&2
    exit 1
fi
workspace="${GITHUB_WORKSPACE:-$(pwd)}"
container_owner="$(openssl rand -hex 16)"
if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
    echo "JSON_POINTER_CI_OWNER_INVALID" >&2
    exit 1
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"
private_dir="$(mktemp -d)"

cleanup() {
    local result=$? inspection="" container_id="" owner="" cleanup_verified=true
    trap - EXIT
    # Ein erfolgreicher Lauf ist erst nach frischer Abwesenheitsprüfung fertig.
    # ID und Owner aus derselben Aufnahme binden rm auch bei Namensaustausch.
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null; then
        cleanup_verified=false
    elif [[ -s "${private_dir}/owned-containers" ]]; then
        if ! inspection="$(docker inspect --format '{{.Id}} {{ index .Config.Labels "tbx.json-pointer.ci.owner" }}' \
            "${container_name}" 2>/dev/null)" || [[ ! "${inspection}" =~ ^([0-9a-f]{64})\ ([0-9a-f]{32})$ ]]; then
            cleanup_verified=false
        else
            container_id="${BASH_REMATCH[1]}"; owner="${BASH_REMATCH[2]}"
            if [[ "${owner}" != "${container_owner}" ]]; then
                cleanup_verified=false
            elif ! docker rm -f "${container_id}" >/dev/null 2>&1; then
                cleanup_verified=false
            fi
        fi
    fi
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null \
        || [[ -s "${private_dir}/owned-containers" ]]; then
        cleanup_verified=false
    fi
    if ! rm -rf -- "${private_dir}"; then
        cleanup_verified=false
    fi
    if [[ "${cleanup_verified}" != true ]]; then
        echo "JSON_POINTER_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    else
        echo "JSON_POINTER_CI_CLEANUP_VERIFIED"
    fi
    exit "${result}"
}
trap cleanup EXIT

run_private() {
    local label="$1"
    shift
    if ! "$@" >"${private_dir}/last-output" 2>&1; then
        echo "JSON_POINTER_CI_STEP_FAILED:${label}" >&2
        # Ausschließlich feste, vom Driver gefilterte Kategorien weitergeben.
        # Private SQL-/Exception-/Journalpayloads bleiben unterdrückt.
        if [[ "${label}" == lifecycle_local || "${label}" == lifecycle_central ]]; then
            grep -E '^JSON_POINTER_CI_LIFECYCLE_FAILED:stage=(PREPARATION|BASELINE|DEPENDENCY|CALLER|LOCK|ROLLBACK|MARKER|CONFIRM0|UNINSTALL|FOREIGN_SLOT|UNINSTALL_REPEAT|FINAL_CLEANUP|UNCLASSIFIED):reason=(JSON_POINTER_[A-Z_]+|UNCLASSIFIED)$' \
                "${private_dir}/last-output" >&2 || true
        fi
        return 1
    fi
}

# Unabhängiges JSON-/Pointer-Referenzmodell mit kleinen synthetischen Dokumenten.
if ! python3 "${workspace}/Tests/CI/generate-json-pointer-reference.py" \
    >"${private_dir}/reference.sql" 2>"${private_dir}/generator-error"; then
    echo "JSON_POINTER_CI_REFERENCE_GENERATION_FAILED" >&2
    exit 1
fi

run_private start_container docker run --detach \
    --name "${container_name}" \
    --label "tbx.json-pointer.ci.owner=${container_owner}" \
    --publish 127.0.0.1::1433 \
    --env ACCEPT_EULA=Y \
    --env MSSQL_PID=Developer \
    --env MSSQL_SA_PASSWORD="${sa_password}" \
    --volume "${workspace}:/workspace:ro" \
    "${sql_image}"

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
    if docker exec "${container_name}" test -x "${candidate}" >/dev/null 2>&1; then
        sqlcmd_path="${candidate}"
        break
    fi
done
if [[ -z "${sqlcmd_path}" ]]; then
    echo "JSON_POINTER_CI_SQLCMD_UNAVAILABLE" >&2
    exit 1
fi

ready=false
for _ in $(seq 1 60); do
    if docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 5 \
        -Q 'SELECT 1;' >"${private_dir}/last-output" 2>&1; then
        ready=true
        break
    fi
    sleep 2
done
if [[ "${ready}" != true ]]; then
    echo "JSON_POINTER_CI_SQL_NOT_READY" >&2
    exit 1
fi

published="$(docker port "${container_name}" 1433/tcp)"
port="${published##*:}"
if [[ "${published}" != 127.0.0.1:* || ! "${port}" =~ ^[0-9]{1,5}$ ]]; then
    echo "JSON_POINTER_CI_LOCAL_PORT_INVALID" >&2
    exit 1
fi
export TBX_CI_SQL_PORT="${port}"
export TBX_CI_SQL_PASSWORD="${sa_password}"

run_query() {
    local label="$1" database="$2" query="$3"
    run_private "${label}" docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -h -1 -W -w 65535 -Q "${query}"
}

run_file() {
    local label="$1" database="$2" directory="$3" filename="$4"
    shift 4
    run_private "${label}" docker exec --workdir "${directory}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${filename}" "$@"
}

expect_unknown_release_rejection() {
    local label="$1" database="$2" script="$3"
    shift 3
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${script}" "$@" \
        >"${private_dir}/last-output" 2>&1; then
        echo "JSON_POINTER_CI_UNKNOWN_RELEASE_UNEXPECTED_SUCCESS:${label}" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55524, Level 16, State 2,' "${private_dir}/last-output"; then
        echo "JSON_POINTER_CI_UNKNOWN_RELEASE_WRONG_ERROR:${label}" >&2
        return 1
    fi
}

deployment="/workspace/Modules/toolbelt.json.pointer/Deployment"
runtime="/workspace/Modules/toolbelt.json.pointer/Tests/Runtime"
client="${workspace}/Tests/CI/run-json-pointer-client.ps1"
lifecycle="${workspace}/Modules/toolbelt.json.pointer/Tests/CI/Test-JsonPointerLifecycle.ps1"
reference_level="${compatibility_levels##* }"

for level in ${compatibility_levels}; do
    local_db="tbx_json_pointer_local_${level}"
    central_db="tbx_json_pointer_central_${level}"
    consumer_db="tbx_json_pointer_consumer_${level}"
    run_query create_local master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
    run_query create_central master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2;"
    run_query create_consumer master "CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CI_AS_SC_UTF8;"
    # Owner wird ausschließlich im frisch erzeugten eigenen Container gesetzt.
    # ID/CreateDate werden vor Produktinstallation privat erfasst und später
    # unabhängig von Name und Owner auf jeder Driverconnection geprüft.
    for mode in local central; do
        database="tbx_json_pointer_${mode}_${level}"
        run_query owner "${database}" "EXEC sys.sp_addextendedproperty @name=N'Test.JsonPointer.Owner',@value=N'${container_owner}';"
        run_query identity "${database}" "SET NOCOUNT ON; SELECT database_id Id,CONVERT(varchar(18),CONVERT(binary(8),create_date),1) Creation FROM sys.databases WHERE database_id=DB_ID() FOR JSON PATH;"
        if ! python3 - "${private_dir}/last-output" >"${private_dir}/${mode}-identity-${level}" <<'PY'
import json, re, sys
def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError()
        result[key] = value
    return result
try:
    with open(sys.argv[1], encoding="utf-8-sig") as stream:
        rows = json.load(stream, object_pairs_hook=unique_object)
    if not isinstance(rows, list) or len(rows) != 1 or not isinstance(rows[0], dict) or set(rows[0]) != {"Id", "Creation"}:
        raise ValueError()
    identity, creation = rows[0]["Id"], rows[0]["Creation"]
    if type(identity) is not int or identity <= 4 or not isinstance(creation, str) or not re.fullmatch(r"0x[0-9A-F]{16}", creation):
        raise ValueError()
    print(identity, creation)
except (OSError, ValueError, KeyError, TypeError):
    print("JSON_POINTER_CI_DATABASE_IDENTITY_INVALID", file=sys.stderr)
    sys.exit(1)
PY
        then
            exit 1
        fi
    done
    for database in "${local_db}" "${central_db}" "${consumer_db}"; do
        run_query compatibility master "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL=${level};"
    done

    run_file deploy_local "${local_db}" "${deployment}" Deploy.sql -v DeploymentMode=local
    run_file deploy_central "${central_db}" "${deployment}" Deploy.sql -v DeploymentMode=central
    run_file baseline_local "${local_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${local_db}"
    run_file baseline_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    # Erste darstellbare UTF-16-Größe oberhalb des harten 16-MiB-Limits.
    # Der INPUT_LIMIT-Zweig muss vor Syntaxprüfung und großen Scans zurückkehren.
    run_query above_hard_input_limit "${central_db}" "
DECLARE @Input nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388609);
IF DATALENGTH(@Input)<>16777218
 THROW 55592,N'Pointer: synthetische Inputlänge stimmt nicht.',11;
DECLARE @Rows int=0,@Status varchar(16)=NULL,@JsonType varchar(8)=NULL,
        @Value nvarchar(max)=NULL,@ErrorCode varchar(32)=NULL;
SELECT @Rows=@Rows+1,@Status=Status,@JsonType=JsonType,@Value=Value,@ErrorCode=ErrorCode
FROM toolbelt_json.TVF_ResolveJsonPointer(@Input,N'',DEFAULT,DEFAULT);
IF @Rows<>1 OR ISNULL(@Status,'')<>'INVALID' OR @JsonType IS NOT NULL
 OR @Value IS NOT NULL OR ISNULL(@ErrorCode,'')<>'INPUT_LIMIT'
 THROW 55592,N'Pointer: hartes Inputlimit wurde nicht vor Syntax geprüft.',12;"

    for mode in local central consumer; do
        case "${mode}" in
            local) database="${local_db}"; provider="${local_db}" ;;
            central) database="${central_db}"; provider="${central_db}" ;;
            consumer) database="${consumer_db}"; provider="${central_db}" ;;
        esac
        run_file "contract_${mode}" "${database}" "${runtime}" Contract.Tests.sql -v "ToolbeltDatabase=${provider}"
        run_file "safety_${mode}" "${database}" "${runtime}" Safety.Tests.sql -v "ToolbeltDatabase=${provider}"
        run_private "client_${mode}" pwsh -NoProfile -File "${client}" -Database "${database}" -ToolbeltDatabase "${provider}"
    done

    run_file repeat_local "${local_db}" "${deployment}" Deploy.sql -v DeploymentMode=local
    run_file repeat_central "${central_db}" "${deployment}" Deploy.sql -v DeploymentMode=central
    run_file repeat_baseline_local "${local_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${local_db}"
    run_file repeat_baseline_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    if [[ "${level}" == "${reference_level}" ]]; then
        run_private independent_reference docker exec --interactive "${container_name}" "${sqlcmd_path}" \
            -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
            -d "${local_db}" -i /dev/stdin <"${private_dir}/reference.sql"
    fi
    run_query set_unknown_release "${central_db}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.pointer.Version',@value=N'9.9.9';"
    expect_unknown_release_rejection deploy "${central_db}" Deploy.sql -v DeploymentMode=central
    expect_unknown_release_rejection uninstall "${central_db}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_query unknown_release_preserved "${central_db}" "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.pointer.Version' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'9.9.9')) OR OBJECT_ID(N'toolbelt_json.TVF_ResolveJsonPointer',N'TF') IS NULL THROW 55592,N'Pointer: abgewiesener unbekannter Release wurde verändert.',13;"
    run_query restore_known_release "${central_db}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.pointer.Version',@value=N'1.0.0';"
    run_file unknown_release_restored_baseline "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    # Kanonische 20/22 Fälle besitzen den abschließenden Uninstall samt
    # Fremdslot/Repeat; die ersetzten zentralen Teilblöcke laufen nicht doppelt.
    for mode in local central; do
        database="tbx_json_pointer_${mode}_${level}"
        read -r database_id creation_hex <"${private_dir}/${mode}-identity-${level}"
        expected_count=20
        if [[ "${mode}" == central ]]; then expected_count=22; fi
        journal="${private_dir}/lifecycle-${level}-${mode}.json"
        run_private "lifecycle_${mode}" timeout --signal=TERM --kill-after=5s 160s \
            pwsh -NoProfile -File "${lifecycle}" -Database "${database}" -Mode "${mode}" \
            -Owner32Hex "${container_owner}" -ExpectedDatabaseId "${database_id}" \
            -ExpectedCreationHex "${creation_hex}" -JournalPath "${journal}"
        if ! grep -Fxq "PASS: JSON_POINTER_CI_LIFECYCLE mode=${mode} cases=${expected_count} restored=3 absent=1" \
            "${private_dir}/last-output"; then
            echo "JSON_POINTER_CI_LIFECYCLE_WITNESS_MISSING" >&2
            exit 1
        fi
        # Frischer Ledgerread nach Prozessende: ein Exit0 allein beweist weder
        # die Fallzahl noch erfolgreiche Compare-and-restore-Fixtures.
        if ! python3 - "${journal}" "${mode}" "${container_owner}" "${database_id}" "${creation_hex}" "${expected_count}" <<'PY'
import json, sys
def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError()
        result[key] = value
    return result
try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        ledger = json.load(stream, object_pairs_hook=unique_object)
    if not isinstance(ledger, dict):
        raise ValueError()
    expected = {"State": "COMPLETE", "Mode": sys.argv[2], "RunId": sys.argv[3],
                "DatabaseId": int(sys.argv[4]), "CreationHex": sys.argv[5],
                "LifecycleCasesPassed": int(sys.argv[6])}
    if any(type(ledger.get(key)) is not type(value) or ledger[key] != value
           for key, value in expected.items()):
        raise ValueError()
    if any(ledger.get(key) is not True for key in ("AbsentVerified", "NeutralVerified", "SourcePinsVerified")):
        raise ValueError()
    if any(ledger.get(key) is not False for key in ("ForeignSetupPending", "RestorationUnverified")):
        raise ValueError()
    for key in ("MarkerFixtures", "ForeignFixtures", "DependencyFixtures"):
        fixtures = ledger[key]
        if not isinstance(fixtures, list) or len(fixtures) != 1 or not isinstance(fixtures[0], dict):
            raise ValueError()
        if fixtures[0]["Restored"] is not True or type(fixtures[0]["Rejections"]) is not int or fixtures[0]["Rejections"] != 2:
            raise ValueError()
        if fixtures[0]["Mode"] != sys.argv[2]:
            raise ValueError()
except (OSError, ValueError, KeyError, TypeError):
    print("JSON_POINTER_CI_LIFECYCLE_LEDGER_INVALID", file=sys.stderr)
    sys.exit(1)
PY
        then
            exit 1
        fi
    done
    for database in "${local_db}" "${central_db}"; do
        run_query uninstall_disposition "${database}" "IF OBJECT_ID(N'toolbelt_json.TVF_ResolveJsonPointer') IS NOT NULL OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.pointer.Version') THROW 55592,N'Pointer: Uninstall ließ Releaseobjekte zurück.',8;"
    done
done

echo "PASS: JSON Pointer SQL ${sql_version} Linux; CL ${compatibility_levels}; local/central/consumer Contract, Safety, Client, Baseline, Repeat, independent reference at CL ${reference_level}, 42 kanonische local/central Lifecyclefälle pro CL (Dependency/Caller/Lock/Rollback/TypedMarker/ForeignSlot/Confirm0), central UnknownRelease und Uninstall."
