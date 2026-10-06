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
        return 1
    fi
}

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
        -d "${database}" -Q "${query}"
}

run_file() {
    local label="$1" database="$2" directory="$3" filename="$4"
    shift 4
    run_private "${label}" docker exec --workdir "${directory}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${filename}" "$@"
}

expect_central_confirm0_rejection() {
    local database="$1"
    # Die erwartete SQL-Ausnahme bleibt privat; nur Nummer und State sind Orakel.
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i Uninstall.sql -v ConfirmNoExternalConsumers=0 \
        >"${private_dir}/last-output" 2>&1; then
        echo "SAFE_CAST_CI_CONFIRM0_UNEXPECTED_SUCCESS" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55426, Level 16, State 1,' "${private_dir}/last-output"; then
        echo "SAFE_CAST_CI_CONFIRM0_WRONG_ERROR" >&2
        return 1
    fi
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

expect_caller_transaction_rejection() {
    local label="$1" database="$2" script="$3"
    shift 3
    # SQLCMD liest denselben Deployment-Einstieg in einer bereits offenen
    # Aufrufertransaktion. Ein unerwartetes Weiterlaufen endet mit eigenem THROW.
    if { printf 'SET XACT_ABORT ON;\nBEGIN TRANSACTION;\n:r ./%s\nTHROW 55492,N\x27Safe Cast: Caller-Gate wurde umgangen.\x27,14;\n' "${script}"; } |
        docker exec --interactive --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i /dev/stdin "$@" \
        >"${private_dir}/last-output" 2>&1; then
        echo "SAFE_CAST_CI_CALLER_UNEXPECTED_SUCCESS:${label}" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 50000, Level 16, State 1,' "${private_dir}/last-output" \
        || ! grep -Fq 'TBX_SAFE_CAST_LIFECYCLE_CALLER_TRANSACTION:' "${private_dir}/last-output" \
        || [[ "$(grep -Ec '^Msg [0-9]+,' "${private_dir}/last-output")" != 1 ]]; then
        echo "SAFE_CAST_CI_CALLER_WRONG_ERROR:${label}" >&2
        return 1
    fi
}

deployment="/workspace/Modules/toolbelt.conversion.safe-cast/Deployment"
runtime="/workspace/Modules/toolbelt.conversion.safe-cast/Tests/Runtime"
client="${workspace}/Tests/CI/run-safe-cast-client.ps1"

for level in ${compatibility_levels}; do
    local_db="tbx_safe_cast_local_${level}"
    central_db="tbx_safe_cast_central_${level}"
    consumer_db="tbx_safe_cast_consumer_${level}"
    run_query create_local master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
    run_query create_central master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2;"
    run_query create_consumer master "CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CI_AS_SC_UTF8;"
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
    expect_caller_transaction_rejection deploy "${central_db}" Deploy.sql -v DeploymentMode=central
    run_file caller_deploy_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    expect_caller_transaction_rejection uninstall "${central_db}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_file caller_uninstall_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
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
    expect_central_confirm0_rejection "${central_db}"
    run_file confirm0_preserved_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_file uninstall_central "${central_db}" "${deployment}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_file uninstall_local "${local_db}" "${deployment}" Uninstall.sql -v ConfirmNoExternalConsumers=0
    for database in "${local_db}" "${central_db}"; do
        run_query uninstall_disposition "${database}" "IF EXISTS(SELECT 1 FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE s.name=N'toolbelt_conversion' AND o.name LIKE N'TVF_TryCast%') OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version') THROW 55492,N'Safe Cast: Uninstall ließ Releaseobjekte zurück.',8;"
    done
done

echo "PASS: Safe Cast SQL ${sql_version} Linux; CL ${compatibility_levels}; local/central/consumer Contract, Client, Baseline, Repeat, central CallerTransaction/UnknownRelease/Dependency/Confirm0 und Uninstall."
