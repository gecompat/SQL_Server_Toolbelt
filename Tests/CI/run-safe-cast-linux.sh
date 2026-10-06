#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich flüchtige Runner-Container und synthetische Testdatenbanken.
# Der lokale SQL_Server_Lab-Vertrag bleibt beim separaten Labtreiber.
if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
    echo "SAFE_CAST_DEDICATED_LAB_DRIVER_REQUIRED" >&2
    exit 65
fi

sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
case "${sql_version}" in
    2019) compatibility_levels="150" ;;
    2022) compatibility_levels="150 160" ;;
    2025) compatibility_levels="150 160 170" ;;
    *) echo "SAFE_CAST_CI_UNSUPPORTED_SQL_VERSION" >&2; exit 65 ;;
esac
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
if [[ "${sql_image}" != "mcr.microsoft.com/mssql/server:${sql_version}-latest" ]]; then
    echo "SAFE_CAST_CI_IMAGE_MISMATCH" >&2
    exit 65
fi

container_name="tbx-safe-cast-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}-${sql_version}"
workspace="${GITHUB_WORKSPACE:-$(pwd)}"
private_dir="$(mktemp -d)"
container_owner="$(openssl rand -hex 16)"
if [[ ! "${container_owner}" =~ ^[0-9a-f]{32}$ ]]; then
    echo "SAFE_CAST_CI_OWNER_INVALID" >&2
    exit 1
fi
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

cleanup() {
    local result=$? owner="" cleanup_verified=true
    trap - EXIT
    # Ein erfolgreicher Lauf ist erst nach frischer Abwesenheitsprüfung fertig.
    # Ein fremdes Namensgleichnis wird bei abweichendem Owner nie gelöscht.
    if ! docker container ls --all --filter "name=^/${container_name}$" \
        --format '{{.Names}}' >"${private_dir}/owned-containers" 2>/dev/null; then
        cleanup_verified=false
    elif [[ -s "${private_dir}/owned-containers" ]]; then
        if ! owner="$(docker inspect --format '{{ index .Config.Labels "tbx.safe-cast.ci.owner" }}' \
            "${container_name}" 2>/dev/null)" || [[ "${owner}" != "${container_owner}" ]]; then
            cleanup_verified=false
        elif ! docker rm -f "${container_name}" >/dev/null 2>&1; then
            cleanup_verified=false
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
        echo "SAFE_CAST_CI_CLEANUP_UNVERIFIED" >&2
        result=1
    fi
    exit "${result}"
}
trap cleanup EXIT

run_private() {
    local label="$1"
    shift
    if ! "$@" >"${private_dir}/last-output" 2>&1; then
        echo "SAFE_CAST_CI_STEP_FAILED:${label}" >&2
        # Ausschließlich feste, vom Driver gefilterte Kategorien weitergeben.
        # Private SQL-/Exception-/Journalpayloads bleiben unterdrückt.
        if [[ "${label}" == lifecycle_local || "${label}" == lifecycle_central ]]; then
            grep -E '^SAFE_CAST_CI_LIFECYCLE_FAILED:stage=(PREPARATION|BASELINE|CALLER|LOCK|ROLLBACK|MARKER|CONFIRM0|UNINSTALL|FOREIGN_SLOT|UNINSTALL_REPEAT|FINAL_CLEANUP|UNCLASSIFIED):reason=(SAFE_CAST_[A-Z_]+|UNCLASSIFIED)$' \
                "${private_dir}/last-output" >&2 || true
        fi
        return 1
    fi
}

# Unabhängige Python-Referenzen für alle sechs Zieltypen, nur synthetische Fälle.
if ! python3 "${workspace}/Tests/CI/generate-safe-cast-reference.py" \
    >"${private_dir}/reference.sql" 2>"${private_dir}/generator-error"; then
    echo "SAFE_CAST_CI_REFERENCE_GENERATION_FAILED" >&2
    exit 1
fi

run_private start_container docker run --detach \
    --name "${container_name}" \
    --label "tbx.safe-cast.ci.owner=${container_owner}" \
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
    echo "SAFE_CAST_CI_SQLCMD_UNAVAILABLE" >&2
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
    echo "SAFE_CAST_CI_SQL_NOT_READY" >&2
    exit 1
fi

published="$(docker port "${container_name}" 1433/tcp)"
port="${published##*:}"
if [[ "${published}" != 127.0.0.1:* || ! "${port}" =~ ^[0-9]{1,5}$ ]]; then
    echo "SAFE_CAST_CI_LOCAL_PORT_INVALID" >&2
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

expect_dependency_rejection() {
    local label="$1" database="$2" script="$3"
    shift 3
    # Ein echter View-Verbraucher muss Deploy und Uninstall blockieren.
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${script}" "$@" \
        >"${private_dir}/last-output" 2>&1; then
        echo "SAFE_CAST_CI_DEPENDENCY_UNEXPECTED_SUCCESS:${label}" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55425, Level 16, State 3,' "${private_dir}/last-output"; then
        echo "SAFE_CAST_CI_DEPENDENCY_WRONG_ERROR:${label}" >&2
        return 1
    fi
}

expect_unknown_release_rejection() {
    local label="$1" database="$2" script="$3"
    shift 3
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${script}" "$@" \
        >"${private_dir}/last-output" 2>&1; then
        echo "SAFE_CAST_CI_UNKNOWN_RELEASE_UNEXPECTED_SUCCESS:${label}" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55424, Level 16, State 2,' "${private_dir}/last-output"; then
        echo "SAFE_CAST_CI_UNKNOWN_RELEASE_WRONG_ERROR:${label}" >&2
        return 1
    fi
}

deployment="/workspace/Modules/toolbelt.conversion.safe-cast/Deployment"
runtime="/workspace/Modules/toolbelt.conversion.safe-cast/Tests/Runtime"
client="${workspace}/Tests/CI/run-safe-cast-client.ps1"
lifecycle="${workspace}/Modules/toolbelt.conversion.safe-cast/Tests/CI/Test-SafeCastLifecycle.ps1"
reference_level="${compatibility_levels##* }"

for level in ${compatibility_levels}; do
    local_db="tbx_safe_cast_local_${level}"
    central_db="tbx_safe_cast_central_${level}"
    consumer_db="tbx_safe_cast_consumer_${level}"
    run_query create_local master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
    run_query create_central master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2;"
    run_query create_consumer master "CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CI_AS_SC_UTF8;"
    # Owner wird ausschließlich im frisch erzeugten eigenen Container gesetzt.
    # ID/CreateDate werden vor Produktinstallation privat erfasst und später
    # unabhängig von Name und Owner auf jeder Driverconnection geprüft.
    for mode in local central; do
        database="tbx_safe_cast_${mode}_${level}"
        run_query owner "${database}" "EXEC sys.sp_addextendedproperty @name=N'Test.SafeCast.Owner',@value=N'${container_owner}';"
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
    print("SAFE_CAST_CI_DATABASE_IDENTITY_INVALID", file=sys.stderr)
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

    for mode in local central consumer; do
        case "${mode}" in
            local) database="${local_db}"; provider="${local_db}" ;;
            central) database="${central_db}"; provider="${central_db}" ;;
            consumer) database="${consumer_db}"; provider="${central_db}" ;;
        esac
        run_file "contract_${mode}" "${database}" "${runtime}" Contract.Tests.sql -v "ToolbeltDatabase=${provider}"
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
    run_query set_unknown_release "${central_db}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version',@value=N'9.9.9';"
    expect_unknown_release_rejection deploy "${central_db}" Deploy.sql -v DeploymentMode=central
    expect_unknown_release_rejection uninstall "${central_db}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_query unknown_release_preserved "${central_db}" "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'9.9.9')) OR (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_conversion') AND type=N'IF' AND name IN(N'TVF_TryCastBigInt',N'TVF_TryCastDecimal',N'TVF_TryCastDate',N'TVF_TryCastDateTime2',N'TVF_TryCastBit',N'TVF_TryCastUniqueIdentifier'))<>6 THROW 55492,N'Safe Cast: abgewiesener unbekannter Release wurde verändert.',13;"
    run_query restore_known_release "${central_db}" "EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version',@value=N'1.0.0';"
    run_file unknown_release_restored_baseline "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_query create_dependency "${central_db}" "EXEC(N'CREATE VIEW dbo.VW_SafeCastDependencyCI AS SELECT Status FROM toolbelt_conversion.TVF_TryCastBigInt(N''1'',DEFAULT);'); IF NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.VW_SafeCastDependencyCI',N'V') AND referenced_id=OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF')) THROW 55492,N'Safe Cast: synthetische Abhängigkeit fehlt.',9;"
    expect_dependency_rejection deploy "${central_db}" Deploy.sql -v DeploymentMode=central
    run_file dependency_deploy_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    expect_dependency_rejection uninstall "${central_db}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_file dependency_uninstall_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_query drop_dependency "${central_db}" "IF NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.VW_SafeCastDependencyCI',N'V') AND referenced_id=OBJECT_ID(N'toolbelt_conversion.TVF_TryCastBigInt',N'IF')) THROW 55492,N'Safe Cast: Abhängigkeit nach Ablehnung verloren.',10; DROP VIEW dbo.VW_SafeCastDependencyCI;"
    # Kanonische 18/20 Fälle besitzen den abschließenden Uninstall samt
    # Fremdslot/Repeat; die ersetzten zentralen Teilblöcke laufen nicht doppelt.
    for mode in local central; do
        database="tbx_safe_cast_${mode}_${level}"
        read -r database_id creation_hex <"${private_dir}/${mode}-identity-${level}"
        expected_count=18
        if [[ "${mode}" == central ]]; then expected_count=20; fi
        journal="${private_dir}/lifecycle-${level}-${mode}.json"
        run_private "lifecycle_${mode}" timeout --signal=TERM --kill-after=5s 160s \
            pwsh -NoProfile -File "${lifecycle}" -Database "${database}" -Mode "${mode}" \
            -Owner32Hex "${container_owner}" -ExpectedDatabaseId "${database_id}" \
            -ExpectedCreationHex "${creation_hex}" -JournalPath "${journal}"
        if ! grep -Fxq "PASS: SAFE_CAST_CI_LIFECYCLE mode=${mode} cases=${expected_count} restored=2 absent=1" \
            "${private_dir}/last-output"; then
            echo "SAFE_CAST_CI_LIFECYCLE_WITNESS_MISSING" >&2
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
    for key in ("MarkerFixtures", "ForeignFixtures"):
        fixtures = ledger[key]
        if not isinstance(fixtures, list) or len(fixtures) != 1 or not isinstance(fixtures[0], dict):
            raise ValueError()
        if fixtures[0]["Restored"] is not True or type(fixtures[0]["Rejections"]) is not int or fixtures[0]["Rejections"] != 2:
            raise ValueError()
        if fixtures[0]["Mode"] != sys.argv[2]:
            raise ValueError()
except (OSError, ValueError, KeyError, TypeError):
    print("SAFE_CAST_CI_LIFECYCLE_LEDGER_INVALID", file=sys.stderr)
    sys.exit(1)
PY
        then
            exit 1
        fi
    done
    for database in "${local_db}" "${central_db}"; do
        run_query uninstall_disposition "${database}" "IF EXISTS(SELECT 1 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_conversion' AND o.name LIKE N'TVF_TryCast%') OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version') THROW 55492,N'Safe Cast: Uninstall ließ Releaseobjekte zurück.',8;"
    done
done

echo "PASS: Safe Cast SQL ${sql_version} Linux; CL ${compatibility_levels}; local/central/consumer Contract, Client, Baseline, Repeat, independent reference at CL ${reference_level}, 38 kanonische local/central Lifecyclefälle pro CL (Caller/Lock/Rollback/TypedMarker/ForeignSlot/Confirm0), central UnknownRelease/Dependency und Uninstall."
